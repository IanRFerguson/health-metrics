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

        FROM base
        LEFT JOIN UNNEST(base.daily_workouts) AS dw
        GROUP BY 1
    ),

    staged AS (
        SELECT

            DATE_TRUNC(target_date, WEEK(MONDAY)) AS start_date,

            -- TOTALS
            ROUND(SUM(sum_active_energy_kcal), 3) AS total_active_energy_kcal,
            ROUND(SUM(sum_physical_effort_kcal), 3) AS total_physical_effort_kcal,
            ROUND(SUM(sum_resting_energy_kcal), 3) AS total_resting_energy_kcal,
            ROUND(SUM(sum_exercise_minutes), 3) AS total_exercise_minutes,
            ROUND(SUM(sum_stand_count), 3) AS total_stand_count,
            ROUND(SUM(sum_flights_climbed), 3) AS total_flights_climbed,
            ROUND(SUM(sum_step_count), 3) AS total_step_count,
            
            MIN(weight_lb) AS min_weight_lb,
            ROUND(AVG(weight_lb), 3) AS avg_weight_lb,
            MAX(weight_lb) AS max_weight_lb,
            
            NULL AS food_score,

            COUNT(*) AS days_recorded
        
        FROM base
        GROUP BY 1
    )

SELECT 
    
    staged.* EXCEPT(days_recorded),

    -- AVERAGES
    ROUND(staged.total_active_energy_kcal / NULLIF(staged.days_recorded, 0), 3) AS avg_active_energy_kcal,
    ROUND(staged.total_physical_effort_kcal / NULLIF(staged.days_recorded, 0), 3) AS avg_physical_effort_kcal,
    ROUND(staged.total_resting_energy_kcal / NULLIF(staged.days_recorded, 0), 3) AS avg_resting_energy_kcal,
    ROUND(staged.total_exercise_minutes / NULLIF(staged.days_recorded, 0), 3) AS avg_exercise_minutes,
    ROUND(staged.total_stand_count / NULLIF(staged.days_recorded, 0), 3) AS avg_stand_count,
    ROUND(staged.total_flights_climbed / NULLIF(staged.days_recorded, 0), 3) AS avg_flights_climbed,
    ROUND(staged.total_step_count / NULLIF(staged.days_recorded, 0), 3) AS avg_step_count,

    workout_metrics.high_impact_workouts,
    workout_metrics.total_miles_run,
    CURRENT_TIMESTAMP() AS _dbt_last_run_at


FROM staged
LEFT JOIN workout_metrics USING(start_date)