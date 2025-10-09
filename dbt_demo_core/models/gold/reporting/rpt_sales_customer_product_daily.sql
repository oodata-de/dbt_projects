{{ 
  config(
    materialized='view'
    ) 
}}

-- REPORTING: Sales daily aggregated by customer and product

WITH fact AS (
  SELECT * FROM {{ ref('f_sales_order_line') }}
),
d_c AS (
  SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    MASKED_EMAIL,
    COUNTRY
  FROM {{ ref('d_customer') }}
),
d_p AS (
  SELECT
    PRODUCT_SK,
    PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY
  FROM {{ ref('d_product') }}
),
d_d AS (
  SELECT
    DATE_KEY,
    DATE_VALUE
  FROM {{ ref('d_date') }}
)

SELECT
  f.DATE_KEY,
  d_d.DATE_VALUE AS DATE_VALUE,
  f.CUSTOMER_SK,
  d_c.MASKED_EMAIL,
  d_c.COUNTRY,
  f.PRODUCT_SK,
  d_p.PRODUCT_NAME,
  d_p.CATEGORY,
  SUM(f.QUANTITY) AS TOTAL_QTY,
  SUM(f.AMOUNT) AS TOTAL_AMOUNT,
  COUNT(DISTINCT f.ORDER_ID) AS DISTINCT_ORDERS
FROM fact f
LEFT JOIN d_c ON f.CUSTOMER_SK = d_c.CUSTOMER_SK
LEFT JOIN d_p ON f.PRODUCT_SK = d_p.PRODUCT_SK
LEFT JOIN d_d ON f.DATE_KEY = d_d.DATE_KEY
GROUP BY
  f.DATE_KEY,
  d_d.DATE_VALUE,
  f.CUSTOMER_SK,
  d_c.MASKED_EMAIL,
  d_c.COUNTRY,
  f.PRODUCT_SK,
  d_p.PRODUCT_NAME,
  d_p.CATEGORY
