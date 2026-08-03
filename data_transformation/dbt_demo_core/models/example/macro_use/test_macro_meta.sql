{{ config(
    materialized='table'
)
}}


{% set test = meta_use() %}
{{ log("column mapping in model: " ~ test, info=true) }}

select
    '{{ this }}' as full_path,
    '{{ this.schema }}' as schema_name,
    '{{ this.database }}' as db_name,
    '{{ this.table }}' as table_name,
    '{{ this.identifier }}' as identifier,
    '{{ this.type }}' as relation_type,
    current_timestamp() as run_ts
