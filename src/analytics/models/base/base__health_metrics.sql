SELECT

    {{
        dbt_utils.star(
            from=source("health", "apple_health_metrics")
        )
    }}

FROM {{ source("health", "apple_health_metrics") }}