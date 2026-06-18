from flask import jsonify

from common.logger import metrics_logger

from . import BQ_CLIENT, bp

#####


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
    FROM `ian-is-online.health_metrics_marts.metrics_per_week`
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    row = next(results)
    last_updated_at = row["last_updated_at"]
    metrics_logger.info(f"dbt last updated at: {last_updated_at}")

    return jsonify({"last_updated_at": last_updated_at.isoformat()})
