SELECT * FROM DBT_DEV.CUSTOMER.CUSTOMER_SNAPSHOT_CHECK

INSERT INTO sch_bronze_sales.customers VALUES
    (101, 'JohnJon', 'Doe', 'john.doe@email.com', 'USA', '2023-01-15');

INSERT INTO sch_bronze_sales.customers VALUES
    (104, 'Sarahhh', 'Jane', 'sarah.jane@email.com', 'NG', '2024-07-15'),
    (105, 'Lisa', 'Brown', 'lisab@email.com', 'UK', '2025-01-15');

SELECT * FROM sch_gold_customer.d_customer_audit AT(TIMESTAMP => 'Mon, 29 Sep 2025 20:05:00 -0700'::timestamp_tz);

SELECT * FROM sch_bronze_sales.customers;