{% set target_columns = [
    "active_energy_kcal",
    "physical_effort_kcal_hr_kg",
    "resting_energy_kcal",
    "exercise_minutes",
    "stand_count",
    "stand_minutes",
    "blood_oxygen_saturation_percent",
    "cardio_recovery_minutes",
    "flights_climbed",
    "heart_rate_minimum_minutes",
    "heart_rate_maximum_minutes",
    "heart_rate_resting_minutes",
    "heart_rate_average_minutes",
    "heart_rate_variability_ms",
    "resting_heart_rate_minutes",
    "stair_speed_down_ft_s",
    "stair_speed_up_ft_s",
    "step_count",
    "time_in_daylight_min",
    "vo2_max_ml_kg_min",
    "walking_plus_running_distance_mi",
    "walking_asymmetry_percentage_percent",
    "walking_double_support_percentage_percent",
    "walking_heart_rate_average_minutes",
    "walking_speed_mi_hr",
    "walking_step_length_in"
] %}

WITH
    base AS (
        SELECT
        
            date_time,
            CAST(active_energy__kcal AS FLOAT64) AS active_energy_kcal,
            CAST(physical_effort__kcal_hr_kg AS FLOAT64) AS physical_effort_kcal_hr_kg,
            CAST(resting_energy__kcal AS FLOAT64) AS resting_energy_kcal,
            
            CAST(apple_exercise_time__min AS FLOAT64) AS exercise_minutes,
            CAST(apple_stand_hour__count AS FLOAT64) AS stand_count,
            CAST(apple_stand_time__min AS FLOAT64) AS stand_minutes,
            CAST(`blood_oxygen_saturation__%` AS FLOAT64) AS blood_oxygen_saturation_percent,
            CAST(cardio_recovery__count_min AS FLOAT64) AS cardio_recovery_minutes,
            CAST(flights_climbed__count AS FLOAT64) AS flights_climbed,
            
            CAST(heart_rate_min__count_min AS FLOAT64) AS heart_rate_minimum_minutes,
            CAST(heart_rate_max__count_min AS FLOAT64) AS heart_rate_maximum_minutes,
            CAST(resting_heart_rate__count_min AS FLOAT64) AS heart_rate_resting_minutes,
            CAST(heart_rate_avg__count_min AS FLOAT64) AS heart_rate_average_minutes,
            CAST(heart_rate_variability__ms AS FLOAT64) AS heart_rate_variability_ms,
            CAST(resting_heart_rate__count_min AS FLOAT64) AS resting_heart_rate_minutes,
            
            CAST(`stair_speed:_down__ft_s` AS FLOAT64) AS stair_speed_down_ft_s,
            CAST(`stair_speed:_up__ft_s` AS FLOAT64) AS stair_speed_up_ft_s,
            CAST(step_count__count AS FLOAT64) AS step_count,
            CAST(time_in_daylight__min AS FLOAT64) AS time_in_daylight_min,
            CAST(vo2_max__ml__kg_min AS FLOAT64) AS vo2_max_ml_kg_min,
            CAST(`walking_+_running_distance__mi` AS FLOAT64) AS walking_plus_running_distance_mi,
            CAST(`walking_asymmetry_percentage__%` AS FLOAT64) AS walking_asymmetry_percentage_percent,
            CAST(`walking_double_support_percentage__%` AS FLOAT64) AS walking_double_support_percentage_percent,
            CAST(walking_heart_rate_average__count_min AS FLOAT64) AS walking_heart_rate_average_minutes,
            CAST(walking_speed__mi_hr AS FLOAT64) AS walking_speed_mi_hr,
            CAST(walking_step_length__in AS FLOAT64) AS walking_step_length_in,
            
            weight__lb AS `weight`,
            {{ parse_time_of_day("CAST(date_time AS TIMESTAMP)") }} AS time_of_day,
            _load_timestamp AS utc_loaded_at
        
        FROM {{ ref('base__health_metrics') }}
        
        -- NOTE: This indicates that I wasn't wearing my watch at the time
        WHERE active_energy__kcal IS NOT NULL
    ),

    agg AS (
        SELECT
            
            date_time,
            
            {% for col in target_columns %}
                SUM({{ col }}) AS {{ col }},
            {% endfor %}
        
        FROM base
        GROUP BY date_time
    ),

    joined AS (
        SELECT
            
            DATE(agg.date_time) AS measurement_date,
            agg.*,
            time_of_day,
            utc_loaded_at,
            LAST_VALUE(base.`weight` IGNORE NULLS) OVER (
                PARTITION BY DATE(agg.date_time)
                ORDER BY agg.date_time
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS `weight`,
            {{
                dbt_utils.generate_surrogate_key(
                    [
                        "date_time",
                        "time_of_day"
                    ]
                )
            }} AS surrogate_pk
            
        FROM agg
        LEFT JOIN base USING (date_time)
    )

SELECT * FROM joined
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY surrogate_pk 
    ORDER BY utc_loaded_at DESC
) = 1