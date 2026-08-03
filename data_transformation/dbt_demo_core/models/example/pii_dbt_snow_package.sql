{{ config(
    materialized='table',
    post_hook = "{{ dbt_snow_mask.apply_masking_policy('models') }}"
    ) 
}}

with source_data as (

    select * from {{ source('example', 'customer') }}

)

select *, 
{{ dbt.current_timestamp() }} as tfw_created_at
from source_data