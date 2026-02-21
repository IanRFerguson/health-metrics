import os

from flask import Blueprint, request
from logic.notifications.email_helpers import send_email_notification
from logic.notifications.gemini_helpers import (
    STORAGE_CLIENT,
    get_gemini_summaries,
    write_summary_to_gcs,
)

from common.logger import metrics_logger

#####

bp = Blueprint("email_summaries", __name__, url_prefix="/notify")


@bp.route("/email-summaries", methods=["POST"])
def send_email_summaries() -> tuple[dict[str, str], int]:
    """
    This endpoint will trigger the sending of email summaries to users.
    The actual implementation of sending emails would be handled by a background task or service.
    """

    TRIGGER_KEY = request.get_json().get("trigger_key")
    if not TRIGGER_KEY:
        return {"error": "Missing trigger key"}, 400

    elif not TRIGGER_KEY == os.getenv("EMAIL_SUMMARIES_TRIGGER_KEY"):
        return {"error": "Unauthorized"}, 401

    metrics_logger.info("Received request to send email summaries...")

    # Fetch summaries from Gemini
    weekly_summaries = get_gemini_summaries()
    metrics_logger.info("Fetched weekly summaries from Gemini...")

    # Send email notification with the summaries
    send_email_notification(summaries=weekly_summaries)
    metrics_logger.info("Sent email notification with weekly summaries...")

    # Write the resulting summary to GCS for safekeeping and future reference
    write_summary_to_gcs(
        storage_client=STORAGE_CLIENT,
        bucket_name=os.environ["GCS_BUCKET_NAME"],
        summary=weekly_summaries["overall_health"],
    )
    metrics_logger.info("Wrote weekly summaries to GCS...")

    return {"message": "Email summaries have been triggered for sending."}, 200
