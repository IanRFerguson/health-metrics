WITH
    base AS (
        SELECT

            date_time,
            CAST(sleep_analysis_asleep__hr AS FLOAT64) AS sleep_analysis_asleep__hr,
            CAST(sleep_analysis_awake__hr AS FLOAT64) AS sleep_analysis_awake__hr,
            CAST(sleep_analysis_core__hr AS FLOAT64) AS sleep_analysis_core__hr,
            CAST(sleep_analysis_deep__hr AS FLOAT64) AS sleep_analysis_deep__hr,
            CAST(sleep_analysis_in_bed__hr AS FLOAT64) AS sleep_analysis_in_bed__hr,
            CAST(sleep_analysis_rem__hr AS FLOAT64) AS sleep_analysis_rem__hr,
            CAST(sleep_analysis_total__hr AS FLOAT64) AS sleep_analysis_total__hr 

        FROM {{ ref("base__health_metrics")}}
    ),

    modeled AS (
        SELECT

            DATE(date_time) AS measurement_date,
            sleep_analysis_asleep__hr AS sleep__asleep_hr,
            sleep_analysis_awake__hr AS sleep__awake_hr,
            sleep_analysis_core__hr AS sleep__core_hr,
            sleep_analysis_deep__hr AS sleep__deep_hr,
            sleep_analysis_in_bed__hr AS sleep__in_bed_hr,
            sleep_analysis_rem__hr AS sleep__rem_hr,
            sleep_analysis_total__hr AS sleep__total_hr,
            {{
                dbt_utils.generate_surrogate_key(
                    [
                        "date_time"
                    ]
                )
            }} AS surrogate_pk

        FROM base
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY DATE(date_time)
            ORDER BY sleep_analysis_total__hr DESC NULLS LAST
        ) = 1
    )

SELECT 
    *,
    sleep__total_hr >= 2.5 AS sleep__is_valid
FROM modeled
WHERE sleep__total_hr IS NOT NULL