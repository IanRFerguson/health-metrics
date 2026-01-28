-- NOTE: In a refactor we might build these into staging or intermediate models
-- Not the best to do all of this logic in the analytical layer, but for now it's acceptable
WITH
    daily_stats AS (
        SELECT 
            
            EXTRACT(YEAR FROM target_date) AS year,
            EXTRACT(MONTH FROM target_date) AS month,

            -- Ring stats
            ROUND(SUM(total_active_energy_kcal) / COUNT(*), 3) AS avg_active_energy_kcal,
            ROUND(SUM(total_exercise_minutes) / COUNT(*), 3) AS avg_exercise_minutes,
            ROUND(SUM(total_stand_count) / COUNT(*), 3) AS avg_stand_count,
            ROUND(SUM(total_step_count) / COUNT(*), 3) AS avg_step_count,

            -- Weight
            MIN(max_weight_lb) AS min_weight_lb,
            ROUND(AVG(max_weight_lb), 3) AS avg_weight_lb,
            MAX(max_weight_lb) AS max_weight_lb
        
        FROM {{ ref("cln__metrics_per_day") }}
        GROUP BY 1,2
    ),

    weekly_stats AS (
        SELECT 
            EXTRACT(YEAR FROM start_date) AS year,
            EXTRACT(MONTH FROM start_date) AS month,
            
            -- Workout stats
            SUM(high_impact_workouts) AS high_impact_workouts,
            SUM(strength_workouts) AS strength_workouts,
            SUM(running_workouts) AS running_workouts,
            ROUND(SUM(total_miles_run), 3) AS total_miles_run,
            SUM(running_workouts) / NULLIF(COUNT(DISTINCT start_date), 0) AS avg_running_workouts_per_week,
            COUNTIF(running_goal_met) AS weeks_running_goal_met,
            COUNTIF(running_goal_met) / NULLIF(COUNT(DISTINCT start_date), 0) AS pct_weeks_running_goal_met,
        
        FROM {{ ref("cln__metrics_per_week") }}
        GROUP BY 1,2
    ),

    joined AS (
        SELECT 
            *
        FROM weekly_stats
        JOIN daily_stats USING (year, month)
        ORDER BY year, month
    )

SELECT 
    
    *,
    ROUND((
        avg_step_count - LAG(avg_step_count) OVER (ORDER BY year,month)) 
        / NULLIF(LAG(avg_step_count) OVER (ORDER BY year,month), 0
    ) * 100.0, 3) AS step_count_pct_change,
    
    ROUND((
        avg_weight_lb - LAG(avg_weight_lb) OVER (ORDER BY year,month)) 
        / NULLIF(LAG(avg_weight_lb) OVER (ORDER BY year,month), 0
    ) * 100.0, 3) AS weight_pct_change,
    
    -- Total weight loss since new years
    ROUND((avg_weight_lb - 220.2) / 220.2 * 100.0, 3) AS weight_loss_since_new_year_pct,

    ROUND((
        avg_running_workouts_per_week - LAG(avg_running_workouts_per_week) OVER (ORDER BY year,month)) 
        / NULLIF(LAG(avg_running_workouts_per_week) OVER (ORDER BY year,month), 0
    ) * 100.0, 3) AS runs_per_week_pct_change
    
FROM joined
ORDER BY year, month
