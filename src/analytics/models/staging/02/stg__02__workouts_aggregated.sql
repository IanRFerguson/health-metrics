SELECT

    EXTRACT(YEAR FROM target_date) AS year,
    EXTRACT(MONTH FROM target_date) AS month,
    CASE
        WHEN UPPER(workout_type) LIKE '%RUN%' THEN 'RUN'
        ELSE 'STRENGTH TRAINING'
    END AS workout_type,
    COUNT(*) AS workout_count,
    SUM(dw.distance_in_miles) AS total_mileage,
    {{ format_pace_string("CAST(AVG(dw.pace_seconds) AS INT64)") }} AS average_pace,
    ROUND(AVG(dw.duration_minutes), 3) AS average_workout_duration_minutes,
    ROUND(AVG(dw.total_energy), 3) AS average_total_energy,
    ROUND(AVG(dw.active_energy), 3) AS average_active_energy

FROM {{ ref("stg__01__health_metrics") }} AS health_metrics,
    UNNEST(daily_workouts) AS dw
WHERE dw.high_impact
GROUP BY 1, 2, 3