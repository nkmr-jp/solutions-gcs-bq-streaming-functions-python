import json
import logging
import os
import traceback
from google.api_core import retry
from google.cloud import bigquery
from google.cloud import storage

PROJECT_ID = os.getenv('GCP_PROJECT')
BQ_DATASET = 'bq_load_test'
BQ_TABLE = 'mytable'
CS = storage.Client()
BQ = bigquery.Client()


def bq_load(data, context):
    bucket_name = data['bucket']
    file_name = data['name']
    try:
        _load(bucket_name, file_name)
        _handle_success(file_name)
    except Exception:
        _handle_error(file_name)


def _load(bucket_name, file_name):
    pass


# def _insert_into_bigquery(bucket_name, file_name):
#     blob = CS.get_bucket(bucket_name).blob(file_name)
#     row = json.loads(blob.download_as_string())
#     table = BQ.dataset(BQ_DATASET).table(BQ_TABLE)
#     errors = BQ.insert_rows_json(table,
#                                  json_rows=[row],
#                                  row_ids=[file_name],
#                                  retry=retry.Retry(deadline=30))
#     if errors != []:
#         raise BigQueryError(errors)


def _handle_success(file_name):
    message = 'File \'%s\' loaded into BigQuery' % file_name
    logging.info(message)


def _handle_error(file_name):
    message = 'Error bq_load file \'%s\'. Cause: %s' % (file_name, traceback.format_exc())
    logging.error(message)


class BigQueryError(Exception):
    """Exception raised whenever a BigQuery error happened"""

    def __init__(self, errors):
        super().__init__(self._format(errors))
        self.errors = errors

    def _format(self, errors):
        err = []
        for error in errors:
            err.extend(error['errors'])
        return json.dumps(err)
