{% snapshot SNSH_ABC_BANK_POSITION %}

{{
    config(
        unique_key='POSITION_HKEY',
        strategy='check',
        check_cols=['POSITION_HDIFF'],
        invalidate_hard_deletes=True 
    )
}}

select * from {{ ref('STG_ABC_BANK_POSITION') }}

{% endsnapshot %}

/*
-- invalidate_hard_deletes=True: enable tracking of deletions from the source. 
-- to be able to track deletions, you need to have a reliable full export from the source, as any key that is not in the source is considered deleted
 */
