# See: https://cloud.google.com/solutions/streaming-data-from-cloud-storage-into-bigquery-using-cloud-functions

PROJECT_ID=
DATE=$(shell date '+%Y%m%d')
REGION=asia-northeast1
FILES_SOURCE=$(PROJECT_ID)-files-$(DATE)
FILES_SUCCESS=$(PROJECT_ID)-files-success-$(DATE)
FILES_ERROR=$(PROJECT_ID)-files-error-$(DATE)
FUNCTIONS_BUCKET=$(PROJECT_ID)-functions-$(DATE)

STREAMING_ERROR_TOPIC=streaming_error_topic
STREAMING_SUCCESS_TOPIC=streaming_success_topic

create-bucket:
	gsutil mb -c regional -l $(REGION) gs://$(FILES_SOURCE)
	gsutil mb -c coldline -l $(REGION) gs://$(FILES_SUCCESS)
	gsutil mb -c regional -l $(REGION) gs://$(FILES_ERROR)
	gsutil mb -c regional -l $(REGION) gs://$(FUNCTIONS_BUCKET)

create-dataset:
	bq mk mydataset
	bq mk mydataset.mytable schema.json
	bq ls --format=pretty mydataset

create-topic:
	gcloud pubsub topics create $(STREAMING_ERROR_TOPIC)
	gcloud pubsub topics create $(STREAMING_SUCCESS_TOPIC)

deploy1:
	gcloud functions deploy streaming --region=$(REGION) \
        --source=./functions/streaming --runtime=python37 \
        --stage-bucket=$(FUNCTIONS_BUCKET) \
        --trigger-bucket=$(FILES_SOURCE)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"

deploy2:
	gcloud functions deploy streaming_error --region=$(REGION) \
        --source=./functions/move_file \
        --entry-point=move_file --runtime=python37 \
        --stage-bucket=$(FUNCTIONS_BUCKET) \
        --trigger-topic=$(STREAMING_ERROR_TOPIC) \
        --set-env-vars SOURCE_BUCKET=$(FILES_SOURCE),DESTINATION_BUCKET=$(FILES_ERROR)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming_error?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"

deploy3:
	gcloud functions deploy streaming_success --region=$(REGION) \
		--source=./functions/move_file \
		--entry-point=move_file --runtime=python37 \
		--stage-bucket=$(FUNCTIONS_BUCKET) \
		--trigger-topic=$(STREAMING_ERROR_TOPIC) \
		--set-env-vars SOURCE_BUCKET=$(FILES_SOURCE),DESTINATION_BUCKET=$(FILES_SUCCESS)
	@echo
	@echo "See: https://console.cloud.google.com/functions/details/$(REGION)/streaming_success?env=gen1&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"


describe:
	gcloud functions describe streaming --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	gcloud functions describe streaming_error --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	gcloud functions describe streaming_success --region=$(REGION) \
        --format="table[box](entryPoint, status, eventTrigger.eventType)"
	@echo
	@echo "See: https://console.cloud.google.com/functions/list?referrer=search&project=$(PROJECT_ID)"
	@echo "See: https://cloud.google.com/sdk/gcloud/reference/functions/describe"

upload:
	gsutil cp test_files/data.json gs://$(FILES_SOURCE)
	gsutil cp test_files/data_error.json gs://$(FILES_SOURCE)
	@echo
	@echo "See: https://console.cloud.google.com/storage/browser?project=$(PROJECT_ID)"

query:
	bq query 'select first_name, last_name, dob from mydataset.mytable'
	@echo
	@echo "See: https://console.cloud.google.com/bigquery?project=$(PROJECT_ID)"
