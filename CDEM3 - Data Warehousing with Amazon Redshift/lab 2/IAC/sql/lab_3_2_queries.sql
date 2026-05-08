-- =============================================
-- LAB 3.2: COPY COMMAND + SPECTRUM QUERIES
-- Account:  352505432441
-- Bucket:   data-lake-prod-352505432441
-- IAM Role: arn:aws:iam::352505432441:role/RedshiftIAMRole
-- Cluster:  redshift-tier3-lab / database: analytics
--
-- Run each section in Redshift Query Editor v2
-- =============================================


-- ─────────────────────────────────────────────
-- PART 1: CREATE TABLES
-- ─────────────────────────────────────────────

CREATE TABLE customers (
    customer_id    INTEGER,
    customer_name  VARCHAR(100),
    country        VARCHAR(50),
    signup_date    DATE,
    lifetime_value NUMERIC(12,2)
);

CREATE TABLE orders (
    order_id    INTEGER,
    customer_id INTEGER,
    product     VARCHAR(100),
    amount      NUMERIC(10,2),
    order_date  DATE
);

CREATE TABLE events (
    event_id         INTEGER,
    user_id          INTEGER,
    event_type       VARCHAR(50),
    event_timestamp  TIMESTAMP,
    session_id       VARCHAR(20),
    duration_seconds INTEGER
);


-- ─────────────────────────────────────────────
-- PART 2: COPY COMMANDS (load from S3)
-- ─────────────────────────────────────────────

COPY customers (customer_id, customer_name, country, signup_date, lifetime_value)
FROM 's3://data-lake-prod-352505432441/raw/customers.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1
MAXERROR 100;

COPY orders (order_id, customer_id, product, amount, order_date)
FROM 's3://data-lake-prod-352505432441/raw/orders.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1
MAXERROR 100;

COPY events (event_id, user_id, event_type, event_timestamp, session_id, duration_seconds)
FROM 's3://data-lake-prod-352505432441/raw/events.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1
MAXERROR 100;


-- ─────────────────────────────────────────────
-- PART 3: VERIFY LOADED DATA
-- ─────────────────────────────────────────────

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders',                  COUNT(*)               FROM orders
UNION ALL
SELECT 'events',                  COUNT(*)               FROM events;
-- Expected: customers=10, orders=15, events=100


-- ─────────────────────────────────────────────
-- PART 4: PERFORMANCE TEST — COPY data (should be <1s)
-- ─────────────────────────────────────────────

SELECT
    c.customer_name,
    COUNT(o.order_id) AS orders_count,
    SUM(o.amount)     AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- ─────────────────────────────────────────────
-- PART 5: SPECTRUM — CREATE EXTERNAL SCHEMA
-- (references the Glue DB created by Terraform)
-- ─────────────────────────────────────────────

CREATE EXTERNAL SCHEMA spectrum_events
FROM DATA CATALOG
DATABASE 'spectrum_db'
REGION 'us-east-1'
IAM_ROLE 'arn:aws:iam::352505432441:role/RedshiftIAMRole';


-- ─────────────────────────────────────────────
-- PART 6: SPECTRUM — CREATE EXTERNAL TABLE
-- (defines structure over S3 file; does NOT load data)
-- ─────────────────────────────────────────────

CREATE EXTERNAL TABLE spectrum_events.events_external (
    event_id         INTEGER,
    user_id          INTEGER,
    event_type       VARCHAR(50),
    event_timestamp  TIMESTAMP,
    session_id       VARCHAR(20),
    duration_seconds INTEGER
)
STORED AS TEXTFILE
LOCATION 's3://data-lake-prod-352505432441/raw/events.csv'
WITH SERDEPROPERTIES (
    'field.delim'            = ',',
    'skip.header.line.count' = '1'
);


-- ─────────────────────────────────────────────
-- PART 7: SPECTRUM QUERY (should be 1-3s, slower than COPY)
-- ─────────────────────────────────────────────

SELECT COUNT(*) AS event_count FROM spectrum_events.events_external;

-- Compare same aggregation on loaded vs external data:

-- COPY (fast — data in cluster memory):
SELECT event_type, COUNT(*) AS count, AVG(duration_seconds) AS avg_duration
FROM events
GROUP BY event_type
ORDER BY count DESC;

-- Spectrum (slower — reads from S3 on demand):
SELECT event_type, COUNT(*) AS count, AVG(duration_seconds) AS avg_duration
FROM spectrum_events.events_external
GROUP BY event_type
ORDER BY count DESC;


-- ─────────────────────────────────────────────
-- PART 8: COMPRESSION ANALYSIS
-- ─────────────────────────────────────────────

ANALYZE COMPRESSION events;
-- Redshift recommends optimal compression per column.
