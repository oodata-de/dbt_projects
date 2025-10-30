{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    post_hook = "{{ dbt_snow_mask.apply_masking_policy('models') }}"

    ) 
}}

with source_data as (

    select * from {{ source('example', 'customer') }}

)

select *, 
{{ dbt.current_timestamp() }} as tfw_created_at
from source_data

{% if is_incremental() %}
where created_at > (select coalesce(max(created_at), '1990-01-01') from {{ this }})
{% endif %}