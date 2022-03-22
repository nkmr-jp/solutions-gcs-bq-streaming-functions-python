# Streaming data from Cloud Storage into BigQuery using Cloud Functions
This code looks at a complete ingest pipeline all the way from capturing streaming events 
(upload of files to Cloud Storage), to doing basic processing, errorm handling, logging and 
insert stream to bigquery. The example captures events from a bucket (object create) with 
Cloud Function, reads the file and stream the content (JSON) to a table in BigQuery. 
If something goes wrong, the function logs the results in Cloud Logging and Firestore, for post analysis. 
Finally the data from the BigQuery can be visualized using DataStudio or a front end Web UI with 
API integration.

For more details of how to execute the steps of this streaming pipeline, please take a look on 
[Streaming data from Cloud Storage into BigQuery using Cloud Functions](https://cloud.google.com/solutions/streaming-data-from-cloud-storage-into-bigquery-using-cloud-functions) Tutorial.


# 追記

see: https://cloud.google.com/solutions/streaming-data-from-cloud-storage-into-bigquery-using-cloud-functions

## 設定

```sh
make PROJECT_ID=[your-project-id] create-bucket
make PROJECT_ID=[your-project-id] create-dataset
make PROJECT_ID=[your-project-id] create-topic
make PROJECT_ID=[your-project-id] deploy1
make PROJECT_ID=[your-project-id] deploy2
make PROJECT_ID=[your-project-id] deploy3
make PROJECT_ID=[your-project-id] describe
```

## 動作確認

```sh
make PROJECT_ID=[your-project-id] upload
make PROJECT_ID=[your-project-id] query
```
