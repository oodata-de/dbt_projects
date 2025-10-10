{{ 
  config(
    tags=['inventory']
  ) 
}}

SELECT
    inventory_id,
    product_id,
    UPPER(TRIM(warehouse_location)) AS warehouse_location,
    CASE WHEN quantity_on_hand < 0 THEN 0 ELSE quantity_on_hand END AS quantity_on_hand,
    last_updated_at,
    minimum_stock_level,
    maximum_stock_level
FROM {{ ref('stg_invdb__inventory_levels') }}
