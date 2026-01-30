from flask import jsonify

from common.logger import metrics_logger

from . import BQ_CLIENT, bp

#####


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
    FROM `ian-is-online.dbt_health_metrics_analytics.metrics_per_week`
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
    FROM `ian-is-online.dbt_health_metrics_analytics.metrics_per_day`
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
    FROM `ian-is-online.dbt_health_metrics_analytics.metrics_per_month`
    WHERE year = EXTRACT(YEAR FROM CURRENT_DATE())
    ORDER BY year, month
    """
    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)
