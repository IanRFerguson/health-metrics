WITH
    food_intake AS (
        SELECT

            load_date AS target_date,
            time_of_day,
            ARRAY_AGG(food_line_item) AS food_line_items

        FROM {{ ref("stg__00__food_journal") }}
        GROUP BY ALL
    ),

    workouts AS (
        SELECT

            workout_date AS target_date,
            time_of_day,
            ARRAY_AGG(
                STRUCT(
                    workout_type,
                    high_impact,
                    distance_in_miles,
                    total_energy,
                    active_energy,
                    max_heart_rate,
                    average_heart_rate,
                    step_count AS excercise_step_count
                )
            ) AS daily_workouts

        FROM {{ ref("stg__00__workouts") }}
        GROUP BY 1,2
    ),

    health_metrics AS (
        SELECT

            measurement_date AS target_date,
            time_of_day,
            ROUND(SUM(active_energy_kcal), 3) AS sum_active_energy_kcal,
            ROUND(SUM(physical_effort_kcal_hr_kg), 3) AS sum_physical_effort_kcal,
            ROUND(SUM(resting_energy_kcal), 3) AS sum_resting_energy_kcal,

            ROUND(SUM(excercise_minutes), 3) AS sum_excercise_minutes,
            ROUND(SUM(stand_count), 3) AS sum_stand_count,
            ROUND(SUM(flights_climbed), 3) AS sum_flights_climbed,
            ROUND(SUM(step_count), 3) AS sum_step_count,


        FROM {{ ref("stg__00__health_metrics") }}
        GROUP BY ALL
    )

SELECT

    health_metrics.target_date,
    health_metrics.time_of_day,
    health_metrics.sum_active_energy_kcal,
    health_metrics.sum_physical_effort_kcal,
    health_metrics.sum_resting_energy_kcal,
    health_metrics.sum_excercise_minutes,
    health_metrics.sum_stand_count,
    health_metrics.sum_flights_climbed,
    health_metrics.sum_step_count,
    workouts.daily_workouts,
    food_intake.food_line_items,
    {{
        dbt_utils.generate_surrogate_key(
            [
                "target_date",
                "time_of_day"
            ]
        )
    }} AS surrogate_pk

FROM health_metrics
LEFT JOIN workouts USING(target_date, time_of_day)
LEFT JOIN food_intake USING(target_date, time_of_day)