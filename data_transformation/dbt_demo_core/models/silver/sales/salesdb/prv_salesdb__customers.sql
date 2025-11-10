{{ 
  config(
    tags = ['sales']
  ) 
}}

SELECT
  customer_id,
  TRIM(first_name) AS first_name,
  TRIM(last_name) AS last_name,
  LOWER(TRIM(email)) AS email,
  UPPER(TRIM(country)) AS country,
  created_date
FROM {{ ref('stg_salesdb__customers') }}