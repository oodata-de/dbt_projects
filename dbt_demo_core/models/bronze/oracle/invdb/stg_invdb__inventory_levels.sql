with source as (
  select * from {{ source('invdb', 'inventory_levels') }}
)

select * from source
