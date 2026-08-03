with source as (
  select * from {{ source('salesdb', 'products') }}
)

select * from source