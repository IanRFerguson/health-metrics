import click
from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector
from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

from common.logger import logger

#####


def load_source_data_to_gcs(
    source: str, drive_client: GoogleDrive, storage_client: storage.Client
):
    pass


@click.command()
@click.option(
    "--source",
    required=False,
    default="ALL",
    help="Source of health data (defaults to ALL)",
)
@click.option("--debug", is_flag=True, help="Enable debug logging")
def main(source: str, debug: bool):
    """
    Depending on the user's input, loads health data from various sources
    from Google Drive into Google Cloud Storage, and then into BigQuery.

    Args:
        source (str): The source of health data to load (e.g., 'FITBIT', 'APPLE_HEALTH', or 'ALL').
        debug (bool): Flag to enable debug logging
    """

    if debug:
        logger.setLevel("DEBUG")
        logger.debug("** Debugger Active **")

    drive_client = None  # Placeholder for Drive client initialization
    storage_client = storage.Client()

    load_source_data_to_gcs(
        source=source.strip().upper(),
        drive_client=drive_client,
        storage_client=storage_client,
    )


#####

if __name__ == "__main__":
    main()
