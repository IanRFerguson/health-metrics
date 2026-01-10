import logging
import os
import sys

from colorlog import ColoredFormatter
from google.cloud.logging import Client as LoggingClient

#####

if os.environ.get("STAGE") != "production":
    metrics_logger = logging.getLogger(__name__)
    _handler = logging.StreamHandler(sys.stdout)
    _formatter = ColoredFormatter(
        "%(log_color)s%(levelname)s%(reset)s %(message)s",
        datefmt=None,
        reset=True,
        log_colors={
            "DEBUG": "cyan",
            "INFO": "green",
            "WARNING": "yellow",
            "ERROR": "red",
            "CRITICAL": "red,bg_white",
        },
        secondary_log_colors={},
        style="%",
    )

    _handler.setFormatter(_formatter)
    metrics_logger.addHandler(_handler)
    metrics_logger.setLevel("INFO")

    if os.environ.get("DEBUG") == "true":
        metrics_logger.setLevel("DEBUG")
        metrics_logger.debug("Logging at debug level")

else:
    logging_client = LoggingClient()
    logging_client.setup_logging()
    metrics_logger = logging.getLogger("google.cloud.logging")
    metrics_logger.setLevel("INFO")
