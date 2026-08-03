--- Quick testing on incremental models from source to fact tables
{{ 
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_id',
        merge_exclude_columns = ['customer_sid'],
        pre_hook = "{{ set_run_window_variables() }}",
        post_hook = "{{ update_execution_logs() }}"
    ) 
}}

-- default_records as (
--     SELECT 0 as customer_sid, -10 as customer_id, 'UNKNOWN' as first_name, 'UNKNOWN' as last_name, 'UNKNOWN' as email, 'UNKNOWN' as country, TO_DATE('1900-01-01') as profile_created_date
--     UNION ALL SELECT 1, -10 , 'NOT APPLICABLE', 'NOT APPLICABLE' , 'NOT APPLICABLE', 'NOT APPLICABLE', TO_DATE('1900-01-01') 
--     UNION ALL SELECT 2, -10 , 'ALL', 'ALL', 'ALL', 'ALL', TO_DATE('1900-01-01') 
-- ),

with 
default_records as (
    {{ default_dimension_records(
        {
            'customer_sid': 'int',
            'customer_id': 'int',
            'first_name': 'string',
            'last_name': 'string',
            'email': 'string',
            'country': 'string',
            'profile_created_date': 'date'
        },
        'customer_sid'
    ) }}
),

static_data as (
    SELECT * FROM default_records
    {% if is_incremental() %}
        WHERE false
    {% endif %}
),

distinct_customer as (
    SELECT DISTINCT
        customer_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        LOWER(TRIM(email)) AS email,
        UPPER(TRIM(country)) AS country,
        created_date AS profile_created_date
    FROM {{ source('salesdb', 'customers') }} c
    {% if is_incremental() %}
        -- where _el_timestamp >= (select coalesce(max(_process_timestamp), '1900-01-01') from {{ this }})
        where _el_timestamp between $run_start_ts and $run_end_ts
    {% endif %}
),

final as (
    SELECT * from static_data
    UNION ALL
    SELECT {{ increment_sequence() }} as customer_sid, * from distinct_customer
)

SELECT *,
    {{ dbt_utils.generate_surrogate_key([
            'first_name', 'last_name', 'email', 'country', 'profile_created_date'])
    }} as _sha256_val,
    current_timestamp() AS _process_timestamp,
    '{{ invocation_id }}' AS _dbt_invocation_id 
FROM final


