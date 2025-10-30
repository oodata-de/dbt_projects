{{ config(
    materialized='view',
    transient=false,
    cluster_by=['id'],
    post_hook = "{{ apply_dynamic_masking_policy(
        columns=['email','last_name'],
        masking_policy='plcy_st'
        ) }}"
    )
}}

with source_data as (

    select 101 as id,
        'John' as first_name,
        'Doe' as last_name,
        'john.doe@email.com' as email,
        'USA' as country,
        to_date('2023-01-15') as signup_date
    union all
    select 102 as id,
        'Jane' as first_name,
        'Smith' as last_name,
        'jane.smith@email.com' as email,
        'Canada' as country,
        to_date('2023-02-20') as signup_date
    union all
    select 103 as id,
        'Bob' as first_name,
        'Johnson' as last_name,
        'bob.j@email.com' as email,
        'UK' as country,
        to_date('2023-03-10') as signup_date

)

select *, current_timestamp() as run_ts
from source_data