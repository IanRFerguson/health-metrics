WITH
    base AS (
        SELECT
            
            UPPER(TRIM(`type`)) AS workout_type,
            SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M', `start`) AS workout_start,
            SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M', `end`) AS workout_end,
            duration AS workout_duration,

            total_energy__kcal AS total_energy,
            active_energy__kcal AS active_energy,
            max_heart_rate__bpm AS max_heart_rate,
            avg_heart_rate__bpm AS average_heart_rate,

            distance__mi AS distance_in_miles,
            avg_speed_mi_hr AS average_speed,
            step_count__count AS step_count,
            step_cadence__spm AS step_cadence,
            flights_climbed__count AS flights_climbed,
            elevation_ascended__ft AS elevation_ascended,
            elevation_descended__ft AS elevation_descended,

            _load_timestamp

        FROM {{ ref("base__workouts")}}
    ),

    staged AS (
        SELECT

            base.*,
            {{ parse_time_of_day("workout_start") }} AS time_of_day,
            (workout_type LIKE ANY('%RUN%', '%STRENGTH%')) AS high_impact

        FROM base
        GROUP BY ALL
    )

SELECT

    CAST(workout_start AS DATE) AS workout_date,
    workout_type,
    workout_start,
    workout_end,
    workout_duration,
    high_impact,
    time_of_day,
    distance_in_miles,
    total_energy,
    active_energy,
    max_heart_rate,
    average_heart_rate,
    average_speed,
    step_count,
    step_cadence,
    flights_climbed,
    elevation_ascended,
    elevation_descended,    
    _load_timestamp

FROM staged