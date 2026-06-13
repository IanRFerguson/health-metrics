{{
    config(
        alias="workouts"
    )
}}

SELECT

    {{
        dbt_utils.star(
            ref("stg__02__workouts")
        )
    }}

FROM {{ ref("stg__02__workouts")}}