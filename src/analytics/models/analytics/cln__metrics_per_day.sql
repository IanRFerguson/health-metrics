{{
    config(
        alias="metrics_per_day"
    )
}}

SELECT

    {{
        dbt_utils.star(
            from=ref("stg__02__metrics_per_day")
        )
    }}

FROM {{ ref("stg__02__metrics_per_day") }}