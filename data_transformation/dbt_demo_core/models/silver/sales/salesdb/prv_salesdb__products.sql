{{ 
  config(
    tags=['inventory']
  ) 
}}

SELECT
    product_id,
    TRIM(product_name) AS product_name,
    TRIM(category) AS category,
    CASE WHEN unit_price < 0 THEN NULL ELSE unit_price END AS unit_price,
    in_stock
FROM {{ ref('stg_salesdb__products') }}