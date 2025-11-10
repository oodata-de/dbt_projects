--- Quick testing on incremental models from source to fact tables
-- microbatch does not require is_incremental filtering
{{ 
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        unique_key='customer_id',
        event_time='_el_timestamp',
        begin='1900-01-01',
        batch_size='day'            
    ) 
}}

with distinct_customer as (
    SELECT DISTINCT
        customer_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        LOWER(TRIM(email)) AS email,
        UPPER(TRIM(country)) AS country,
        created_date AS profile_created_date
    FROM {{ source('salesdb', 'customers') }} c
)

SELECT {{ increment_sequence() }} as customer_sid, 
    customer_id, 
    first_name, 
    last_name, 
    email,
    country,
    profile_created_date,
    {{ dbt_utils.generate_surrogate_key([
            'first_name', 'last_name', 'email', 'country', 'profile_created_date'])
    }} as _sha256_val,
    current_timestamp() AS _process_timestamp
FROM distinct_customer

{% if is_incremental() %}
where _el_timestamp >= (select coalesce(max(_process_timestamp), '1900-01-01') from {{ this }})
{% endif %}

