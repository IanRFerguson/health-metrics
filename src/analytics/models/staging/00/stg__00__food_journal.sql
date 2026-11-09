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
    ),

    backfilled AS (
        SELECT

            id,
            target_date,
            target_time_of_day,
            food_item,
            added_at

        FROM {{ source("health", "food_diary_backfill") }}
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY id ORDER BY added_at DESC
        ) = 1
    ),

    cleaned AS (
        SELECT 

            DATE(est_loaded_at) AS load_date,
            message_unique_id,
            est_loaded_at,
            {{ parse_time_of_day("est_loaded_at") }} AS time_of_day,
            UPPER(TRIM(food_line_item)) AS food_line_item,
            {{
                dbt_utils.generate_surrogate_key(
                    [
                        "message_unique_id",
                        "food_line_item"
                    ]
                )
            }} AS surrogate_pk,
            false AS is_backfilled
            
        FROM parsed
        WHERE DATE(est_loaded_at) >= '2025-12-01'
        UNION ALL
        SELECT
            DATE(target_date) AS load_date,
            id AS message_unique_id,
            added_at AS est_loaded_at,
            target_time_of_day AS time_of_day,
            UPPER(TRIM(food_item)) AS food_line_item,
            {{
                dbt_utils.generate_surrogate_key(
                    [
                        "id",
                        "food_item"
                    ]
                )
            }} AS surrogate_pk,
            true AS is_backfilled
        FROM backfilled
    )

SELECT * FROM cleaned
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY surrogate_pk 
    ORDER BY est_loaded_at DESC
) = 1