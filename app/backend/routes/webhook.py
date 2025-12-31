import os
import tempfile
from datetime import datetime
import io
import pandas as pd

from flask import Blueprint, request
from google.cloud import storage

from common.logger import logger

#####

bp = Blueprint("webhook", __name__, url_prefix="/webhook")


def write_bytes_to_gcs(
    bucket_name: str, blob_name: str, payload: str, data_type: str
) -> None:
    """
    Catches webhook data and uploads it to Google Cloud Storage as a CSV file.

    Args:
        bucket_name (str): The name of the GCS bucket.
        blob_name (str): The name of the blob (file) in the GCS bucket.
        payload (str): The raw CSV data as a string.
        data_type (str): The type of data being uploaded (for logging purposes).
    """

    with io.StringIO(payload) as csv_file:
        with tempfile.NamedTemporaryFile(mode="w+", delete=True) as temp_file:
            # Write the CSV data to a temporary file
            temp_file.write(csv_file.read())
            temp_file.flush()

            logger.debug("Temporary file created at %s", temp_file.name)

            # Load the CSV data into a pandas DataFrame
            df = pd.read_csv(temp_file.name)

    # Initialize Google Cloud Storage client
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    # Upload the DataFrame as a CSV to GCS
    blob.upload_from_string(df.to_csv(index=False), content_type="text/csv")

    logger.info(f"Uploaded {data_type} data to gs://%s/%s", bucket_name, blob_name)


@bp.route("/load", methods=["POST"])
def webhook_load():
    if request.method != "POST":
        return "Method Not Allowed", 405

    # Get data type from the request string
    data_type = request.args.get("data_type")

    # Validate request args
    if not data_type:
        return "Bad Request: Missing data_type parameter", 400
    elif data_type not in ["health-metrics", "workouts"]:
        return "Bad Request: Invalid data_type parameter", 400

    # Validate auehtnication
    api_key = request.headers.get("X_API_KEY")
    logger.debug("Received API key: %s", api_key)

    webhook_api_key = os.environ.get("WEBHOOK_API_KEY")
    logger.debug("Expected API key: %s", webhook_api_key)
    if api_key != webhook_api_key:
        return "Unauthorized", 401

    # Read the raw payload from the request
    payload = request.data.decode("utf-8")
    logger.debug("Received webhook payload at %s", datetime.now())

    write_bytes_to_gcs(
        bucket_name=os.environ["GCS_BUCKET_NAME"],
        blob_name=f"{data_type}/{data_type}__{datetime.now().strftime('%Y%m%d%H%M%S')}.csv",
        payload=payload,
        data_type=data_type,
    )

    return "OK"
