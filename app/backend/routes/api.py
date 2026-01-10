from flask import Blueprint, jsonify
from google.cloud import bigquery

from common.logger import metrics_logger

#####

bp = Blueprint("api", __name__, url_prefix="/api")


@bp.route("weekly-stats", methods=["GET"])
def get_weekly_stats():
    """
    This endpoint hits the analytical dbt models in BigQuery
    to get weekly health metrics for the current year.
    """

    metrics_logger.info("Fetching weekly health metrics from BigQuery")

    query = """
    SELECT 
        * 
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_week`
    -- WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE())
    ORDER BY start_date DESC
    """
    metrics_logger.debug(f"Executing query: {query}")

    client = bigquery.Client()
    query_job = client.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)
