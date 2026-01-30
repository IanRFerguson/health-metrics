{{
    config(
        alias="metrics_per_month"
    )
}}

SELECT

    {{
        dbt_utils.star(
            from=ref("stg__02__metrics_per_month")
        )
    }}

FROM {{ ref("stg__02__metrics_per_month") }}