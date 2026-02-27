SELECT
  
  fl.surrogate_line_item_pk,
  fl.food_line_item AS line_item,
  COUNT(*) AS n

FROM {{ ref("stg__01__health_metrics") }},
  UNNEST(food_line_items) AS fl
GROUP BY 1, 2