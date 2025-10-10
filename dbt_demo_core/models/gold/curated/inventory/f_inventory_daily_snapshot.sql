{{ config(
    materialized='incremental',
    unique_key=['PRODUCT_SK','DATE_KEY','LOCATION_SK'],
    incremental_strategy='merge'
) }}
-- FACT: INVENTORY DAILY SNAPSHOT
WITH src AS (
  SELECT * FROM {{ ref('int_inventory_daily') }}
), final AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS PRODUCT_SK,
    {{ dbt_utils.generate_surrogate_key(['warehouse_location']) }} AS LOCATION_SK,
    TO_NUMBER(TO_CHAR(snapshot_date,'YYYYMMDD')) AS DATE_KEY,
    snapshot_date AS SNAPSHOT_DATE,
    receipts_qty AS RECEIPTS_QTY,
    shipments_qty AS SHIPMENTS_QTY,
    quantity_on_hand AS QUANTITY_ON_HAND
  FROM src
)
SELECT * FROM final
{% if is_incremental() %}
WHERE SNAPSHOT_DATE >= DATEADD(day,-7,(SELECT MAX(SNAPSHOT_DATE) FROM {{ this }}))
{% endif %}
