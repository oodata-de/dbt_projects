{{ config(materialized='view') }}
-- INTERMEDIATE: product enrichment (placeholder for future attributes)
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.unit_price,
  p.in_stock
FROM {{ ref('prv_salesdb__products') }} p
