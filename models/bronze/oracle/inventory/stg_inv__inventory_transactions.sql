with source as (
  select * from {{ source('src_inventory', 'inventory_transactions') }}
)

select * from source

