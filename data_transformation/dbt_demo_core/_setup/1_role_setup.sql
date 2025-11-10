use role sysadmin;
-- Create a database to store our schemas.
create database if not exists dbt_dev;
create database if not exists dbt_prod;



-- Create schema.
use database dbt_dev;
use role sysadmin;
create schema if not exists sch_bronze_sales;
create schema if not exists sch_bronze_inventory;
create schema if not exists sch_silver_inventory;
create schema if not exists sch_silver_sales;
create schema if not exists sch_intermediate;
create schema if not exists sch_dbt_test;
create schema if not exists sch_gold_customer;
create schema if not exists sch_gold_sales;
create schema if not exists sch_gold_inventory;

-- We'll remove the default schema to keep things clean.
drop schema if exists dbt_dev.public;
drop schema if exists dbt_prod.public;

/*
    Warehouses are synonymous with the idea of compute
    resources in other systems.
*/
create warehouse if not exists development 
    warehouse_size = xsmall
    auto_suspend = 30
    initially_suspended = true;

create warehouse if not exists production 
    warehouse_size = xsmall
    auto_suspend = 30
    initially_suspended = true;


-- Create source tables in RAW database
-- Customer orders data
CREATE OR REPLACE TABLE sch_bronze_sales.orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    product_id INTEGER,
    quantity INTEGER,
    amount DECIMAL(10,2),
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Customer information
CREATE OR REPLACE TABLE sch_bronze_sales.customers (
    customer_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    country VARCHAR(50),
    created_date DATE,
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Product catalog
CREATE OR REPLACE TABLE sch_bronze_sales.products (
    product_id INTEGER,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    in_stock BOOLEAN,
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample data
INSERT INTO sch_bronze_sales.orders VALUES
 (1, 101, '2024-01-01', 1, 2, 199.98, CURRENT_TIMESTAMP()),
 (2, 102, '2024-01-02', 2, 1, 299.99, CURRENT_TIMESTAMP()),
 (3, 101, '2024-01-03', 3, 3, 149.97, CURRENT_TIMESTAMP()),
 (4, 103, '2024-01-03', 1, 1, 99.99, CURRENT_TIMESTAMP());

INSERT INTO sch_bronze_sales.customers VALUES
 (101, 'John', 'Doe', 'john.doe@email.com', 'USA', '2023-01-15', CURRENT_TIMESTAMP()),
 (102, 'Jane', 'Smith', 'jane.smith@email.com', 'Canada', '2023-02-20', CURRENT_TIMESTAMP()),
 (103, 'Bob', 'Johnson', 'bob.j@email.com', 'UK', '2023-03-10', CURRENT_TIMESTAMP());

INSERT INTO sch_bronze_sales.products VALUES
 (1, 'Premium Laptop', 'Electronics', 999.99, true, CURRENT_TIMESTAMP()),
 (2, 'Wireless Headphones', 'Electronics', 299.99, true, CURRENT_TIMESTAMP()),
 (3, 'Smart Watch', 'Accessories', 49.99, true, CURRENT_TIMESTAMP()),
 (4, 'Gaming Mouse', 'Accessories', 89.99, false, CURRENT_TIMESTAMP());

-- Additional inventory-related tables in RAW database
CREATE OR REPLACE TABLE sch_bronze_inventory.inventory_levels (
    inventory_id INTEGER,
    product_id INTEGER,
    warehouse_location VARCHAR(50),
    quantity_on_hand INTEGER,
    last_updated_at TIMESTAMP,
    minimum_stock_level INTEGER,
    maximum_stock_level INTEGER,
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE sch_bronze_inventory.inventory_transactions (
    transaction_id INTEGER,
    product_id INTEGER,
    transaction_type VARCHAR(20),
    quantity INTEGER,
    transaction_date TIMESTAMP,
    warehouse_location VARCHAR(50),
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample inventory data
INSERT INTO sch_bronze_inventory.inventory_levels VALUES
 (1, 1, 'EAST_WH', 50, CURRENT_TIMESTAMP(), 20, 100, CURRENT_TIMESTAMP()),
 (2, 2, 'EAST_WH', 75, CURRENT_TIMESTAMP(), 30, 150, CURRENT_TIMESTAMP()),
 (3, 3, 'WEST_WH', 100, CURRENT_TIMESTAMP(), 40, 200, CURRENT_TIMESTAMP()),
 (4, 4, 'WEST_WH', 15, CURRENT_TIMESTAMP(), 25, 120, CURRENT_TIMESTAMP());

INSERT INTO sch_bronze_inventory.inventory_transactions VALUES
 (1, 1, 'RECEIPT', 100, '2024-01-01 10:00:00', 'EAST_WH', CURRENT_TIMESTAMP()),
 (2, 1, 'SHIPMENT', -50, '2024-01-02 15:30:00', 'EAST_WH', CURRENT_TIMESTAMP()),
 (3, 2, 'RECEIPT', 150, '2024-01-01 11:00:00', 'EAST_WH', CURRENT_TIMESTAMP()),
 (4, 3, 'RECEIPT', 200, '2024-01-01 14:00:00', 'WEST_WH', CURRENT_TIMESTAMP());

-- Addresses table
CREATE OR REPLACE TABLE sch_bronze_sales.addresses (
    customer_id INTEGER,
    address_id INTEGER,
    address_line1 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(10),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    address_type VARCHAR(20),
    _el_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO sch_bronze_sales.addresses (
    customer_id, address_id, address_line1, city, state, postal_code, country, address_type, _el_timestamp
) VALUES
    (101, 1, '101 MAIN ST', 'SEATTLE', 'WA', '98101', 'USA', 'HOME', CURRENT_TIMESTAMP()),
    (101, 2, '500 2ND AVE', 'SEATTLE', 'WA', '98104', 'USA', 'WORK', CURRENT_TIMESTAMP()),
    (102, 1, '22 OAK ROAD', 'AUSTIN', 'TX', '73301', 'USA', 'HOME', CURRENT_TIMESTAMP()),
    (102, 2, '400 TECH PKWY', 'AUSTIN', 'TX', '73301', 'USA', 'WORK', CURRENT_TIMESTAMP()),
    (103, 1, '77 LAKE SHORE DR', 'CHICAGO', 'IL', '60601', 'USA', 'HOME', CURRENT_TIMESTAMP()),
    (103, 2, '330 W MONROE', 'CHICAGO', 'IL', '60606', 'USA', 'WORK', CURRENT_TIMESTAMP());