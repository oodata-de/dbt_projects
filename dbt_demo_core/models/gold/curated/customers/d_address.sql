{{ config(materialized='table') }}
-- DIMENSION: ADDRESS
SELECT
  {{ dbt_utils.generate_surrogate_key(['customer_id','address_id']) }} AS ADDRESS_SK,
  customer_id AS CUSTOMER_ID,
  address_id AS ADDRESS_ID,
  address_line1 AS ADDRESS_LINE1,
  city AS CITY,
  state AS STATE,
  postal_code AS POSTAL_CODE,
  country AS COUNTRY,
  address_type AS ADDRESS_TYPE
FROM {{ ref('int_address_enriched') }}
