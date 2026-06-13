{{
    config(
        materialized='view',
        alias='health_summary'
    )
}}

SELECT
    
    *

FROM {{ ref("stg__01__health_metrics") }} 
ORDER BY target_date DESC, time_of_day