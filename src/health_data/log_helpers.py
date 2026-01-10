import datetime
import os
from typing import List

import polars as pl
from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector

from common.logger import metrics_logger

#####


def setup_log_table(
    bigquery_client: BigQueryConnector,
    log_table_name: str,
) -> None:
    """
    Sets up the log table in BigQuery if it does not already exist.

    Args:
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        log_table_name (str): Fully qualified log table name
    """

    metrics_logger.info(f"Creating log table: {log_table_name}")

    with open(os.path.join(os.path.dirname(__file__), "log_table.sql"), "r") as f:
        create_table_sql = f.read().format(log_table_name=log_table_name)

    bigquery_client.query(
        create_table_sql,
        return_results=False,
    )


def compare_logged_flat_files(
    bigquery_client: BigQueryConnector,
    log_table: str,
    source: str,
    all_blobs: List[storage.Blob],
) -> List[storage.Blob]:
    """
    Compares all blobs in GCS with those already logged in the BigQuery log table.
    Returns a list of blobs that have not yet been logged.

    Args:
        bigquery_client (BigQueryConnector): BigQuery client to query log table
        log_table (str): Fully qualified log table name
        source (str): Source of health data
        all_blobs (List[storage.Blob]): List of all blobs in GCS

    Returns:
        List[storage.Blob]: List of blobs that have not yet been logged
    """

    logged_blobs = bigquery_client.query(
        f"""
        SELECT
            file_name AS source_filename
        FROM `{log_table}`
        WHERE source = '{source}';
        """
    ).to_polars()

    if logged_blobs.is_empty():
        metrics_logger.warning("No logs found - returning all flat file names")
        return all_blobs

    logged_blob_names = set(logged_blobs["source_filename"].to_list())
    target_blobs = [blob for blob in all_blobs if blob.name not in logged_blob_names]

    return target_blobs


def log_loaded_flat_files(
    bigquery_client: BigQueryConnector,
    log_table: str,
    source: str,
    bucket_name: str,
    loaded_blobs: List[storage.Blob],
) -> None:
    """
    Logs the loaded flat files into the BigQuery log table.

    Args:
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        log_table (str): Fully qualified log table name
        source (str): Source of health data
        loaded_blobs: List of loaded blobs
        bucket_name (str): Name of the GCS bucket
    """

    df = pl.DataFrame(
        {
            "source": [source] * len(loaded_blobs),
            "file_name": [blob.name for blob in loaded_blobs],
            "bucket_name": [bucket_name] * len(loaded_blobs),
            "load_timestamp": [datetime.datetime.now()] * len(loaded_blobs),
        }
    )

    bigquery_client.write_dataframe(df=df, table_name=log_table, if_exists="append")
    metrics_logger.info(
        f"* Logged {len(loaded_blobs)} loaded flat files to {log_table}."
    )
