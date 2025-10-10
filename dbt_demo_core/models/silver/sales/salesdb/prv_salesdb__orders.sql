{{ 
  config(
    tags=['sales']
  ) 
}}

SELECT
  order_id,
  customer_id,
  order_date,
  product_id,
  quantity,
  -- Convert any negative amounts to NULL and flag them
  CASE 
    WHEN amount < 0 THEN NULL 
    ELSE amount 
  END AS amount,
  CASE 
    WHEN amount < 0 THEN TRUE 
    ELSE FALSE 
  END AS is_invalid_amount
FROM {{ ref('stg_salesdb__orders') }}