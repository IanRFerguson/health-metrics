from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector
from polars import DataFrame

from common.logger import logger

#####


def load_single_blob_to_bigquery() -> None:
    pass


def load_source_data_to_bigquery(
    source: str,
    storage_client: storage.Client,
    bigquery_client: BigQueryConnector,
    bucket_name: str,
    prefix: str,
    destination_schema: str,
    destination_table: str,
) -> None:
    """
    Lists all target blobs and iteratively writes them to a staging table. The
    staging table overwrites the production table each run, unless there are runtime
    exceptions. NOTE: Eventually we can make this build incrementally.

    Args:
        source (str): Type of data that is being loaded in the current execution
        storage_client (storage.Client): Storage client to read from GCS
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        bucket_name (str): GCS bucket name
        prefix (str): GCS prefix (subfolder) name
        destination_schema (str): BigQuery destination schema
        destination_table (str): BigQuery destination table
    """

    target_blobs = storage_client.list_blobs(bucket_or_name=bucket_name, prefix=prefix)
    logger.info(f"* Writing {source} data to BigQuery")
    logger.info(f"** Read {len(target_blobs)} from gs://{bucket_name}/{prefix}")
    logger.info(f"** Writing to `{destination_schema}.{destination_table}`")

    errors = []
    for blob_name in target_blobs:
        try:
            load_single_blob_to_bigquery(
                storage_client=storage_client,
                bigquery_client=bigquery_client,
                bucket_name=bucket_name,
                blob_name=blob_name,
                destination_schema=destination_schema,
                destination_table=destination_table,
            )
        except Exception as e:
            logger.error(f"** Failed @ {blob_name} ... {e}")
            errors.append((blob_name, e))

    if errors:
        pass
