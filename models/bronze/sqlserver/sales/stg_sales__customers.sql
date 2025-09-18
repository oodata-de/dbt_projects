with source as (
  select * from {{ source('src_sales', 'customers') }}
)

select * from source