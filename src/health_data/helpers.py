import logging
import sys
import tempfile
from datetime import datetime

import polars as pl
from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector

from common.logger import metrics_logger

#####

logger_to_suppress = logging.getLogger("klondike.gcp.bigquery")
logger_to_suppress.setLevel(logging.WARNING)
logger_to_suppress.propagate = False


def standardize_column_name(column_name: str) -> str:
    """
    Standardizes column names by converting to lowercase and replacing spaces with underscores.

    Args:
        column_name (str): The original column name

    Returns:
        str: The standardized column name
    """

    return (
        column_name.strip()
        .lower()
        .replace(" ", "_")
        .replace("(", "_")
        .replace(")", "")
        .replace("/", "_")
        .replace("[", "")
        .replace("]", "")
        .replace("·", "_")
    )


def read_dataframe_from_gcs(
    storage_client: storage.Client,
    bigquery_client: BigQueryConnector,
    bucket_name: str,
    blob_name: str,
    destination_schema: str,
    destination_table: str,
) -> pl.DataFrame:
    """
    Loads a single blob from GCS into a BigQuery table.

    Args:
        storage_client (storage.Client): Storage client to read from GCS
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        bucket_name (str): GCS bucket name
        blob_name (str): GCS blob name
        destination_schema (str): BigQuery destination schema
        destination_table (str): BigQuery destination table
    """

    metrics_logger.debug(f"*** Loading blob: gs://{bucket_name}/{blob_name}")

    # Download blob to a temporary file
    with tempfile.NamedTemporaryFile() as temp_file:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_name)
        blob.download_to_filename(temp_file.name)

        # Read the data into a Polars DataFrame
        df: pl.DataFrame = pl.DataFrame._read_csv(temp_file.name)

        # Add load timestamp column
        df = df.with_columns(
            _load_timestamp=pl.lit(datetime.now()),
            _source_bucket_name=pl.lit(bucket_name),
            _source_filename=pl.lit(blob_name),
        )

        for col in df.columns:
            standardized_col = standardize_column_name(col)
            if standardized_col != col:
                df = df.rename({col: standardized_col})

        return df


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

    target_blobs = [
        blob
        for blob in storage_client.list_blobs(bucket_or_name=bucket_name, prefix=prefix)
    ]
    metrics_logger.info(f"* Writing {source} data to BigQuery")
    metrics_logger.info(
        f"** Read {len(target_blobs)} flat files from gs://{bucket_name}/{prefix}"
    )
    metrics_logger.info(f"** Writing to `{destination_schema}.{destination_table}`")

    if bigquery_client.table_exists(
        table_name=f"{destination_schema}.{destination_table}"
    ):
        metrics_logger.info(
            f"** Deleting existing table `{destination_schema}.{destination_table}`"
        )
        bigquery_client.query(
            f"DROP TABLE `{destination_schema}.{destination_table}`",
            return_results=False,
        )

    dataframes, errors = [], []
    for blob in target_blobs:
        try:
            dataframes.append(
                read_dataframe_from_gcs(
                    storage_client=storage_client,
                    bigquery_client=bigquery_client,
                    bucket_name=bucket_name,
                    blob_name=blob.name,
                    destination_schema=destination_schema,
                    destination_table=destination_table,
                )
            )
        except Exception as e:
            metrics_logger.error(f"** Failed @ {blob.name} ... {e}")
            errors.append((blob.name, e))

    if errors:
        metrics_logger.error(f"* Completed with {len(errors)} errors:")
        for blob_name, error in errors:
            metrics_logger.error(f"** {blob_name} ... {error}")
        sys.exit(1)

    if dataframes:
        df = pl.concat(dataframes, how="vertical_relaxed")
        bigquery_client.write_dataframe(
            df=df,
            table_name=f"{destination_schema}.{destination_table}",
            if_exists="fail",
        )
        metrics_logger.info(
            f"* Successfully loaded {len(dataframes)} files into BigQuery"
        )
