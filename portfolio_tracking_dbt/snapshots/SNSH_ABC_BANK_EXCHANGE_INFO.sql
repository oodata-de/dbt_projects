{% snapshot SNSH_ABC_BANK_EXCHANGE_INFO %}

{{

    config(
        unique_key= 'EXCHANGE_HKEY',
        strategy='check',
        check_cols=['EXCHANGE_HDIFF'],
    )

}}

select * from {{ ref('STG_ABC_BANK_EXCHANGE_INFO') }}

{% endsnapshot %}