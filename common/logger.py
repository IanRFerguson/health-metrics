import logging
import os
import sys

from colorlog import ColoredFormatter
from google.cloud.logging import Client as LoggingClient

#####

# If we're running production, persist logs to Google Cloud Logging
if os.environ.get("STAGE") == "production":
    logging_client = LoggingClient()
    logging_client.setup_logging()
    metrics_logger = logging.getLogger("google.cloud.logging")
    metrics_logger.setLevel("INFO")

# Otherwise, log to stdout with colored output
else:
    metrics_logger = logging.getLogger(__name__)
    _handler = logging.StreamHandler(sys.stdout)
    _formatter = ColoredFormatter(
        "%(log_color)s%(levelname)s%(reset)s %(message)s",
        reset=True,
        log_colors={
            "DEBUG": "cyan",
            "INFO": "green",
            "WARNING": "yellow",
            "ERROR": "red",
            "CRITICAL": "red,bg_white",
        },
        style="%",
    )

    _handler.setFormatter(_formatter)
    metrics_logger.addHandler(_handler)
    metrics_logger.setLevel("INFO")

    if os.environ.get("DEBUG") == "true":
        metrics_logger.setLevel("DEBUG")
        metrics_logger.debug("Logging at debug level")
