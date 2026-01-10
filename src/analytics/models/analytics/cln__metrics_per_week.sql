WITH
    base AS (
        SELECT * FROM {{ ref("stg__01__health_metrics") }}
    ),

    workout_metrics AS (
        SELECT

            DATE_TRUNC(target_date, WEEK(MONDAY)) AS start_date,
            COUNTIF(dw.high_impact) AS high_impact_workouts,
            ROUND(
                SUM(
                    CASE 
                        WHEN dw.workout_type LIKE '%RUN%' THEN dw.distance_in_miles 
                        ELSE 0 
                    END
                ), 
            3) AS total_miles_run

        FROM base,
            UNNEST(base.daily_workouts) AS dw
        GROUP BY 1
    ),

    staged AS (
        SELECT

            DATE_TRUNC(target_date, WEEK(MONDAY)) AS start_date,
            ROUND(SUM(sum_active_energy_kcal), 3) AS total_active_energy_kcal,
            ROUND(SUM(sum_physical_effort_kcal), 3) AS total_physical_effort_kcal,
            ROUND(SUM(sum_resting_energy_kcal), 3) AS total_resting_energy_kcal,
            ROUND(SUM(sum_excercise_minutes), 3) AS total_exercise_minutes,
            ROUND(SUM(sum_stand_count), 3) AS total_stand_count,
            ROUND(SUM(sum_flights_climbed), 3) AS total_flights_climbed,
            ROUND(SUM(sum_step_count), 3) AS total_step_count,
            
            MIN(weight_lb) AS min_weight_lb,
            ROUND(AVG(weight_lb), 3) AS avg_weight_lb,
            MAX(weight_lb) AS max_weight_lb,
            
            NULL AS food_score
        
        FROM base
        GROUP BY 1
    )

SELECT 
    
    staged.*,
    workout_metrics.high_impact_workouts,
    workout_metrics.total_miles_run,
    CURRENT_TIMESTAMP() AS _dbt_last_run_at


FROM staged
JOIN workout_metrics USING(start_date)