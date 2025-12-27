SELECT

    {{
        dbt_utils.star(
            from=source("health", "food_diary_2026")
        )
    }}

FROM {{ source("health", "food_diary_2026") }}