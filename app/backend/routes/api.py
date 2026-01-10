from flask import Blueprint, jsonify
from google.cloud import bigquery

from common.logger import metrics_logger

#####

bp = Blueprint("api", __name__, url_prefix="/api")
BQ_CLIENT = bigquery.Client()


@bp.route("/weekly-stats", methods=["GET"])
def get_weekly_stats():
    """
    This endpoint hits the analytical dbt models in BigQuery
    to get weekly health metrics for the current year.
    """

    metrics_logger.info("Fetching weekly health metrics from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        * 
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_week`
    WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE())
    ORDER BY start_date
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)


@bp.route("/last-updated-at", methods=["GET"])
def get_dbt_last_updated_at():
    """
    This endpoint retrieves the last updated timestamp
    of the dbt models from BigQuery.
    """

    metrics_logger.info("Fetching dbt last updated timestamp from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        MAX(_dbt_last_run_at) AS last_updated_at
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_week`
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    row = next(results)
    last_updated_at = row["last_updated_at"]
    metrics_logger.info(f"dbt last updated at: {last_updated_at}")

    return jsonify({"last_updated_at": last_updated_at.isoformat()})
