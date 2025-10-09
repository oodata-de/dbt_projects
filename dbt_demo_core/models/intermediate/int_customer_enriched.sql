{{ config(materialized='view') }}
-- INTERMEDIATE: customer enrichment
-- Adds first order date, new customer flag, masked email.

WITH customers AS (
    SELECT * FROM {{ ref('prv_salesdb__customers') }}
),
orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM {{ ref('prv_salesdb__orders') }}
    GROUP BY 1
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email AS raw_email,
    -- Mask: first char + *** + domain
    CONCAT(LEFT(c.email,1),'***@',SPLIT_PART(c.email,'@',2)) AS masked_email,
    c.country,
    c.created_date,
    o.first_order_date,
    CASE WHEN o.first_order_date IS NULL THEN 1 ELSE 0 END AS IS_NEW_FLAG
FROM customers c
LEFT JOIN orders o USING (customer_id)
