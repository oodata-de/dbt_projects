{{ config(materialized='view') }}
-- INTERMEDIATE: aggregate inventory transactions to daily product-location
WITH tx AS (
  SELECT
    product_id,
    warehouse_location,
    transaction_date::date AS txn_date,
    SUM(CASE WHEN transaction_type='RECEIPT' THEN quantity ELSE 0 END) AS receipts_qty,
    SUM(CASE WHEN transaction_type='SHIPMENT' THEN ABS(quantity) ELSE 0 END) AS shipments_qty
  FROM {{ ref('prv_invdb__inventory_transactions') }}
  GROUP BY 1,2,3
), levels AS (
  SELECT
    product_id,
    warehouse_location,
    last_updated_at::date AS lvl_date,
    quantity_on_hand
  FROM {{ ref('prv_invdb__inventory_levels') }}
)
SELECT
  COALESCE(tx.product_id, levels.product_id) AS product_id,
  COALESCE(tx.warehouse_location, levels.warehouse_location) AS warehouse_location,
  COALESCE(tx.txn_date, levels.lvl_date) AS snapshot_date,
  receipts_qty,
  shipments_qty,
  quantity_on_hand
FROM tx
FULL OUTER JOIN levels
  ON tx.product_id = levels.product_id
 AND tx.warehouse_location = levels.warehouse_location
 AND tx.txn_date = levels.lvl_date
