{% macro audit_columns(column_list) %}
    {{ dbt_utils.generate_surrogate_key(column_list) }} as _sha256_val,
    '{{ run_started_at }}' as _process_date_utc,
    '{{ invocation_id }}' as _dbt_invocation_id
{% endmacro %}