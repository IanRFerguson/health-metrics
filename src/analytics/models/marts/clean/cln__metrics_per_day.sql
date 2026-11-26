{{
    config(
        alias="metrics_per_day"
    )
}}

SELECT

    {{
        dbt_utils.star(
            from=ref("stg__03__metrics_per_day")
        )
    }}

FROM {{ ref("stg__03__metrics_per_day") }}
