import tempfile
from datetime import datetime

import polars as pl
from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector
from log_helpers import compare_logged_flat_files, log_loaded_flat_files

from common.logger import metrics_logger

#####


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
    bucket_name: str,
    blob_name: str,
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


def truncate_single_source(
    source: str,
    bigquery_client: BigQueryConnector,
    log_table: str,
    destination_schema: str,
    destination_table: str,
) -> None:
    """
    Truncates data for a single source from the destination table and
    removes relevant records from the log table.

    Args:
        source (str): Source of health data to truncate
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        log_table (str): Fully qualified log table name
        destination_schema (str): BigQuery destination schema
        destination_table (str): BigQuery destination table
    """

    # First, we'll delete existing log entries for the source
    truncate_sql = f"DELETE FROM `{log_table}` WHERE source = '{source}';"
    bigquery_client.query(truncate_sql, return_results=False)
    metrics_logger.debug("Deleted existing log entries...")

    # Next, we'll drop the existing destination table to get a clean
    # run into BigQuery
    drop_sql = f"DROP TABLE IF EXISTS `{destination_schema}.{destination_table}`;"
    bigquery_client.query(drop_sql, return_results=False)
    metrics_logger.debug("Dropped existing destination table...")

    metrics_logger.info(f"* Truncated existing data for source: {source}")


def load_source_data_to_bigquery(
    source: str,
    storage_client: storage.Client,
    bigquery_client: BigQueryConnector,
    bucket_name: str,
    prefix: str,
    destination_schema: str,
    destination_table: str,
    log_table: str,
) -> None:
    """
    Loads health data from GCS flat files into BigQuery.

    Args:
        source (str): Type of data that is being loaded in the current execution
        storage_client (storage.Client): Storage client to read from GCS
        bigquery_client (BigQueryConnector): BigQuery client to write to BigQuery
        bucket_name (str): GCS bucket name
        prefix (str): GCS prefix (subfolder) name
        destination_schema (str): BigQuery destination schema
        destination_table (str): BigQuery destination table
        log_table (str): Fully qualified log table name
    """

    # These are all  of the flat files in cloud storage
    all_blobs = [
        blob
        for blob in storage_client.list_blobs(bucket_or_name=bucket_name, prefix=prefix)
    ]

    # These are the flat files that have not yet been logged
    target_blobs = compare_logged_flat_files(
        bigquery_client=bigquery_client,
        log_table=log_table,
        source=source,
        all_blobs=all_blobs,
    )

    # If there are no new flat files to load, we'll exit early
    if not target_blobs:
        metrics_logger.info(f"* No new {source} flat files to load.")
        return

    ###

    metrics_logger.info(f"* Writing {source} data to BigQuery")
    metrics_logger.info(
        f"** {len(target_blobs)} flat files to load from gs://{bucket_name}/{prefix} to `{destination_schema}.{destination_table}`"
    )

    # We'll loop through all of the blobs to load, and will attempt to read each one
    # into a Polars DataFrame. If successful, we'll add it to our list of dataframes
    # to be concatenated and written to BigQuery. If there is an error, we'll
    # log it and continue processing the remaining blobs.
    dataframes, loaded_blobs, errors = [], [], []
    for blob in target_blobs:
        try:
            dataframes.append(
                read_dataframe_from_gcs(
                    storage_client=storage_client,
                    bucket_name=bucket_name,
                    blob_name=blob.name,
                )
            )
            loaded_blobs.append(blob)

        except Exception as e:
            metrics_logger.error(f"** Failed @ {blob.name} ... {e}")
            errors.append((blob.name, e))

    ###

    # If we have any successfully loaded dataframes, we'll concatenate them
    # and write them to BigQuery in a single operation
    if dataframes:
        df = pl.concat(dataframes, how="vertical_relaxed")
        bigquery_client.write_dataframe(
            df=df,
            table_name=f"{destination_schema}.{destination_table}",
            if_exists="append",
        )
        metrics_logger.info(
            f"* Successfully loaded {len(dataframes)} files into BigQuery"
        )

    # Next, we'll log all of the successfully loaded flat files
    if loaded_blobs:
        log_loaded_flat_files(
            bigquery_client=bigquery_client,
            log_table=log_table,
            source=source,
            bucket_name=bucket_name,
            loaded_blobs=loaded_blobs,
        )

    # Lastly, if there were runtime errors we'll log them and raise an exception
    # so the program exits appropriately
    if errors:
        metrics_logger.error(f"* Completed with {len(errors)} errors:")
        for blob_name, error in errors:
            metrics_logger.error(f"** {blob_name} ... {error}")
        raise RuntimeError("Errors occurred during data load. See logs for details.")
