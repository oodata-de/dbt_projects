{% macro audit_columns_sha(column_list) %}

    coalesce(__late_arriving_flag, 0) as __late_arriving_flag,
    coalesce(__effective_start_datetime, current_timestamp) as __effective_start_datetime, 
    coalesce(__effective_end_datetime, to_timestamp('9999-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')) as __effective_end_datetime, 
    coalesce(__current_flag, 1) as __current_flag,
    coalesce(__deleted_flag, 0) as __deleted_flag,
    {{ sha256_hashing(column_list) }} as __business_key_hash, 
    {{ sha256_hashing(column_list) }} as __business_col_hash,
    coalesce(__create_datetime_utc, '{{ run_started_at }}') as __create_datetime_utc, 
    '{{ run_started_at }}' as __update_datetime_utc,
    '{{ invocation_id }}' as __dbt_invocation_id

{% endmacro %}