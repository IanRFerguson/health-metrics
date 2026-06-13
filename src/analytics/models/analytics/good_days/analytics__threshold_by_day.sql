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

    rolling AS (
        SELECT
            *,
            ARRAY_AGG(COALESCE(avg_food_score, 0)) OVER (
                ORDER BY target_date
                ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
            ) AS rolling_food_scores
        FROM base
    ),

    thresholds AS (
        SELECT

            target_date,
            total_exercise_minutes >= 30.0 AS threshold__exercise_minutes,
            total_step_count >= 10000 AS threshold__steps,
            COALESCE(has_high_impact_workout = TRUE, FALSE) AS threshold__high_impact_workout,

            -- Food score is >= 75th percentile for rolling 14-day window
            COALESCE(
                avg_food_score >= (
                SELECT PERCENTILE_CONT(score, 0.75) OVER ()
                FROM UNNEST(rolling_food_scores) AS score
                LIMIT 1
            ), FALSE) AS threshold__food_score

        FROM rolling
    )

SELECT
    *,
    {{
        calculate_good_day_threshold(
            fields=[
                "threshold__exercise_minutes",
                "threshold__steps",
                "threshold__high_impact_workout",
                "threshold__food_score"
            ],
            cutoff_percentile=0.7
        )
    }}
FROM thresholds
