SELECT

    target_date,
    CASE
        WHEN dw.workout_type LIKE '%RUN%'
            THEN 'RUN'
        ELSE 'STRENGTH TRAINING'
    END AS workout_type,
    dw.distance_in_miles AS mileage,
    {{ format_pace_string("dw.pace_seconds") }} AS pace,
    dw.workout_duration,
    dw.total_energy,
    dw.active_energy

FROM {{ ref("stg__01__health_metrics") }} AS health_metrics,
    UNNEST(daily_workouts) AS dw
WHERE dw.high_impact