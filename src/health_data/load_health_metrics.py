import os

import click
from constants import HEALTH_METRIC_FLAT_FILE_MAP
from google.cloud import storage
from google_helpers import load_source_data_to_bigquery
from klondike.gcp.bigquery import BigQueryConnector

from common.logger import logger

#####


def load_source_data(
    source: str, storage_client: storage.Client, bigquery_client: BigQueryConnector
):
    match source:
        case "WORKOUTS" | "HEALTH":
            sources = [source]
        case "ALL":
            sources = ["WORKOUTS", "HEALTH"]
        case _:
            raise ValueError(f"Unknown source: {source}")

    for source in sources:
        load_source_data_to_bigquery(
            source=source,
            storage_client=storage_client,
            bigquery_client=bigquery_client,
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
def main(source: str, debug: bool, quiet: bool):
    """
    Depending on the user's input, loads health data from various sources
    from Google Drive into Google Cloud Storage, and then into BigQuery.

    Args:
        source (str): The source of health data to load (e.g., 'WORKOUTS', 'HEALTH', or 'ALL').
        debug (bool): Flag to enable debug logging
        quiet (bool): Flag to disable all logging
    """

    if quiet:
        logger.setLevel("WARNING")
    elif debug or os.environ["STAGE"] != "production":
        logger.setLevel("DEBUG")
        logger.debug("** Debugger Active **")

    storage_client = storage.Client()
    bigquery_client = BigQueryConnector()

    load_source_data(
        source=source.strip().upper(),
        storage_client=storage_client,
        bigquery_client=bigquery_client,
    )


#####

if __name__ == "__main__":
    main()
