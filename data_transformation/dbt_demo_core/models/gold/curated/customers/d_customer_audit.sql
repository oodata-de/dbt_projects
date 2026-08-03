/*
{{ 
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_id',
    ) 
}}


SELECT {{ increment_sequence() }} as customer_sid, 
   *
FROM {{ ref('audit_d_customer') }}

        -- Optionally: exclude customer_sid from being updated (Snowflake + dbt >=1.5)
        -- , merge_update_columns = ['col1','col2', ...]  -- omit customer_sid here

WITH src AS (
    SELECT *
    FROM {{ ref('audit_d_customer') }}
)

{% if is_incremental() %}
, existing AS (
    SELECT customer_id, customer_sid
    FROM {{ this }}
)
SELECT
    COALESCE(existing.customer_sid, {{ increment_sequence() }}) AS customer_sid,
    src.*
FROM src
LEFT JOIN existing
    ON src.customer_id = existing.customer_id
{% else %}
SELECT
    {{ increment_sequence() }} AS customer_sid,
    src.*
FROM src
{% endif %}
*/

{{ 
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_id',
        merge_exclude_columns = ['customer_sid']
    ) 
}}

SELECT {{ increment_sequence() }} as customer_sid, 
   *
FROM {{ ref('audit_d_customer') }}