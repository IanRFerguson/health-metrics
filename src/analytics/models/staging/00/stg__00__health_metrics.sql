WITH
    base AS (
        SELECT
        
            date_time,
            active_energy__kcal AS active_energy_kcal,
            physical_effort__kcal_hr_kg AS physical_effort_kcal_hr_kg,
            resting_energy__kcal AS resting_energy_kcal,
            
            apple_exercise_time__min AS exercise_minutes,
            apple_stand_hour__count AS stand_count,
            apple_stand_time__min AS stand_minutes,
            `blood_oxygen_saturation__%` AS blood_oxygen_saturation_percent,
            cardio_recovery__count_min AS cardio_recovery_minutes,
            flights_climbed__count AS flights_climbed,
            
            heart_rate_min__count_min AS heart_rate_minimum_minutes,
            heart_rate_max__count_min AS heart_rate_maximum_minutes,
            resting_heart_rate__count_min AS heart_rate_resting_minutes,
            heart_rate_avg__count_min AS heart_rate_average_minutes,
            heart_rate_variability__ms AS heart_rate_variability_ms,
            resting_heart_rate__count_min AS resting_heart_rate_minutes,
            
            `stair_speed:_down__ft_s` AS stair_speed_down_ft_s,
            `stair_speed:_up__ft_s` AS stair_speed_up_ft_s,
            step_count__count AS step_count,
            time_in_daylight__min AS time_in_daylight_min,
            vo2_max__ml__kg_min AS vo2_max_ml_kg_min,
            `walking_+_running_distance__mi` AS walking_plus_running_distance_mi,
            `walking_asymmetry_percentage__%` AS walking_asymmetry_percentage_percent,
            `walking_double_support_percentage__%` AS walking_double_support_percentage_percent,
            walking_heart_rate_average__count_min AS walking_heart_rate_average_minutes,
            walking_speed__mi_hr AS walking_speed_mi_hr,
            walking_step_length__in AS walking_step_length_in,
            
            weight__lb AS `weight`,
            {{ parse_time_of_day("CAST(date_time AS TIMESTAMP)") }} AS time_of_day,
            _load_timestamp AS utc_loaded_at
        
        FROM {{ ref('base__health_metrics') }}
        
        -- NOTE: This indicates that I wasn't wearing my watch at the time
        WHERE active_energy__kcal IS NOT NULL
    )

SELECT 
    
    DATE(base.date_time) AS measurement_date,
    base.*
    
FROM base