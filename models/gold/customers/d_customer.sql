{{ 
    config(
        tags=['sales']
    ) 
}}

SELECT DISTINCT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country
FROM {{ ref('prv_sales__customers') }} c