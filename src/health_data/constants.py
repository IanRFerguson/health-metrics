import os

from common.logger import metrics_logger

# NOTE: We can optionally write to a development schema
# that will wipe the tables after 30 minutes
if os.environ["STAGE"] == "production":
    DESTINATION_SCHEMA_NAME = os.environ["DESTINATION_SCHEMA_PROD"]
else:
    DESTINATION_SCHEMA_NAME = os.environ["DESTINATION_SCHEMA_DEV"]
    metrics_logger.debug(f"Writing to development schema ({DESTINATION_SCHEMA_NAME})")


HEALTH_METRIC_FLAT_FILE_MAP = {
    "global": {
        "bucket_name": os.environ["GCS_BUCKET_NAME"],
        "destination_schema": DESTINATION_SCHEMA_NAME,
    },
    "workouts": {"prefix": "workouts", "destination_table": "apple_workouts"},
    "health": {
        "prefix": "health-metrics",
        "destination_table": "apple_health_metrics",
    },
}
