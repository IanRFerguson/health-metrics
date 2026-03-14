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

    weight_raw AS (
        SELECT
            target_date,
            MAX(weight_lb) AS max_weight_lb
        FROM base
        GROUP BY target_date
    ),

    weight_modeled AS (
        SELECT
            target_date,
            COALESCE(
                max_weight_lb,
                LAG(max_weight_lb) OVER (ORDER BY target_date)
            ) AS max_weight_lb
        FROM weight_raw
    ),

    food_raw AS (
        SELECT

            surrogate_line_item_pk,
            score

        FROM {{ source("scored_records", "stg__02__food_intake_scored") }}
    ),

    food_modeled AS (
        SELECT

            base.target_date,
            ARRAY_AGG(
                STRUCT(
                    fli.surrogate_line_item_pk,
                    fli.food_line_item,
                    fr.score
                )
            ) AS scored_food_line_items

        FROM base,
            UNNEST(base.food_line_items) AS fli
        LEFT JOIN food_raw AS fr
            ON fli.surrogate_line_item_pk = fr.surrogate_line_item_pk
        GROUP BY 1
    ),

    food_agg AS (
        SELECT

            target_date,
            MIN(score) AS min_food_score,
            AVG(score) AS avg_food_score,
            MAX(score) AS max_food_score,
            SUM(score) AS total_food_score

        FROM food_modeled,
            UNNEST(scored_food_line_items) AS sfi
        GROUP BY 1
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
    )

    
SELECT

    staged.*,
    wm.max_weight_lb,
    fm.scored_food_line_items,
    fa.min_food_score,
    fa.avg_food_score,
    fa.max_food_score,
    fa.total_food_score,

    -- Extract total_miles_run from the final array in the outer SELECT
    (
        SELECT ROUND(SUM(CAST(dw.distance_in_miles AS FLOAT64)), 3)
        FROM UNNEST(all_daily_workouts) AS dw
        WHERE dw.workout_type LIKE '%RUN%'
    ) AS total_miles_run

FROM staged
LEFT JOIN weight_modeled AS wm USING (target_date)
LEFT JOIN food_modeled AS fm USING (target_date)
LEFT JOIN food_agg AS fa USING (target_date)