-- =============================================
-- LAB 3.3: TABLE DESIGN OPTIMIZATION
-- DISTKEY | SORTKEY | COMPRESSION
-- Account:  352505432441
-- Bucket:   data-lake-prod-352505432441
-- IAM Role: arn:aws:iam::352505432441:role/RedshiftIAMRole
-- Cluster:  redshift-tier3-lab / database: analytics
--
-- Run each section in Redshift Query Editor v2
-- =============================================


-- ─────────────────────────────────────────────
-- PART 1: INSPECT CURRENT TABLE STRUCTURE
-- ─────────────────────────────────────────────
-- Shows DISTKEY, SORTKEYs, and whether encoding is applied.
-- Before optimization you'll see no dist_key, no sort_keys, encoded=N.

SELECT
    tablename,
    diststyle,
    sortkey1,
    encoded
FROM svv_table_info
WHERE tablename IN ('customers', 'orders', 'events');


-- ─────────────────────────────────────────────
-- PART 2: OPTIMIZED CUSTOMERS TABLE
-- DISTKEY: customer_id  (most common join/filter column)
-- SORTKEY: signup_date  (date-range queries)
-- Compression: ENCODE per column
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id    INTEGER          DISTKEY ENCODE RAW,
    customer_name  VARCHAR(100)     ENCODE ZSTD,
    country        VARCHAR(50)      ENCODE LZO,
    signup_date    DATE SORTKEY     ENCODE DELTA,
    lifetime_value NUMERIC(12,2)    ENCODE ZSTD
);

COPY customers (customer_id, customer_name, country, signup_date, lifetime_value)
FROM 's3://data-lake-prod-352505432441/raw/customers.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1;


-- ─────────────────────────────────────────────
-- PART 3: OPTIMIZED ORDERS TABLE
-- DISTKEY: customer_id  (join key — co-located with customers)
-- SORTKEY: order_date   (time-based filtering + block pruning)
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id    INTEGER          ENCODE RAW,
    customer_id INTEGER DISTKEY  ENCODE RAW,
    product     VARCHAR(100)     ENCODE ZSTD,
    amount      NUMERIC(10,2)    ENCODE ZSTD,
    order_date  DATE SORTKEY     ENCODE DELTA
);

COPY orders (order_id, customer_id, product, amount, order_date)
FROM 's3://data-lake-prod-352505432441/raw/orders.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1;


-- ─────────────────────────────────────────────
-- PART 4: OPTIMIZED EVENTS TABLE
-- DISTKEY: user_id              (query/filter by user)
-- COMPOUND SORTKEY:             (event_timestamp first, event_type second)
--   - Primary: time-range queries (most common filter)
--   - Secondary: type grouping (GROUP BY event_type)
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS events;

CREATE TABLE events (
    event_id         INTEGER          ENCODE RAW,
    user_id          INTEGER DISTKEY  ENCODE RAW,
    event_type       VARCHAR(50)      ENCODE LZO,
    event_timestamp  TIMESTAMP        ENCODE DELTA,
    session_id       VARCHAR(20)      ENCODE LZO,
    duration_seconds INTEGER          ENCODE DELTA
)
DISTSTYLE KEY
COMPOUND SORTKEY (event_timestamp, event_type);

COPY events (event_id, user_id, event_type, event_timestamp, session_id, duration_seconds)
FROM 's3://data-lake-prod-352505432441/raw/events.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::352505432441:role/RedshiftIAMRole'
FORMAT CSV
DELIMITER ','
IGNOREHEADER 1;


-- ─────────────────────────────────────────────
-- PART 5: VERIFY ALL TABLES LOADED + STRUCTURE
-- ─────────────────────────────────────────────

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders',                  COUNT(*)               FROM orders
UNION ALL
SELECT 'events',                  COUNT(*)               FROM events;
-- Expected: customers=10, orders=15, events=100

-- Confirm DISTKEY, SORTKEY, encoding applied:
SELECT
    tablename,
    diststyle,
    sortkey1,
    sortkey2,
    encoded
FROM svv_table_info
WHERE tablename IN ('customers', 'orders', 'events');
-- encoded should now = Y for all tables


-- ─────────────────────────────────────────────
-- PART 6: PERFORMANCE TEST 1 — Customer Lookup
-- DISTKEY on customer_id → data on one node, no cross-node scan
-- Expected: <1 second
-- ─────────────────────────────────────────────

SELECT * FROM customers WHERE customer_id = 5;


-- ─────────────────────────────────────────────
-- PART 7: PERFORMANCE TEST 2 — Co-located Join
-- Both tables DISTKEY on customer_id → no redistribution
-- Expected: <1 second
-- ─────────────────────────────────────────────

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id)  AS orders_count,
    SUM(o.amount)      AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- ─────────────────────────────────────────────
-- PART 8: PERFORMANCE TEST 3 — Date Range (Block Pruning)
-- SORTKEY on order_date → Redshift skips irrelevant blocks
-- Expected: <1 second
-- ─────────────────────────────────────────────

SELECT
    order_date,
    COUNT(*)      AS order_count,
    SUM(amount)   AS daily_revenue
FROM orders
WHERE order_date >= '2024-01-15'
GROUP BY order_date
ORDER BY order_date;


-- ─────────────────────────────────────────────
-- PART 9: PERFORMANCE TEST 4 — Event Aggregation
-- COMPOUND SORTKEY on (event_timestamp, event_type)
-- → Time-range + type grouping both fast
-- Expected: <1 second
-- ─────────────────────────────────────────────

SELECT
    event_type,
    COUNT(*)                    AS count,
    AVG(duration_seconds)       AS avg_duration,
    MAX(duration_seconds)       AS max_duration
FROM events
WHERE event_timestamp >= '2024-02-01'
GROUP BY event_type
ORDER BY count DESC;


-- ─────────────────────────────────────────────
-- PART 10: COMPRESSION ANALYSIS
-- ANALYZE COMPRESSION samples the table and recommends
-- optimal encoding per column. Compare against what we chose.
-- ─────────────────────────────────────────────

ANALYZE COMPRESSION customers;
ANALYZE COMPRESSION orders;
ANALYZE COMPRESSION events;


-- ─────────────────────────────────────────────
-- TEARDOWN — run when Tier 3 labs are complete
-- Destroys the cluster (stops charges ~$0.96/hr)
-- OR use: terraform destroy (from CDEM3/lab 1/IAC/terraform/)
-- ─────────────────────────────────────────────

-- Manual SQL teardown (run in query editor before cluster delete):
-- DROP TABLE IF EXISTS customers;
-- DROP TABLE IF EXISTS orders;
-- DROP TABLE IF EXISTS events;
-- DROP SCHEMA IF EXISTS spectrum_events CASCADE;
