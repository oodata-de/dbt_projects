{{ config(
    materialized='view'
)
}}


with 

default_records AS (
    {{ default_dim(
        sid_col='table_sid',
        cols_type={
            "full_path": '',
            "schema_name": '',
            "db_name": '',
            "table_name": '',
            "identifier": 'null',
            "relation_type": '',
            "run_ts": ''
        }
    ) }}
)

select * from default_records
