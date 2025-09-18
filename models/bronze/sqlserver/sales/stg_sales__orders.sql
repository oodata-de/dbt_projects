with source as (
  select * from {{ source('src_sales', 'orders') }}
)

select * from source