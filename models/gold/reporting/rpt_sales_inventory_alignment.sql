{{ 
  config(
    materialized='view'
  ) 
}}

-- REPORTING: Align sales vs inventory snapshot
WITH sales AS (
  SELECT PRODUCT_SK, DATE_KEY, SUM(QUANTITY) AS SALES_QTY
  FROM {{ ref('f_sales_order_line') }}
  GROUP BY 1,2
), 

inv AS (
  SELECT PRODUCT_SK, DATE_KEY, SUM(QUANTITY_ON_HAND) AS TOTAL_STOCK
  FROM {{ ref('f_inventory_daily_snapshot') }}
  GROUP BY 1,2
), 

d AS (
  SELECT DATE_KEY, DATE_VALUE FROM {{ ref('d_date') }}
)

SELECT
  d.DATE_VALUE,
  s.PRODUCT_SK,
  s.SALES_QTY,
  i.TOTAL_STOCK,
  (i.TOTAL_STOCK - s.SALES_QTY) AS STOCK_DELTA
FROM sales s
LEFT JOIN inv i ON s.PRODUCT_SK = i.PRODUCT_SK AND s.DATE_KEY = i.DATE_KEY
LEFT JOIN d ON s.DATE_KEY = d.DATE_KEY
