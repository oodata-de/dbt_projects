{{ 
    config(
        tags=['sales']
    ) 
}}

with distinct_customer as (
    SELECT DISTINCT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country
    FROM {{ ref('prv_salesdb__customers') }} c
)

SELECT {{ increment_sequence() }} as customer_sid, 
    customer_id, 
    first_name, 
    last_name, 
    country
FROM distinct_customer

/*
{{ config(materialized='table') }}
-- DIMENSION: CUSTOMER with masked email
SELECT 
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS CUSTOMER_SK,
    customer_id AS CUSTOMER_ID,
    UPPER(first_name) AS FIRST_NAME,
    UPPER(last_name) AS LAST_NAME,
    masked_email AS MASKED_EMAIL,
    country AS COUNTRY,
    created_date AS CREATED_DATE,
    first_order_date AS FIRST_ORDER_DATE,
    IS_NEW_FLAG AS IS_NEW_FLAG
FROM {{ ref('int_customer_enriched') }}
*/  