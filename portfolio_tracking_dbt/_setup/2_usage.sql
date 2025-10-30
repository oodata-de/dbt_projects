WITH storage AS (
    SELECT 
        TABLE_CATALOG,
        TABLE_SCHEMA,
        TABLE_NAME,
        ACTIVE_BYTES,
        TIME_TRAVEL_BYTES,
        FAILSAFE_BYTES,
        (ACTIVE_BYTES + TIME_TRAVEL_BYTES + FAILSAFE_BYTES) AS TOTAL_BYTES
    FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
    WHERE TABLE_NAME = 'CUSTOMERS_UUID'
)
SELECT 
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    ACTIVE_BYTES / POWER(1024, 4)       AS ACTIVE_TB,
    TIME_TRAVEL_BYTES / POWER(1024, 4)  AS TIME_TRAVEL_TB,
    FAILSAFE_BYTES / POWER(1024, 4)     AS FAILSAFE_TB,
    TOTAL_BYTES / POWER(1024, 4)        AS TOTAL_TB,
    (TOTAL_BYTES / POWER(1024, 4)) * 40 AS ESTIMATED_MONTHLY_COST_USD
FROM storage;

select warehouse_name, mode(warehouse_size) as warehouse_size
from snowflake.account_usage.query_history
where warehouse_size is not null
group by  warehouse_name
;

WITH task_runs AS (
    SELECT 
        ROOT_TASK_ID,
        NAME,
        QUERY_ID,
        SCHEDULED_TIME
    FROM SNOWFLAKE.ACCOUNT_USAGE.TASK_HISTORY
    WHERE QUERY_START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP()) -- last 6 months
      AND STATE = 'SUCCEEDED'
      AND NAME = 'TASK_PRS_DIM_CUST_SCD1'
),
attribution AS (
    SELECT
        QUERY_ID,
        SUM(CREDITS_ATTRIBUTED_COMPUTE) AS WAREHOUSE_CREDITS
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
    WHERE START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    GROUP BY QUERY_ID
)
SELECT
    tr.NAME,
    DATE_TRUNC(month, tr.SCHEDULED_TIME) AS month,
    SUM(a.WAREHOUSE_CREDITS) AS total_warehouse_credits,
    (total_warehouse_credits * 3) AS total_cost
FROM task_runs tr
JOIN attribution a 
    ON tr.QUERY_ID = a.QUERY_ID
GROUP BY tr.NAME, DATE_TRUNC(month, tr.SCHEDULED_TIME)
ORDER BY tr.NAME, month;