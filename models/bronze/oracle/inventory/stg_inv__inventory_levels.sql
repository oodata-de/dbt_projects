with source as (
  select * from {{ source('src_inventory', 'inventory_levels') }}
)

select * from source
