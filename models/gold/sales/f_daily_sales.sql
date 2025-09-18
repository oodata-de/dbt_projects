{{ 
    config(
        tags=['sales']
    ) 
}}

SELECT
    order_date,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS total_items_sold,
    SUM(amount) AS total_revenue
FROM {{ ref('f_sales_orders') }}
GROUP BY order_date