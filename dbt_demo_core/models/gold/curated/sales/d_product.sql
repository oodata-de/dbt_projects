{{ config(materialized='table') }}
-- DIMENSION: PRODUCT
SELECT 
  {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS PRODUCT_SK,
  product_id AS PRODUCT_ID,
  UPPER(product_name) AS PRODUCT_NAME,
  UPPER(category) AS CATEGORY,
  unit_price AS UNIT_PRICE,
  in_stock AS IN_STOCK_FLAG
FROM {{ ref('int_product_enriched') }}
