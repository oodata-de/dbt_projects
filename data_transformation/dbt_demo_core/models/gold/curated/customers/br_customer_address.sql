{{ config(materialized='table') }}
-- BRIDGE: CUSTOMER to ADDRESS (many-to-many resolution)
WITH base AS (
  SELECT c.CUSTOMER_SK, a.ADDRESS_SK, a.ADDRESS_TYPE
  FROM {{ ref('d_customer') }} c
  JOIN {{ ref('d_address') }} a ON c.CUSTOMER_ID = a.CUSTOMER_ID
), 

stats AS (
  SELECT CUSTOMER_SK, ADDRESS_SK,
    MIN(ADDRESS_TYPE) AS ANY_ADDRESS_TYPE,
    COUNT(*) AS LINK_COUNT
  FROM base
  GROUP BY 1,2
)
SELECT * FROM stats
