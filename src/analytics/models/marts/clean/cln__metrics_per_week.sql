{{
    config(
        alias="metrics_per_week"
    )
}}

SELECT

    {{
        dbt_utils.star(
            from=ref("stg__02__metrics_per_week")
        )
    }}

FROM {{ ref("stg__02__metrics_per_week") }}