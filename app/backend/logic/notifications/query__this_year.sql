select * from `health_metrics_marts.metrics_per_week`
where not _is_current_week
  and extract(year from start_date) = extract(year from current_date())
