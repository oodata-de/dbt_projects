with source as (
  select * from {{ source('invdb', 'inventory_transactions') }}
)

select * from source

