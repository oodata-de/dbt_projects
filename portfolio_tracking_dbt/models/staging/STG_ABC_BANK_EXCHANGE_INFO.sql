{{ config(materialized='ephemeral') }}

WITH
src_data AS (
    SELECT
        NAME           AS EXCHANGE_NAME,      -- TEXT
        ID             AS EXCHANGE_ID,        -- TEXT
        COUNTRY        AS COUNTRY_CODE,       -- TEXT
        CITY           AS CITY_NAME,          -- TEXT
        ZONE           AS TIME_ZONE,          -- TEXT
        DELTA          AS TIME_DELTA,         -- TEXT
        DST_period     AS DST_PERIOD,         -- TEXT
        OPEN           AS OPEN_TIME,          -- TEXT
        CLOSE          AS CLOSE_TIME,         -- TEXT
        LUNCH          AS LUNCH_TIME,         -- TEXT
        OPEN_UTC       AS OPEN_TIME_UTC,      -- TEXT
        CLOSE_UTC      AS CLOSE_TIME_UTC,     -- TEXT
        LUNCH_UTC      AS LUNCH_TIME_UTC,     -- TEXT
        LOAD_TS        AS LOAD_TS             -- TIMESTAMP_NTZ

        , 'SEED.ABC_Bank_EXCHANGE_INFO' AS RECORD_SOURCE
    FROM {{ source('seeds', 'ABC_Bank_EXCHANGE_INFO') }}
),

default_record AS (
    SELECT
        'Missing'   AS EXCHANGE_NAME,
        '-1'        AS EXCHANGE_ID,
        '-1'        AS COUNTRY_CODE,
        'Missing'   AS CITY_NAME,
        'Missing'   AS TIME_ZONE,
        -1          AS TIME_DELTA,
        'Missing'   AS DST_PERIOD,
        'Missing'   AS OPEN_TIME,
        'Missing'   AS CLOSE_TIME,
        'Missing'   AS LUNCH_TIME,
        'Missing'   AS OPEN_TIME_UTC,
        'Missing'   AS CLOSE_TIME_UTC,
        'Missing'   AS LUNCH_TIME_UTC,
        '2020-01-01' AS LOAD_TS,
        'Missing'   AS RECORD_SOURCE
),

with_default_record AS (
    SELECT * FROM src_data
    UNION ALL
    SELECT * FROM default_record
),

hashed AS (
    SELECT
        concat_ws('|', EXCHANGE_ID) AS EXCHANGE_HKEY,
        concat_ws('|', EXCHANGE_ID, EXCHANGE_NAME, COUNTRY_CODE, CITY_NAME, TIME_ZONE, TIME_DELTA, DST_PERIOD, OPEN_TIME, CLOSE_TIME, LUNCH_TIME, OPEN_TIME_UTC, CLOSE_TIME_UTC, LUNCH_TIME_UTC) AS EXCHANGE_HDIFF,
        * EXCLUDE LOAD_TS,
        LOAD_TS AS LOAD_TS_UTC
    FROM with_default_record
)
SELECT * FROM hashed