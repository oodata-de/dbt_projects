with source as (
  select * from {{ source('salesdb', 'orders') }}
)

select * from source