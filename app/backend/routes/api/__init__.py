from flask import Blueprint
from google.cloud import bigquery

#####

bp = Blueprint("api", __name__, url_prefix="/api")
BQ_CLIENT = bigquery.Client()

# Import routes to register them with the blueprint
from . import metadata, stats, workouts  # noqa: E402, F401
