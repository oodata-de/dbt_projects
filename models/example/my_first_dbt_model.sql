
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Options for config
    -- table_tag = "my_tag_name = 'my_tag_value'" -- tag must already exist in Snowflake before you apply it
    -- row_access_policy = 'my_database.my_schema.my_row_access_policy_name on (id)'
    -- tmp_relation_type="table | view", ## If not defined, view is the default.
*/

{{ config(
    materialized='table',
    transient=false,
    cluster_by=['id'],

    ) 
}}

with source_data as (

    select 1 as id
    union all
    select null as id

)

select *
from source_data

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
