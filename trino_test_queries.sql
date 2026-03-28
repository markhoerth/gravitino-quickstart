-- ============================================================
-- Trino: JDBC view test queries — Gravitino Quickstart
-- Run inside the Trino CLI (make trino-sql)
--
-- Trino connects through Gravitino as the catalog layer.
-- Catalog path: gravitino."postgres_demo"."sales".<table_or_view>
--
-- This tests whether Gravitino correctly surfaces Postgres
-- views — including computed/expression columns — to Trino.
-- ============================================================

-- Set the working context
USE gravitino."postgres_demo"."sales";

-- -------------------------------------------------------
-- Baseline: confirm what Gravitino surfaces
-- -------------------------------------------------------

-- What schemas does Gravitino expose from postgres_demo?
SHOW SCHEMAS FROM gravitino."postgres_demo";

-- What tables/views are visible in sales?
SHOW TABLES FROM gravitino."postgres_demo"."sales";

-- Describe a view — does Gravitino surface computed columns?
-- KEY TEST: line_total and total_revenue should appear here.
-- If missing, Gravitino inherits Trino's metadata blind spot.
DESCRIBE gravitino."postgres_demo"."sales".v_order_summary;
DESCRIBE gravitino."postgres_demo"."sales".v_customer_revenue;
DESCRIBE gravitino."postgres_demo"."sales".v_open_orders;

-- -------------------------------------------------------
-- Test queries (mirror the direct-JDBC baseline)
-- -------------------------------------------------------

-- T1: Simple scan of a view
SELECT * FROM gravitino."postgres_demo"."sales".v_order_summary;

-- T2: Filter on top of a view
SELECT * FROM gravitino."postgres_demo"."sales".v_order_summary
WHERE region = 'west';

-- T3: Aggregation view — full scan
SELECT * FROM gravitino."postgres_demo"."sales".v_customer_revenue
ORDER BY total_revenue DESC;

-- T4: Filter on aggregation view
SELECT * FROM gravitino."postgres_demo"."sales".v_customer_revenue
WHERE tier = 'enterprise';

-- T5: Open orders view
SELECT * FROM gravitino."postgres_demo"."sales".v_open_orders;

-- T6: HAVING + scalar subquery view
SELECT * FROM gravitino."postgres_demo"."sales".v_customers_above_avg;

-- T7: Filter over revenue view
SELECT customer_name, total_revenue
FROM gravitino."postgres_demo"."sales".v_customer_revenue
WHERE region IN ('west', 'east')
ORDER BY total_revenue DESC;

-- T8: Subquery + group + filter
SELECT customer_name, region, SUM(line_total) AS total
FROM gravitino."postgres_demo"."sales".v_order_summary
GROUP BY customer_name, region
HAVING SUM(line_total) > 500;

-- -------------------------------------------------------
-- EXPLAIN plans — key for pushdown analysis
-- -------------------------------------------------------

-- EP1: Does Trino push the WHERE through Gravitino into Postgres?
EXPLAIN SELECT * FROM gravitino."postgres_demo"."sales".v_order_summary
WHERE region = 'west';

-- EP2: Aggregation view predicate pushdown
EXPLAIN SELECT * FROM gravitino."postgres_demo"."sales".v_customer_revenue
WHERE tier = 'enterprise';

-- EP3: Subquery view — full scan expected
EXPLAIN SELECT * FROM gravitino."postgres_demo"."sales".v_customers_above_avg;
