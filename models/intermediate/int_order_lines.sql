{{ config(materialized='view') }}
-- INTERMEDIATE: simulate order line explosion from order header (if header-level only)
-- Approach: duplicate each order row into 2 pseudo-lines splitting quantity & amount.
WITH 
base AS (
  SELECT * FROM {{ ref('prv_salesdb__orders') }}
), 

expanded AS (
  SELECT *, 1 AS line_seq FROM base
  UNION ALL
  SELECT *, 2 AS line_seq FROM base
), 

adjusted AS (
  SELECT
    order_id,
    customer_id,
    order_date,
    product_id,
    line_seq,
    -- Split quantity roughly equally
    CASE WHEN quantity IS NULL THEN NULL ELSE CEIL(quantity/2.0) END AS line_quantity,
    CASE WHEN amount IS NULL THEN NULL ELSE ROUND(amount/2.0,2) END AS line_amount
  FROM expanded
)

SELECT
  CONCAT(order_id,'-',line_seq) AS order_line_id,
  order_id,
  customer_id,
  order_date,
  product_id,
  line_quantity AS quantity,
  line_amount  AS amount
FROM adjusted
