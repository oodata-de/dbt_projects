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
    --WHERE process_date = (SELECT MAX(process_date) FROM {{ this }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY c.first_name DESC) = 1
)

SELECT 
    customer_id, 
    first_name, 
    last_name, 
    country
FROM distinct_customer