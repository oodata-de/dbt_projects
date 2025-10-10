with source as (
  select * from {{ source('salesdb', 'addresses') }}
)

select * from source