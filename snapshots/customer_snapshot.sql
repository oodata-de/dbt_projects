{% snapshot customer_snapshot_check %}

    {{
        config(
            strategy='check',
            unique_key='customer_id',
            check_cols=['first_name', 'last_name'],
        )
    }}



    select * from {{ source('src_sales', 'customers') }} 

{% endsnapshot %}

/*
    To run this snapshot, use the command:
    dbt snapshot --select orders_snapshot_check

    -- {{
    --     config(
    --       target_schema='snapshots',
    --       strategy='timestamp',
    --       unique_key='order_id',
    -- updated_at='updated_at',
    --     )
    -- }}
*/