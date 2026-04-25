with
  date_bookends as (
    select
      start_date,
      date_add(start_date, INTERVAL 6 DAY) AS end_date
    from `dbt_health_metrics_analytics.metrics_per_week`
    where not _is_current_week
    order by start_date desc
    limit 1
  )

select
  target_date,
  total_active_energy_kcal,
  total_step_count,
  max_weight_lb,
  all_daily_workouts,
  scored_food_line_items
from dbt_health_metrics_analytics.metrics_per_day
where target_date between (select start_date from date_bookends) and (select end_date from date_bookends)
order by target_date
