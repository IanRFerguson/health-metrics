WITH
    base AS (
        SELECT
            
            -- NOTE: This is to buffer against the watch
            -- assigning the wrong type of workout on start
            CASE
                WHEN UPPER(TRIM(`type`)) = 'OTHER'
                    THEN 'STRENGTH (OTHER)'
                ELSE UPPER(TRIM(`type`))
            END AS workout_type,
            
            SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M', `start`) AS workout_start,
            SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M', `end`) AS workout_end,
            duration AS workout_duration,

            CAST(total_energy__kcal AS FLOAT64) AS total_energy,
            CAST(active_energy__kcal AS FLOAT64) AS active_energy,
            CAST(max_heart_rate__bpm AS FLOAT64) AS max_heart_rate,
            CAST(avg_heart_rate__bpm AS FLOAT64) AS average_heart_rate,

            CAST(distance__mi AS FLOAT64) AS distance_in_miles,
            CAST(avg_speed_mi_hr AS FLOAT64) AS average_speed,
            CAST(step_count__count AS FLOAT64) AS step_count,
            CAST(step_cadence__spm AS FLOAT64) AS step_cadence,
            CAST(flights_climbed__count AS FLOAT64) AS flights_climbed,
            CAST(elevation_ascended__ft AS FLOAT64) AS elevation_ascended,
            CAST(elevation_descended__ft AS FLOAT64) AS elevation_descended,

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
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY workout_start, workout_type
            ORDER BY _load_timestamp DESC
        ) = 1
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
    _load_timestamp,
    {{
        dbt_utils.generate_surrogate_key(
            [
                "workout_start",
                "time_of_day"
            ]
        )
    }} AS surrogate_pk

FROM staged