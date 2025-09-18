with source as (
  select * from {{ source('src_sales', 'products') }}
)

select * from source