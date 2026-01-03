SELECT

    {{
        dbt_utils.star(
            from=source("health", "apple_workouts")
        )
    }}

FROM {{ source("health", "apple_workouts") }}