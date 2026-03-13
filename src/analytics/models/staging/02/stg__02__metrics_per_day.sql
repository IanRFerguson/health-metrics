WITH 
    base AS (
        SELECT 
        
            {{
                dbt_utils.star(
                    ref("stg__01__health_metrics")
                )
            }}
        
        FROM {{ ref("stg__01__health_metrics") }}
    ),

    staged AS (
        SELECT
            
            target_date,
            ROUND(SUM(sum_active_energy_kcal), 3) AS total_active_energy_kcal,
            ROUND(SUM(sum_physical_effort_kcal), 3) AS total_physical_effort_kcal,
            ROUND(SUM(sum_resting_energy_kcal), 3) AS total_resting_energy_kcal,
            ROUND(SUM(sum_exercise_minutes), 3) AS total_exercise_minutes,
            ROUND(SUM(sum_stand_count), 3) AS total_stand_count,
            ROUND(SUM(sum_flights_climbed), 3) AS total_flights_climbed,
            ROUND(SUM(sum_step_count), 3) AS total_step_count,
            
            -- Use ARRAY_CONCAT_AGG only if base has multiple rows per date
            ARRAY_CONCAT_AGG(daily_workouts) AS all_daily_workouts
        
        FROM base
        GROUP BY 1
    ),

    staged AS (
        SELECT

            activity.*,
            food.food_line_items,
            food.total_food_score,
            food.average_food_score,
            food.min_food_score,
            food.max_food_score

        FROM activity_agg AS activity
        LEFT JOIN food_scores_agg AS food
            ON activity.target_date = food.target_date
    )

    
SELECT

    staged.*,
    wm.max_weight_lb,

    -- Extract total_miles_run from the final array in the outer SELECT
    (
        SELECT ROUND(SUM(CAST(dw.distance_in_miles AS FLOAT64)), 3)
        FROM UNNEST(all_daily_workouts) AS dw
        WHERE dw.workout_type LIKE '%RUN%'
    ) AS total_miles_run

FROM staged
JOIN weight_modeled AS wm USING (target_date)