{{ 
    config(
        materialized='ephemeral'
    ) 
}}

WITH
-- CTE concerned with incoming source data
src_data as (
    SELECT
        ACCOUNTID         as ACCOUNT_CODE     -- TEXT
        , SYMBOL            as SECURITY_CODE    -- TEXT
        , DESCRIPTION       as SECURITY_NAME    -- TEXT
        , EXCHANGE          as EXCHANGE_CODE    -- TEXT
        , {{to_21st_century_date('REPORT_DATE')}}      
                            as REPORT_DATE      -- DATE
        , QUANTITY          as QUANTITY         -- NUMBER
        , COST_BASE         as COST_BASE        -- NUMBER
        , POSITION_VALUE    as POSITION_VALUE   -- NUMBER
        , CURRENCY          as CURRENCY_CODE    -- TEXT
        , 'SOURCE_DATA.ABC_BANK_POSITION' as RECORD_SOURCE
    FROM {{ source('abc_bank', 'ABC_BANK_POSITION') }}
),

-- default_record CTE, you are concerned with providing a default record

-- hashed CTE, you are concerned with saving the history.
-- The HKEY and HDIFF columns provide a clear definition of what the key used for storage is and what defines a version change for the entity.
-- HKEY is used to understand the entity; SK, and HDIFF is used to understand what changed in the version.
hashed as (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'ACCOUNT_CODE', 'SECURITY_CODE'])
        }} as POSITION_HKEY
        , {{ dbt_utils.generate_surrogate_key([
                'ACCOUNT_CODE', 'SECURITY_CODE',
                'SECURITY_NAME', 'EXCHANGE_CODE', 'REPORT_DATE',
                'QUANTITY', 'COST_BASE', 'POSITION_VALUE',
                'CURRENCY_CODE'])
        }} as POSITION_HDIFF -- concatenation of all the non-metadata fields for change detection
        , *
        , '{{ run_started_at }}' as LOAD_TS_UTC
    FROM src_data
)
SELECT * FROM hashed

-- For HDIFF, Using a hash key in place of the string concatenation introduces a small risk, 
-- as it is possible that two different inputs will produce the same output of the hashing algorithm, 
-- but using a hash with a big enough size makes the chance so little that we can use it without any real risk.