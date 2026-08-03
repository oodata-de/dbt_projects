{% set business_columns = [
    'MINUTE_NUMBER','MINUTE_DATE','QUARTER_HOUR_INTERVAL','HOUR_INTERVAL','AM_PM','SOURCE_ID','SOURCE_NAME'
] %}

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='minute_id',
    merge_update_columns=business_columns,
    on_schema_change='append_new_columns',
    tags=["static"]
) }}

/*
-- model tests the following merge logic to prevent data duplication / unnecessary updates in incremental loads:
-- if type1hash at source == type1hash at target - do nothing
-- if type1hash at source != type1hash at target and id.source == id.target - update business columns (in this case name)
-- if type1hash at source != type1hash at target and id.source != id.target - insert new column
-- perfromance issue: {{ this }} is queried twice incremental run to compare hashes, merge logic - so for very large datasets this may be slow }}
-- this complexity can be skipped if we don't mind updating exising rows even if data hasn't changed (will only update bsuiness columns based on unique key match)
-- add merge_update_columns = bsuiness_columns
*/

WITH d_minute AS (
    SELECT 
        1 AS MINUTE_ID,
        15 AS MINUTE_NUMBER,
        '2025-01-01'::DATE AS MINUTE_DATE,
        'Q1' AS QUARTER_HOUR_INTERVAL,
        '01' AS HOUR_INTERVAL,
        'AM' AS AM_PM,
        100 AS SOURCE_ID,
        'TEST_SOURCE' AS SOURCE_NAME,
        null as __late_arriving_flag,
        null as __effective_start_datetime, 
        null as __effective_end_datetime, 
        null as __current_flag,
        null as __deleted_flag,
        null as __create_datetime_utc, 
    UNION ALL
    SELECT 
        2, 30, '2025-01-01', 'Q2', '02', 'PM', 101, 'TEST_SOURCE_2'
),

final as (
    SELECT *, TO_TIMESTAMP('2025-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') AS __process_ts_utc,
    {{ audit_columns_sha(business_columns) }}
FROM d_minute
)

select s.* 
from final s
{% if is_incremental() %}
    -- LEFT JOIN {{ this }} t
    -- ON s.minute_id = t.minute_id
    -- WHERE
    --     (
    --         t.minute_id IS NULL -- new id, insert
    --         OR s.__type1hash != t.__type1hash -- hash changed, update
    --     )
    WHERE __process_ts_utc > (
        SELECT COALESCE(MAX(__update_datetime_utc), '1900-01-01'::TIMESTAMP)
        FROM {{ this }}
    )
{% endif %}