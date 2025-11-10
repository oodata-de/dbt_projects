{{ 
    config(
        tags=['inventory']
    ) 
}}

SELECT
    il.product_id,
    p.product_name,
    il.warehouse_location,
    il.quantity_on_hand,
    il.minimum_stock_level,
    il.maximum_stock_level,
    SUM(CASE 
        WHEN it.transaction_type = 'RECEIPT' THEN it.quantity
        ELSE 0 
    END) AS total_receipts,
    SUM(CASE 
        WHEN it.transaction_type = 'SHIPMENT' THEN ABS(it.quantity)
        ELSE 0 
    END) AS total_shipments
FROM {{ ref('prv_invdb__inventory_levels') }} il
LEFT JOIN {{ ref('prv_salesdb__products') }} p ON il.product_id = p.product_id
LEFT JOIN {{ ref('prv_invdb__inventory_transactions') }} it ON il.product_id = it.product_id 
    AND il.warehouse_location = it.warehouse_location
GROUP BY 
    il.product_id,
    p.product_name,
    il.warehouse_location,
    il.quantity_on_hand,
    il.minimum_stock_level,
    il.maximum_stock_level