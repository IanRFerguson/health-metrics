import logging
import os
import sys

from colorlog import ColoredFormatter

#####

logger = logging.getLogger(__name__)
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
        "CRITICAL": "red,bg_white",  # Example with background color
    },
    secondary_log_colors={},
    style="%",
)

_handler.setFormatter(_formatter)
logger.addHandler(_handler)
logger.setLevel("INFO")

if os.environ.get("DEBUG") == "true":
    logger.setLevel("DEBUG")
    logger.debug("Logging at debug level")
