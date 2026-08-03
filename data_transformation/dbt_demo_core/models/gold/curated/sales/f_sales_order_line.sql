{{ config(
    materialized='incremental',
    unique_key='ORDER_LINE_ID',
    incremental_strategy='merge'
) }}
-- FACT: SALES ORDER LINE
-- 7-day overlap incremental window to capture late-arriving changes.
WITH 
src AS (
  SELECT * FROM {{ ref('int_order_lines') }}
), 

dims AS (
  SELECT 
    s.order_line_id,
    s.order_id,
    s.customer_id,
    s.product_id,
    s.order_date,
    s.quantity,
    s.amount
  FROM src s
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['order_line_id']) }} AS ORDER_LINE_SK,
  {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS CUSTOMER_SK,
  {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS PRODUCT_SK,
  TO_NUMBER(TO_CHAR(order_date,'YYYYMMDD')) AS DATE_KEY,
  order_line_id AS ORDER_LINE_ID,
  order_id AS ORDER_ID,
  product_id AS PRODUCT_ID,
  customer_id AS CUSTOMER_ID,
  order_date AS ORDER_DATE,
  quantity AS QUANTITY,
  amount AS AMOUNT,
  CASE WHEN amount IS NOT NULL AND quantity > 0 THEN ROUND(amount/NULLIF(quantity,0),2) ELSE NULL END AS UNIT_PRICE
FROM dims
{% if is_incremental() %}
WHERE order_date >= DATEADD(day,-7,(SELECT MAX(order_date) FROM {{ this }}))
{% endif %}
