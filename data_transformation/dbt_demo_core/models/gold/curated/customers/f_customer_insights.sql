{{ 
    config(
        tags=['sales']
    ) 
}}

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.amount) as total_spent,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    ROUND(SUM(o.amount) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) as avg_order_value
FROM {{ ref('d_customer') }} c
LEFT JOIN {{ ref('f_sales_order_line') }} o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country