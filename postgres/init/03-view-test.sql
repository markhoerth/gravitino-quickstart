-- ============================================================
-- 03-view-test.sql
-- View test data for JDBC view behavior testing
-- Runs inside the demo_data database (created in 01-databases.sql)
-- ============================================================

\connect demo_data

CREATE SCHEMA IF NOT EXISTS sales;
GRANT ALL ON SCHEMA sales TO gravitino;

-- -------------------------------------------------------
-- Base tables
-- -------------------------------------------------------

CREATE TABLE sales.customers (
    customer_id   SERIAL PRIMARY KEY,
    name          TEXT    NOT NULL,
    region        TEXT    NOT NULL,
    tier          TEXT    NOT NULL DEFAULT 'standard'
);

CREATE TABLE sales.products (
    product_id    SERIAL PRIMARY KEY,
    sku           TEXT    NOT NULL UNIQUE,
    product_name  TEXT    NOT NULL,
    category      TEXT    NOT NULL,
    list_price    NUMERIC(10,2) NOT NULL
);

CREATE TABLE sales.orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT     NOT NULL REFERENCES sales.customers(customer_id),
    product_id    INT     NOT NULL REFERENCES sales.products(product_id),
    quantity      INT     NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL,
    order_date    DATE    NOT NULL DEFAULT CURRENT_DATE,
    status        TEXT    NOT NULL DEFAULT 'open'
);

-- -------------------------------------------------------
-- Sample data
-- -------------------------------------------------------

INSERT INTO sales.customers (name, region, tier) VALUES
    ('Acme Corp',     'west',    'enterprise'),
    ('Globex Inc',    'east',    'premium'),
    ('Initech LLC',   'central', 'standard'),
    ('Umbrella Ltd',  'west',    'enterprise'),
    ('Soylent Co',    'east',    'standard'),
    ('Initrode Corp', 'central', 'premium');

INSERT INTO sales.products (sku, product_name, category, list_price) VALUES
    ('WDG-001', 'Widget Alpha',   'widgets',   19.99),
    ('WDG-002', 'Widget Beta',    'widgets',   34.99),
    ('GDG-001', 'Gadget X',       'gadgets',  149.99),
    ('GDG-002', 'Gadget Y',       'gadgets',  249.99),
    ('SVC-001', 'Support Tier 1', 'services',  99.00),
    ('SVC-002', 'Support Tier 2', 'services', 199.00);

INSERT INTO sales.orders (customer_id, product_id, quantity, unit_price, order_date, status) VALUES
    (1, 3,  10, 149.99, '2024-01-15', 'closed'),
    (1, 4,   5, 249.99, '2024-02-20', 'closed'),
    (2, 1,  50,  19.99, '2024-02-14', 'shipped'),
    (2, 5,   1,  99.00, '2024-03-01', 'open'),
    (3, 2,  20,  34.99, '2024-03-10', 'open'),
    (4, 4,   8, 249.99, '2024-01-30', 'closed'),
    (4, 6,   2, 199.00, '2024-02-28', 'shipped'),
    (5, 1, 100,  18.00, '2024-03-05', 'open'),
    (6, 3,   3, 149.99, '2024-03-12', 'open'),
    (6, 5,   1,  99.00, '2024-03-12', 'open');

-- Grant table access to gravitino user
GRANT ALL ON ALL TABLES IN SCHEMA sales TO gravitino;
GRANT ALL ON ALL SEQUENCES IN SCHEMA sales TO gravitino;

-- -------------------------------------------------------
-- Views  — these are what we test engines against
-- -------------------------------------------------------

-- Simple projection view with expression column
CREATE VIEW sales.v_order_summary AS
SELECT
    o.order_id,
    c.name          AS customer_name,
    c.region,
    c.tier,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price,
    (o.quantity * o.unit_price) AS line_total,
    o.order_date,
    o.status
FROM sales.orders o
JOIN sales.customers c ON c.customer_id = o.customer_id
JOIN sales.products  p ON p.product_id  = o.product_id;

-- Aggregation view with expression column
CREATE VIEW sales.v_customer_revenue AS
SELECT
    c.customer_id,
    c.name          AS customer_name,
    c.region,
    c.tier,
    COUNT(o.order_id)              AS order_count,
    SUM(o.quantity * o.unit_price) AS total_revenue
FROM sales.customers c
LEFT JOIN sales.orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.region, c.tier;

-- Filtered view with expression column
CREATE VIEW sales.v_open_orders AS
SELECT
    o.order_id,
    c.name     AS customer_name,
    p.sku,
    p.product_name,
    o.quantity,
    o.unit_price,
    (o.quantity * o.unit_price) AS line_total,
    o.order_date
FROM sales.orders o
JOIN sales.customers c ON c.customer_id = o.customer_id
JOIN sales.products  p ON p.product_id  = o.product_id
WHERE o.status = 'open';

-- HAVING + correlated scalar subquery view
CREATE VIEW sales.v_customers_above_avg AS
SELECT
    c.customer_id,
    c.name,
    c.region,
    SUM(o.quantity * o.unit_price) AS total_revenue
FROM sales.customers c
JOIN sales.orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.region
HAVING SUM(o.quantity * o.unit_price) > (
    SELECT AVG(sub.rev)
    FROM (
        SELECT SUM(quantity * unit_price) AS rev
        FROM sales.orders
        GROUP BY customer_id
    ) sub
);

-- Grant view access to gravitino user
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO gravitino;
