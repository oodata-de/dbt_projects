{{ config(materialized='view') }}
-- INTERMEDIATE: clean addresses from seed
SELECT
  CAST(CUSTOMER_ID AS INTEGER) AS customer_id,
  CAST(ADDRESS_ID AS INTEGER) AS address_id,
  UPPER(ADDRESS_LINE1) AS address_line1,
  UPPER(CITY) AS city,
  UPPER(STATE) AS state,
  POSTAL_CODE,
  UPPER(COUNTRY) AS country,
  UPPER(ADDRESS_TYPE) AS address_type
FROM {{ ref('prv_salesdb__addresses') }}
