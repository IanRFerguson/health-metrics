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
def main(source: str):

    drive_client = None  # Placeholder for Drive client initialization
    storage_client = storage.Client()

    source = source.strip().upper()
    load_source_data_to_gcs(
        source=source, drive_client=drive_client, storage_client=storage_client
    )


#####

if __name__ == "__main__":
    main()
