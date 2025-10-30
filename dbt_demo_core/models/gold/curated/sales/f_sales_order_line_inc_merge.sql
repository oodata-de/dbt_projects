{{ config(
  materialized='incremental',
  unique_key='ORDER_LINE_ID',
  incremental_strategy='merge',
  merge_exclude_columns = ['product_sid']
) }}

-- FACT: SALES ORDER LINE
-- 7-day overlap incremental window to capture late-arriving changes.
WITH base AS (
  SELECT
    order_id,
    customer_id,
    order_date,
    product_id,
    quantity,
    -- Convert any negative amounts to NULL and flag them
    CASE WHEN amount < 0 THEN NULL ELSE amount END AS amount,
    CASE WHEN amount < 0 THEN TRUE ELSE FALSE END AS is_invalid_amount
  FROM {{ source('salesdb', 'orders') }}
  -- only process new or changed records on orders tables based on _el_timestamp
  {% if is_incremental() %}
  WHERE _el_timestamp >= (select coalesce(max(_process_timestamp), '1900-01-01') from {{ this }})
  {% endif %} 
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
    CASE WHEN quantity IS NULL THEN NULL ELSE CEIL(quantity / 2.0) END AS line_quantity,
    CASE WHEN amount IS NULL THEN NULL ELSE ROUND(amount / 2.0, 2) END AS line_amount
  FROM expanded
),

src AS (
  SELECT
    CONCAT(order_id, '-', line_seq) AS order_line_id,
    order_id,
    customer_id,
    order_date,
    product_id,
    line_quantity AS quantity,
    line_amount AS amount
  FROM adjusted
)

SELECT
  TO_NUMBER(TO_CHAR(order_date, 'YYYYMMDD')) AS order_date_id,
  order_line_id AS ORDER_LINE_ID,
  order_id AS ORDER_ID,
  nvl(p.product_sid, -1) AS PRODUCT_SID,
  nvl(c.customer_sid, -1) AS CUSTOMER_SID,
  order_date AS ORDER_DATE,
  quantity AS QUANTITY,
  amount AS AMOUNT,
  CASE WHEN amount IS NOT NULL AND quantity > 0 THEN ROUND(amount / NULLIF(quantity, 0), 2) ELSE NULL END AS UNIT_PRICE,
  current_timestamp() AS _process_timestamp
FROM src
-- no filtering for dimension jobs, we want to get the sid irrespective of whe the dim records was created
-- will change for type 2 to identify the right SID based on effective date
LEFT JOIN {{ ref('d_product_inc_merge') }} p ON src.product_id = p.product_id
LEFT JOIN {{ ref('d_customer_inc_merge') }} c ON src.customer_id = c.customer_id
