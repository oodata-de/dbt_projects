{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    exclude_from_incremental=['tfw_created_at']

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