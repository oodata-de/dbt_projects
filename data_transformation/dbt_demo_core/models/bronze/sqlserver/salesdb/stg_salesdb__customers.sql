-- source function allows you to reference a table or view that has not been created by dbt

with source as (
  select * from {{ source('salesdb', 'customers') }}
)

select * from source