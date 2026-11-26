{#
    Each threshold is TRUE/FALSE when it can be evaluated and NULL when the
    underlying data is missing, so is_good_day is judged only against real
    inputs (see the calculate_good_day_threshold macro).

    Relative thresholds compare a day against a baseline built from the
    previous 14 calendar days (excluding the day itself). Days without logged
    values are left out of the baseline, and a baseline needs at least
    `min_baseline_days` logged days; otherwise the threshold is NULL.
#}
{% set min_baseline_days = 7 %}

WITH
    base AS (
        SELECT
            {{
                dbt_utils.star(
                    from=ref("stg__02__metrics_per_day")
                )
            }}
        FROM {{ ref("stg__02__metrics_per_day") }}
    ),

    prior_window AS (
        -- Values are wrapped in STRUCTs because analytic ARRAY_AGG can't
        -- IGNORE NULLS and arrays can't hold bare NULLs; NULLs are dropped
        -- when the baselines are computed below.
        SELECT
            *,
            ARRAY_AGG(STRUCT(avg_food_score AS val)) OVER prior_14_days AS prior_food_scores,
            ARRAY_AGG(STRUCT(total_estimated_calories AS val)) OVER prior_14_days AS prior_estimated_calories,
            ARRAY_AGG(STRUCT(total_estimated_protein AS val)) OVER prior_14_days AS prior_estimated_protein

        FROM base
        WINDOW prior_14_days AS (
            ORDER BY UNIX_DATE(target_date)
            RANGE BETWEEN 14 PRECEDING AND 1 PRECEDING
        )
    ),

    baselines AS (
        SELECT
            *,
            (
                SELECT IF(COUNT(p.val) >= {{ min_baseline_days }}, APPROX_QUANTILES(p.val, 100)[OFFSET(75)], NULL)
                FROM UNNEST(prior_food_scores) AS p
            ) AS baseline_food_score_p75,
            (
                SELECT IF(COUNT(p.val) >= {{ min_baseline_days }}, APPROX_QUANTILES(p.val, 100)[OFFSET(75)], NULL)
                FROM UNNEST(prior_estimated_calories) AS p
            ) AS baseline_estimated_calories_p75,
            (
                SELECT IF(COUNT(p.val) >= {{ min_baseline_days }}, APPROX_QUANTILES(p.val, 100)[OFFSET(50)], NULL)
                FROM UNNEST(prior_estimated_protein) AS p
            ) AS baseline_estimated_protein_p50

        FROM prior_window
    ),

    thresholds AS (
        SELECT

            target_date,
            -- NULL when the day has no activity data
            total_exercise_minutes >= 30.0 AS threshold__exercise_minutes,
            total_step_count >= 10000 AS threshold__steps,
            -- NULL here means no workouts were logged, which is a real "no"
            COALESCE(has_high_impact_workout, FALSE) AS threshold__high_impact_workout,

            -- NULL when no food was logged or there isn't enough baseline history
            -- Food score is >= 75th percentile of the prior 14 days
            avg_food_score >= baseline_food_score_p75 AS threshold__food_score,
            -- Calories are <= 75th percentile of the prior 14 days
            total_estimated_calories <= baseline_estimated_calories_p75 AS threshold__estimated_calories,
            -- Protein is >= median of the prior 14 days
            total_estimated_protein >= baseline_estimated_protein_p50 AS threshold__estimated_protein

        FROM baselines
    )

-- Activity alone (3 thresholds) isn't enough to judge a day, so
-- min_thresholds_evaluated=4 requires at least one food threshold with data.
SELECT
    *,
    {{
        calculate_good_day_threshold(
            fields=[
                "threshold__exercise_minutes",
                "threshold__steps",
                "threshold__high_impact_workout",
                "threshold__food_score",
                "threshold__estimated_calories",
                "threshold__estimated_protein"
            ],
            min_thresholds_met=4,
            min_thresholds_evaluated=4
        )
    }}
FROM thresholds
