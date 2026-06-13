{{
    config(
        alias="workouts_aggregated"
    )
}}

SELECT

    {{
        dbt_utils.star(
            ref("stg__02__workouts_aggregated")
        )
    }}

FROM {{ ref("stg__02__workouts_aggregated")}}