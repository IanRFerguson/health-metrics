WITH
    food_ratings AS (
        SELECT * FROM {{ ref("stg__00__food_journal")}}
    ),

    gemini_input AS (
        SELECT 
            *,
            CONCAT(
                "Rate the healthiness of this food item: '", food_line_item, 
                "'. Return ONLY a numeric value between 0.0 (unhealthy) and 10.0 (healthy)."
            ) AS prompt
        FROM food_ratings
    )

SELECT
    *,
    -- Correctly navigate the nested JSON structure: candidates -> content -> parts -> text
    SAFE_CAST(
        JSON_VALUE(
            ml_generate_text_result, 
            '$.candidates[0].content.parts[0].text'
        ) 
        AS FLOAT64
    ) AS health_rating
FROM
    ML.GENERATE_TEXT(
        MODEL `ian-is-online.health.gemini_model`,
        (SELECT prompt FROM gemini_input),
        STRUCT(0.1 AS temperature)
    )