{{ 
  config(
    tags=['inventory']
  ) 
}}

SELECT
    transaction_id,
    product_id,
    UPPER(TRIM(transaction_type)) AS transaction_type,
    quantity,
    transaction_date,
    UPPER(TRIM(warehouse_location)) AS warehouse_location
FROM {{ ref('stg_invdb__inventory_transactions') }}
WHERE transaction_type IN ('RECEIPT', 'SHIPMENT') 

