import logging
import os

import click
from constants import HEALTH_METRIC_FLAT_FILE_MAP, LOG_TABLE_NAME
from google.cloud import storage
from klondike import logger as klondike_logger
from klondike.gcp.bigquery import BigQueryConnector

from common.logger import metrics_logger
from health_data.log_helpers import setup_log_table
from health_data.pipeline_helpers import (
    load_source_data_to_bigquery,
    truncate_single_source,
)

#####

# We'll suppress Klondike logs throughout
logging.getLogger("klondike").setLevel("WARNING")


def load_source_data(
    source: str,
    storage_client: storage.Client,
    bigquery_client: BigQueryConnector,
    full_refresh: bool,
) -> None:
    """
    Loads health data from the specified source(s) into BigQuery.

    Args:
        source (str): The source of health data to load (e.g., 'WORKOUTS', 'HEALTH', or 'ALL').
        storage_client (storage.Client): Google Cloud Storage client
        bigquery_client (BigQueryConnector): BigQuery client
        full_refresh (bool): Flag to perform a full refresh load
    """

    match source:
        case "WORKOUTS" | "HEALTH":
            sources = [source]
        case "ALL":
            sources = ["WORKOUTS", "HEALTH"]
        case _:
            raise ValueError(f"Unknown source: {source}")

    for source in sources:
        if full_refresh:
            truncate_single_source(
                source=source,
                bigquery_client=bigquery_client,
                log_table=LOG_TABLE_NAME,
                destination_schema=HEALTH_METRIC_FLAT_FILE_MAP["global"][
                    "destination_schema"
                ],
                destination_table=HEALTH_METRIC_FLAT_FILE_MAP[source.lower()][
                    "destination_table"
                ],
            )

        load_source_data_to_bigquery(
            source=source,
            storage_client=storage_client,
            bigquery_client=bigquery_client,
            log_table=LOG_TABLE_NAME,
            **HEALTH_METRIC_FLAT_FILE_MAP["global"],
            **HEALTH_METRIC_FLAT_FILE_MAP[source.lower()],
        )


@click.command()
@click.option(
    "--source",
    required=False,
    default="ALL",
    help="Source of health data (defaults to ALL)",
)
@click.option("--debug", is_flag=True, help="Enable debug logging")
@click.option("--quiet", is_flag=True, help="Disable all logs")
@click.option("--full-refresh", is_flag=True, help="Perform a full refresh load")
def main(source: str, debug: bool, quiet: bool, full_refresh: bool):
    """
    Depending on the user's input, loads health data from various sources
    from Google Drive into Google Cloud Storage, and then into BigQuery.

    Args:
        source (str): The source of health data to load (e.g., 'WORKOUTS', 'HEALTH', or 'ALL').
        debug (bool): Flag to enable debug logging
        quiet (bool): Flag to disable all logging
        full_refresh (bool): Flag to perform a full refresh load
    """

    if quiet and debug:
        raise ValueError("Cannot use both --quiet and --debug flags together")

    if quiet:
        metrics_logger.setLevel("WARNING")
    elif debug or os.environ["STAGE"] != "production":
        metrics_logger.setLevel("DEBUG")
        metrics_logger.debug("** Debugger Active **")

    if full_refresh:
        metrics_logger.warning("Performing full refresh load")

    storage_client = storage.Client()
    bigquery_client = BigQueryConnector(
        bypass_env_variable=os.environ["STAGE"] == "production"
    )

    if not bigquery_client.table_exists(LOG_TABLE_NAME):
        setup_log_table(
            bigquery_client=bigquery_client,
            log_table_name=LOG_TABLE_NAME,
        )

    load_source_data(
        source=source.strip().upper(),
        storage_client=storage_client,
        bigquery_client=bigquery_client,
        full_refresh=full_refresh,
    )


#####

if __name__ == "__main__":
    main()
