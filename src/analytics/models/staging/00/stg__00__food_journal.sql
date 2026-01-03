WITH
    base AS (
        SELECT

            _load_timestamp AS utc_loaded_at,
            Body AS message_body,
            MessageSid AS message_unique_id

        FROM {{ ref('base__food_journal') }}
        WHERE _load_timestamp IS NOT NULL
    ),

    parsed AS (
        SELECT

            base.message_unique_id,
            base.utc_loaded_at,
            DATETIME(base.utc_loaded_at, 'America/New_York') AS est_loaded_at,
            food_line_item

        FROM base
        CROSS JOIN UNNEST(SPLIT(base.message_body, '*')) AS food_line_item
        WHERE food_line_item IS NOT NULL
            AND TRIM(food_line_item) != ''
    )

SELECT 

    DATE(est_loaded_at) AS load_date,
    message_unique_id,
    est_loaded_at,
    {{ parse_time_of_day("est_loaded_at") }} AS time_of_day,
    UPPER(TRIM(food_line_item)) AS food_line_item
    
FROM parsed
WHERE DATE(est_loaded_at) >= '2025-12-01'