USE database dbt_dev;

-- delete insert 
INSERT INTO sch_bronze_sales.customers VALUES
 (102, 'Janet', 'Smithen', 'jane.smith@email.com', 'Canada', '2023-02-20', CURRENT_TIMESTAMP()),
 (104, 'Bob', 'Johnson', 'bob.j@email.com', 'UK', '2023-03-10', CURRENT_TIMESTAMP());

-------------------------------------------
--- Test filter for incremental logic (BETWWEN vs >=)
-------------------------------------------
-- Dummy data CTE
WITH events AS (
    SELECT 1 AS id, '2024-01-01 00:00:00'::timestamp AS event_ts UNION ALL
    SELECT 2, '2024-01-01 12:00:00' UNION ALL
    SELECT 3, '2024-01-02 00:00:00' UNION ALL
    SELECT 4, '2024-01-03 00:00:00'
),

-- Parameters for incremental window
params AS (
    SELECT 
        '2024-01-01 00:00:00'::timestamp AS start_ts,
        '2024-01-03 00:00:00'::timestamp AS end_ts
)

-- Query using >=
SELECT 'GE' AS method, e.*
FROM events e, params p
WHERE e.event_ts >= p.start_ts

UNION ALL

-- Query using BETWEEN
SELECT 'BETWEEN' AS method, e.*
FROM events e, params p
WHERE e.event_ts BETWEEN p.start_ts AND p.end_ts
ORDER BY method, id;

--- Conclusion: No difference using >= or betwwen if used correctly. Between is inclusive of lower and upper bounds (expr >= lower_bound AND expr <= upper_bound )

-------------------------------------------
--- Test merge with attribute hash
-------------------------------------------
use database bench_db;
use schema processing;

-- create table
CREATE OR REPLACE TABLE dim_customer (
    customer_id INT,              -- business key
    customer_name STRING,
    _attribute_hash STRING,
    _create_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _update_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

select * from dim_customer

-- Insert initial data
INSERT INTO dim_customer (customer_id, customer_name, _attribute_hash) VALUES
    (1, 'Alice',   'hash1'),
    (2, 'Bob',     'hash2'),
    (3, 'Charlie', 'hash3');

-- Prepare Incremental (Staging) Data
CREATE OR REPLACE TABLE stg_customer (
    customer_id INT,
    customer_name STRING,
    _attribute_hash STRING
);

INSERT INTO stg_customer VALUES
    (1, 'Alice',   'hash1'),      -- unchanged
    (2, 'Bob Jr.', 'hash2b'),     -- name changed, hash changed
    (4, 'Diana',   'hash4');      -- new customer

-- run merge
MERGE INTO dim_customer AS tgt
USING stg_customer AS src
ON tgt.customer_id = src.customer_id
WHEN MATCHED AND tgt._attribute_hash != src._attribute_hash THEN
    UPDATE SET
        customer_name = src.customer_name,
        _attribute_hash = src._attribute_hash,
        _update_ts = current_timestamp()
WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, _attribute_hash)
    VALUES (src.customer_id, src.customer_name, src._attribute_hash);

select * from dim_customer