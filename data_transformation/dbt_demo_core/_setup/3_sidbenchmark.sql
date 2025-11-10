-- Step 1: Create schema for testing
USE database bench_db;
CREATE OR REPLACE SCHEMA benchmark_keys;
use warehouse WH_BENCHMARK;

alter session set USE_CACHED_RESULT = FALSE;  -- disable persisted result cache for this session
-- (Optional) also alternate suspend/resume between runs to limit warehouse local cache effects
alter warehouse WH_BENCHMARK suspend;
alter warehouse WH_BENCHMARK resume;


------------------------------
-- 1. Setup clean schemas
------------------------------
CREATE OR REPLACE SCHEMA benchmark_keys;

------------------------------
-- 2. Customer tables
------------------------------
-- UUID-based customers
CREATE OR REPLACE TABLE benchmark_keys.customers_uuid (
    customer_id STRING,  -- UUID
    name STRING
);

-- Surrogate INT customers
CREATE OR REPLACE TABLE benchmark_keys.customers_int (
    customer_id INT,  -- Surrogate key
    name STRING
);

------------------------------
-- 3. Orders tables
------------------------------
-- UUID-based orders
CREATE OR REPLACE TABLE benchmark_keys.orders_uuid (
    order_id STRING,
    customer_id STRING,
    order_date DATE,
    amount NUMBER(10,2)
);

-- INT-based orders
CREATE OR REPLACE TABLE benchmark_keys.orders_int (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount NUMBER(10,2)
);


------------------------------
-- 4. Populate Customers
------------------------------
-- Number of customers
SET num_customers = 1000000;

-- UUID customers
INSERT INTO benchmark_keys.customers_uuid
SELECT UUID_STRING(),
    'Customer-' || SEQ4()
FROM TABLE(GENERATOR(ROWCOUNT => $num_customers));

-- INT surrogate customers
INSERT INTO benchmark_keys.customers_int
SELECT SEQ4() + 1,  -- Surrogate starts at 1
    'Customer-' || SEQ4()
FROM TABLE(GENERATOR(ROWCOUNT => $num_customers));

------------------------------
-- 5. Populate Orders (10M rows)
------------------------------
SET num_orders = 10000000;

-- UUID Orders
INSERT INTO benchmark_keys.orders_uuid (order_id, customer_id, order_date, amount)
WITH gen AS (
    SELECT SEQ8() AS rn
    FROM TABLE(GENERATOR(ROWCOUNT => $num_orders))
),
cust AS (
    SELECT customer_id,
           ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
    FROM benchmark_keys.customers_uuid
)
SELECT UUID_STRING() AS order_id,
       c.customer_id,
       CURRENT_DATE - UNIFORM(0,365,RANDOM()) AS order_date,
       UNIFORM(10,1000,RANDOM()) AS amount
FROM gen g
JOIN cust c
  ON MOD(g.rn, (SELECT COUNT(*) FROM cust)) + 1 = c.rn;

-- INT Orders
INSERT INTO benchmark_keys.orders_int (order_id, customer_id, order_date, amount)
WITH gen AS (
    SELECT SEQ8() AS rn
    FROM TABLE(GENERATOR(ROWCOUNT => $num_orders))
),
cust AS (
    SELECT customer_id,
           ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
    FROM benchmark_keys.customers_int
)
SELECT g.rn + 1 AS order_id,  -- sequential order_id
       c.customer_id,
       CURRENT_DATE - UNIFORM(0,365,RANDOM()) AS order_date,
       UNIFORM(10,1000,RANDOM()) AS amount
FROM gen g
JOIN cust c
  ON MOD(g.rn, (SELECT COUNT(*) FROM cust)) + 1 = c.rn;

  
  
select max(length(customer_id)) from  benchmark_keys.customers_uuid;
------------------------------
-- 6. Benchmark Queries
------------------------------
-- UUID join
ALTER SESSION SET QUERY_TAG = 'BENCHMARK_UUID';
SELECT o.order_id, o.amount, c.name
FROM benchmark_keys.orders_uuid o
JOIN benchmark_keys.customers_uuid c
  ON o.customer_id = c.customer_id
WHERE o.amount > 900;

-- INT join
ALTER SESSION SET QUERY_TAG = 'BENCHMARK_INT';
SELECT o.order_id, o.amount, c.name
FROM benchmark_keys.orders_int o
JOIN benchmark_keys.customers_int c
  ON o.customer_id = c.customer_id
WHERE o.amount > 900;


-----------------------------------
-- 8. Capture Query History
-----------------------------------
ALTER SESSION UNSET QUERY_TAG;
-- Grab the last 2 benchmark queries
WITH recent AS (
    SELECT *
    -- FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    --     END_TIME_RANGE_START => DATEADD('minute', -20, CURRENT_TIMESTAMP()),
    --     RESULT_LIMIT => 50
    -- ))
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE QUERY_TAG IN ('BENCHMARK_UUID','BENCHMARK_INT')
        AND QUERY_TYPE = 'SELECT'
        AND WAREHOUSE_SIZE IS NOT NULL
    ORDER BY START_TIME ASC
    LIMIT 2
)
SELECT QUERY_TAG,
       TOTAL_ELAPSED_TIME/1000 AS total_time_sec,
       BYTES_SCANNED/1024/1024 AS mb_scanned,
       COMPILATION_TIME,
       EXECUTION_TIME,
       ROWS_PRODUCED,
       CREDITS_USED_CLOUD_SERVICES
FROM recent;

-----------------------------------
-- 9. Drill into Query Profile
-----------------------------------
-- Get detailed profile (operators, partitions, cache hits, etc.)
-- Replace <UUID_QUERY_ID> and <INT_QUERY_ID> with IDs from above

SELECT * 
FROM TABLE(INFORMATION_SCHEMA.QUERY_PROFILE('<UUID_QUERY_ID>'));

SELECT * 
FROM TABLE(INFORMATION_SCHEMA.QUERY_PROFILE('<INT_QUERY_ID>'));


WITH recent AS (
    SELECT *
    FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
        END_TIME_RANGE_START => DATEADD('minute', -20, CURRENT_TIMESTAMP()),
        RESULT_LIMIT => 50
    ))
    WHERE QUERY_TAG IN ('BENCHMARK_UUID','BENCHMARK_INT')
      AND QUERY_TYPE = 'SELECT'
      AND WAREHOUSE_SIZE IS NOT NULL
    ORDER BY START_TIME ASC
    LIMIT 2
),
metrics AS (
    SELECT QUERY_TAG,
           TOTAL_ELAPSED_TIME/1000 AS total_time_sec,
           BYTES_SCANNED/1024/1024 AS mb_scanned,
           COMPILATION_TIME,
           EXECUTION_TIME,
           ROWS_PRODUCED,
           CREDITS_USED_CLOUD_SERVICES
    FROM recent
),
pivoted AS (
    SELECT 
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_UUID' THEN total_time_sec END) AS uuid_time,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_INT' THEN total_time_sec END)  AS int_time,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_UUID' THEN mb_scanned END)     AS uuid_mb,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_INT' THEN mb_scanned END)      AS int_mb,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_UUID' THEN compilation_time END) AS uuid_compile,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_INT' THEN compilation_time END)  AS int_compile,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_UUID' THEN execution_time END)   AS uuid_exec,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_INT' THEN execution_time END)    AS int_exec,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_UUID' THEN rows_produced END)    AS uuid_rows,
        MAX(CASE WHEN QUERY_TAG = 'BENCHMARK_INT' THEN rows_produced END)     AS int_rows
    FROM metrics
)
SELECT 
    ROUND(((uuid_time - int_time)/int_time)*100,2) AS pct_diff_time,
    ROUND(((uuid_mb - int_mb)/int_mb)*100,2)       AS pct_diff_mb,
    ROUND(((uuid_compile - int_compile)/int_compile)*100,2) AS pct_diff_compile,
    ROUND(((uuid_exec - int_exec)/int_exec)*100,2) AS pct_diff_exec,
FROM pivoted;
