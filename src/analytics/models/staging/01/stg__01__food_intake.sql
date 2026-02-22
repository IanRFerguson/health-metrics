SELECT
  {{
    dbt_utils.generate_surrogate_key(
      [
        "fl"
      ]
    )
  }} AS surrogate_line_item_pk,
  fl AS line_item,
  COUNT(*) AS n
FROM {{ ref("stg__01__health_metrics") }},
  UNNEST(food_line_items) AS fl
GROUP BY 1, 2