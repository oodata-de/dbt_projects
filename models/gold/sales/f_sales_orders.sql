{{ 
    config(
        tags=['sales']
    ) 
}}

SELECT
    *
FROM {{ ref('prv_sales__orders') }}