WITH
    base AS (
        SELECT

            {{
                dbt_utils.star(
                    from=ref("stg__02__metrics_per_day"),
                )
            }}

        FROM {{ ref("stg__02__metrics_per_day") }}
        
        -- NOTE: We'll calculate these numbers on a rolling 30 day basis
        WHERE {{ get_date_window("target_date") }}
    ),

    modeled AS (
        SELECT

            EXTRACT(dayofweek from target_date) as dow_num,
            UPPER(FORMAT_DATE('%A', target_date)) as dow_name,

            COUNTIF(total_miles_run IS NOT NULL) as days_run,
            ROUND(SUM(total_miles_run), 3) AS total_miles_run,
            ROUND(AVG(total_exercise_minutes), 3) AS avg_exercise_minutes,
            ROUND(AVG(total_step_count), 3) AS avg_step_count,
            ROUND(AVG(avg_food_score), 3) AS avg_food_score

        FROM base
        GROUP BY ALL   
    )

SELECT
    *
FROM modeled