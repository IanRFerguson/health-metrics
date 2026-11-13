{{
    config(
        alias="metrics_by_dow"
    )
}}

SELECT
    {{
        dbt_utils.star(
            from=ref("stg__02__metrics_by_dow")
        )
    }}
FROM {{ ref("stg__02__metrics_by_dow") }}
ORDER BY dow_num
