import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.backend.logic.notifications.email_helpers import send_email_notification
from app.backend.logic.notifications.gemini_helpers import (
    STORAGE_CLIENT,
    get_gemini_summaries,
    write_summary_to_gcs,
)

#####


def main():
    weekly_summaries = get_gemini_summaries()
    send_email_notification(summaries=weekly_summaries)
    write_summary_to_gcs(
        storage_client=STORAGE_CLIENT,
        bucket_name=os.environ["GCS_BUCKET_NAME"],
        summary=weekly_summaries["overall_health"],
    )


#####

if __name__ == "__main__":
    main()
