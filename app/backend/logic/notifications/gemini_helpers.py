import os
import time
from typing import Optional

from google.cloud import storage

from common.logger import metrics_logger

from .constants import (
    GEMINI_CLIENT,
    GEMINI_MODEL,
    KLONDIKE_CONNECTOR,
    PROMPT,
    STORAGE_CLIENT,
)

#####


def generate_summary(
    category: str,
    daily_data: dict,
    weekly_data: Optional[dict] = None,
    last_summary: Optional[str] = None,
) -> str:
    """
        Generate a summary for the given category using the Gemini API.

        Args:
            category (str): The category of the data (e.g., "overall_health").
            daily_data (dict): The daily data to be summarized.
            weekly_data (Optional[dict]): The weekly data to be summarized.
            last_summary (Optional[str]): The last summary that was generated, if available.
    ß
        Returns:
            str: The generated summary.
    """

    prompt = f"{PROMPT}\n\nDaily Data:\n{daily_data}"

    if weekly_data:
        prompt += f"\n\nWeekly Data:\n{weekly_data}"

    if last_summary:
        prompt += f"\n\nThis is the last summary you generated for me:\n{last_summary}"

    response = GEMINI_CLIENT.models.generate_content(
        model=GEMINI_MODEL, contents=prompt
    )

    gemini_output = response.text.strip().replace("```html", "").replace("```", "")
    metrics_logger.debug(f"Gemini output for category '{category}': {gemini_output}")

    return gemini_output


def fetch_last_summary(
    storage_client: storage.Client, bucket_name: str, prefix: str = "gemini_summaries"
) -> Optional[str]:
    """
    Fetch the last summary from Google Cloud Storage.

    Args:
        storage_client: The Google Cloud Storage client.
        bucket_name (str): The name of the GCS bucket.
        prefix (str): The prefix for the blobs in the bucket.

    Returns:
        Optional[str]: The last summary if available, otherwise None.
    """

    try:
        bucket = storage_client.bucket(bucket_name)

        all_blobs = list(bucket.list_blobs(prefix=prefix))
        if all_blobs:
            latest_blob = max(all_blobs, key=lambda b: b.updated)
            return latest_blob.download_as_text()

    except Exception as e:
        metrics_logger.error(f"Error fetching last summary: {e}")

    return None


def get_gemini_summaries() -> dict:
    """
    Get summaries for all categories using the Gemini API.

    Returns:
        dict: A dictionary containing summaries for each category.
    """

    with open(
        os.path.join(os.path.dirname(__file__), "query__last_week.sql")
    ) as _query:
        query = _query.read()
        metrics_logger.debug(f"Executing query for Gemini summaries: {query}")
        resp = KLONDIKE_CONNECTOR.query(query)
        past_week_data = resp.to_dicts()

    with open(
        os.path.join(os.path.dirname(__file__), "query__this_year.sql")
    ) as _query:
        query = _query.read()
        metrics_logger.debug(f"Executing query for Gemini summaries: {query}")
        resp = KLONDIKE_CONNECTOR.query(query)
        past_year_data = resp.to_dicts()

    last_summary = fetch_last_summary(
        storage_client=STORAGE_CLIENT,
        bucket_name=os.environ["GCS_BUCKET_NAME"],
        prefix="gemini_summaries",
    )

    metrics_logger.debug(f"Data retrieved for Gemini summaries: {past_week_data}")
    summaries = {
        "overall_health": generate_summary(
            "overall_health",
            daily_data=past_week_data,
            weekly_data=past_year_data,
            last_summary=last_summary,
        )
    }

    return summaries


def write_summary_to_gcs(
    storage_client: storage.Client, bucket_name: str, summary: str
) -> None:
    """
    Write the generated summary to Google Cloud Storage.

    Args:
        storage_client: The Google Cloud Storage client.
        bucket_name (str): The name of the GCS bucket.
        summary (str): The summary to be written to GCS.
    """

    try:
        # Get the bucket and create a new blob
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(f"gemini_summaries/summary_{int(time.time())}.html")

        # Write the summary to the blob
        blob.upload_from_string(summary, content_type="text/html")
        metrics_logger.debug("Summary successfully written to GCS.")

    except Exception as e:
        metrics_logger.error(f"Error writing summary to GCS: {e}")
