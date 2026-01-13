{{
    config(
        cluster_by=["workout_type"]
    )
}}

WITH
    base AS (
        SELECT * FROM {{ ref("stg__01__health_metrics") }}
    )

SELECT

    DATE_TRUNC(target_date, WEEK(MONDAY)) AS start_date,
    workout_type,
    COUNT(*) AS workout_count,

    ROUND(MIN(dw.total_energy), 3) AS min_total_energy,
    ROUND(AVG(dw.total_energy), 3) AS avg_total_energy,
    ROUND(MAX(dw.total_energy), 3) AS max_total_energy,

    ROUND(MIN(dw.average_heart_rate), 3) AS min_average_heart_rate,
    ROUND(AVG(dw.average_heart_rate), 3) AS avg_average_heart_rate,
    ROUND(MAX(dw.average_heart_rate), 3) AS max_average_heart_rate

FROM base
LEFT JOIN UNNEST(base.daily_workouts) AS dw
WHERE dw.high_impact
GROUP BY ALL