WITH
    health_metrics AS (
        SELECT
            {{
                dbt_utils.star(
                    from=ref("stg__02__metrics_per_day")
                )
            }}
        FROM {{ ref("stg__02__metrics_per_day") }}
    ),

    good_day_thresholds AS (
        SELECT
            {{
                dbt_utils.star(
                    from=ref("analytics__threshold_by_day")
                )
            }}
        FROM {{ ref("analytics__threshold_by_day") }}
    ),

    joined AS (
        SELECT

            hm.target_date,
            hm.total_active_energy_kcal,
            hm.total_physical_effort_kcal,
            hm.total_resting_energy_kcal,
            hm.total_exercise_minutes,
            hm.total_stand_count,
            hm.total_flights_climbed,
            hm.total_step_count,
            hm.all_daily_workouts,
            hm.max_weight_lb,
            hm.scored_food_line_items,
            hm.min_food_score,
            hm.avg_food_score,
            hm.max_food_score,
            hm.total_food_score,
            hm.total_estimated_calories,
            hm.total_estimated_protein,
            hm.has_high_impact_workout,
            hm.total_miles_run,
            gdt.threshold__exercise_minutes,
            gdt.threshold__steps,
            gdt.threshold__high_impact_workout,
            gdt.threshold__food_score,
            gdt.threshold__estimated_calories,
            gdt.threshold__estimated_protein,
            gdt.is_good_day

        FROM health_metrics AS hm
        LEFT JOIN good_day_thresholds AS gdt
            ON hm.target_date = gdt.target_date
    )

SELECT *
FROM joined
