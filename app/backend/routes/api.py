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


@bp.route("/daily-stats", methods=["GET"])
def get_daily_stats():
    """
    This endpoint hits the analytical dbt models in BigQuery
    to get daily health metrics for the current year.
    """

    metrics_logger.info("Fetching daily health metrics from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        * EXCEPT(target_date),
        target_date AS start_date
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_day`
    WHERE EXTRACT(YEAR FROM target_date) = EXTRACT(YEAR FROM CURRENT_DATE())
    ORDER BY target_date
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)


@bp.route("/monthly-stats", methods=["GET"])
def get_monthly_stats():
    """
    This endpoint hits the analytical dbt models in BigQuery
    to get monthly health metrics for the current year.
    """

    metrics_logger.info("Fetching monthly health metrics from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        year,
        month,
        strength_workouts,
        running_workouts,
        total_miles_run,
        pct_weeks_running_goal_met * 100.0 AS pct_weeks_running_goal_met,
        avg_step_count,
        avg_weight_lb,
        weight_loss_since_new_year_pct
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_month`
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE())
    ORDER BY year, month
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)


@bp.route("/total-miles-run", methods=["GET"])
def get_total_miles_run():
    """
    This endpoint retrieves the total miles run
    from the analytical dbt models in BigQuery.
    """

    metrics_logger.info("Fetching total miles run from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        SUM(total_miles_run) AS total_miles_run
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_week`
    WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE())
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    row = next(results)
    total_miles_run = row["total_miles_run"]
    metrics_logger.info(f"Total miles run: {total_miles_run}")

    return jsonify({"total_miles_run": total_miles_run})


@bp.route("/weekly-running-goal-met", methods=["GET"])
def get_weekly_running_goal_met():
    """
    This endpoint retrieves the percentage of weeks
    where the running goal was met from BigQuery.
    """

    metrics_logger.info("Fetching weekly running goal met percentage from BigQuery")

    # TODO - Let's move the project / dataset to a config at some point
    query = """
    SELECT 
        COUNTIF(running_goal_met) / COUNT(*) AS pct_weeks_running_goal_met
    FROM `ian-is-online.dbt_health_metrics_analytics.cln__metrics_per_week`
    WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE())
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    row = next(results)
    pct_weeks_running_goal_met = row["pct_weeks_running_goal_met"]
    metrics_logger.info(
        f"Weekly running goal met percentage: {pct_weeks_running_goal_met}"
    )

    return jsonify({"pct_weeks_running_goal_met": pct_weeks_running_goal_met})


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
