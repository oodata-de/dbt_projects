{{ config(
    materialized='table',
    post_hook = "{{ temp_test() }}"
)
}}


select
    '{{ this }}' as full_path,
    '{{ this.schema }}' as schema_name,
    '{{ this.database }}' as db_name,
    '{{ this.table }}' as table_name,
    '{{ this.identifier }}' as identifier,
    '{{ this.type }}' as relation_type,
    current_timestamp() as run_ts

/*
post_hook=[
    "CREATE OR REPLACE TABLE dbt_dev.sch_dbt_test.post_hook_table AS 
    SELECT 1 AS id;"
]

post_hook=log_post_hook('{{ this }} ')

post_hook = "{{ temp_test() }}"

post_hook=[
    "select
        CASE t.table_type
            WHEN 'BASE TABLE' THEN 'TABLE'
            ELSE t.table_type
        END AS table_type
        from dbt_dev.information_schema.tables t
        where table_name = 'POST_HOOK_TABLE'
    limit 1;"
]
*/