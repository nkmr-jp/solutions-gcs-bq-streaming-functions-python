# See: https://cloud.google.com/solutions/streaming-data-from-cloud-storage-into-bigquery-using-cloud-functions
# See: https://github.com/GoogleCloudPlatform/functions-framework-python

PROJECT_ID=
DATE=$(shell date '+%Y%m%d')
REGION=asia-northeast1
FILES_SOURCE_BUCKET=$(PROJECT_ID)-files-$(DATE)
FILES_SUCCESS_BUCKET=$(PROJECT_ID)-files-success-$(DATE)
FILES_ERROR_BUCKET=$(PROJECT_ID)-files-error-$(DATE)
FUNCTIONS_BUCKET=$(PROJECT_ID)-functions-$(DATE)
FILE_NAME=data.json

STREAMING_ERROR_TOPIC=streaming_error_topic
STREAMING_SUCCESS_TOPIC=streaming_success_topic

check:
ifeq ($(PROJECT_ID),)
	$(error "Please specify PROJECT_ID")
endif

create-bucket: check
	gsutil mb -c regional -l $(REGION) gs://$(FILES_SOURCE_BUCKET)
	gsutil mb -c coldline -l $(REGION) gs://$(FILES_SUCCESS_BUCKET)
	gsutil mb -c regional -l $(REGION) gs://$(FILES_ERROR_BUCKET)
	gsutil mb -c regional -l $(REGION) gs://$(FUNCTIONS_BUCKET)

create-dataset:
	bq mk mydataset
	bq mk mydataset.mytable schema.json
	bq ls --format=pretty mydataset

create-topic:
	gcloud pubsub topics create $(STREAMING_ERROR_TOPIC)
	gcloud pubsub topics create $(STREAMING_SUCCESS_TOPIC)

deploy1: check
	gcloud functions deploy streaming --region=$(REGION) \
        --source=./functions/streaming --runtime=python37 \
        --stage-bucket=$(FUNCTIONS_BUCKET) \
        --trigger-bucket=$(FILES_SOURCE_BUCKET)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"

deploy2: check
	gcloud functions deploy streaming_error --region=$(REGION) \
        --source=./functions/move_file \
        --entry-point=move_file --runtime=python37 \
        --stage-bucket=$(FUNCTIONS_BUCKET) \
        --trigger-topic=$(STREAMING_ERROR_TOPIC) \
        --set-env-vars SOURCE_BUCKET=$(FILES_SOURCE_BUCKET),DESTINATION_BUCKET=$(FILES_ERROR_BUCKET)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming_error?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"

deploy3: check
	gcloud functions deploy streaming_success --region=$(REGION) \
		--source=./functions/move_file \
		--entry-point=move_file --runtime=python37 \
		--stage-bucket=$(FUNCTIONS_BUCKET) \
		--trigger-topic=$(STREAMING_SUCCESS_TOPIC) \
		--set-env-vars SOURCE_BUCKET=$(FILES_SOURCE_BUCKET),DESTINATION_BUCKET=$(FILES_SUCCESS_BUCKET)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming_success?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"


describe: check
	gcloud functions describe streaming --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	gcloud functions describe streaming_error --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	gcloud functions describe streaming_success --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	@echo
	@echo "See: https://console.cloud.google.com/functions/list?referrer=search&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/describe"

upload: check
	gsutil cp test_files/$(FILE_NAME) gs://$(FILES_SOURCE_BUCKET)
	@echo
	@echo "See: https://console.cloud.google.com/storage/browser?project=$(PROJECT_ID)"

query: check
	bq query 'select first_name, last_name, dob from mydataset.mytable'
	@echo
	@echo "See: https://console.cloud.google.com/bigquery?project=$(PROJECT_ID)"


### Local test

local-gcs-event: gen
	curl -X POST localhost:8081 \
	-H "Content-Type: application/cloudevents+json" \
	-d @./tmp/google.storage.object.finalize.json

gen: check
	@mkdir -p ./tmp
	@cat ./cloudevents/google.storage.object.finalize.json | \
	sed "s|{{FILES_SOURCE_BUCKET}}|$(FILES_SOURCE_BUCKET)|g" | \
	sed "s|{{FILE_NAME}}|$(FILE_NAME)|g" > ./tmp/google.storage.object.finalize.json

SCRIPT_DIR=tmp/python-pubsub/samples/snippets/
local-init-pubsub:
	cd tmp; git clone https://github.com/googleapis/python-pubsub.git
	cd $(SCRIPT_DIR); pip install -r requirements.txt;
	$(gcloud beta emulators pubsub env-init)

local-create-topic: check
	cd $(SCRIPT_DIR); python publisher.py $(PROJECT_ID) create $(STREAMING_SUCCESS_TOPIC)
	cd $(SCRIPT_DIR); python subscriber.py $(PROJECT_ID) create-push $(STREAMING_SUCCESS_TOPIC) $gcf-(STREAMING_SUCCESS_TOPIC) http://localhost:8082
	cd $(SCRIPT_DIR); python subscriber.py $(PROJECT_ID) create-push $(STREMING_ERROR_TOPIC) $gcf-(STREMING_ERROR_TOPIC) http://localhost:8083

local-success-event: check
	python publisher.py $(PROJECT_ID) publish $(STREAMING_SUCCESS_TOPIC)

local-error-event: check
	python publisher.py $(PROJECT_ID) publish $(STREAMING_ERROR_TOPIC)
