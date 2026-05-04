from flask import jsonify, request

from common.logger import metrics_logger

from . import BQ_CLIENT, bp

#####


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
    FROM `ian-is-online.dbt_health_metrics_analytics.metrics_per_week`
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
    FROM `ian-is-online.dbt_health_metrics_analytics.metrics_per_week`
    WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE())
        AND NOT _is_current_week
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


@bp.route("/workout-stats", methods=["GET"])
def get_workout_stats():
    """
    This endpoint retrieves workout statistics
    from the analytical dbt models in BigQuery.
    """

    metrics_logger.info("Fetching workout stats from BigQuery")

    # Run against daily or aggregated table based on query parameter
    if request.args.get("daily") == "true":
        query = """
            SELECT 
                *
            FROM `ian-is-online.dbt_health_metrics_analytics.workouts`
            WHERE EXTRACT(YEAR FROM target_date) = EXTRACT(YEAR FROM CURRENT_DATE())
            ORDER BY target_date ASC
            """
    else:
        query = """
            SELECT 
                *
            FROM `ian-is-online.dbt_health_metrics_analytics.workouts_aggregated`
            WHERE year = EXTRACT(YEAR FROM CURRENT_DATE())
            ORDER BY year, month, workout_type
            """

    metrics_logger.debug(f"Executing query: {query}")

    query_job = BQ_CLIENT.query(query)
    results = query_job.result()

    data = [dict(row) for row in results]
    metrics_logger.info(f"Retrieved {len(data)} records from BigQuery")

    return jsonify(data)
