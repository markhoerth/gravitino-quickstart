-- ============================================================
-- Spark SQL: JDBC view test queries — Gravitino Quickstart
-- Run inside the Spark SQL shell (make spark-sql)
--
-- TWO modes:
--   A) Direct JDBC — baseline, bypasses Gravitino
--   B) Via Gravitino — uses Gravitino as catalog (requires
--      spark.sql.catalog.gravitino config, see notes below)
--
-- For this quickstart we use Direct JDBC as the baseline.
-- The Gravitino catalog path requires the Gravitino Spark
-- connector jar, which is not included in this image.
-- ============================================================

-- -------------------------------------------------------
-- Mode A: Direct JDBC (baseline — bypasses Gravitino)
-- Register Postgres tables and views as Spark temp views
-- NOTE: Re-run this block at the start of every session.
--       Spark has no persistent catalog — temp views are
--       session-scoped only.
-- -------------------------------------------------------

CREATE OR REPLACE TEMPORARY VIEW pg_customers
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.customers",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_orders
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.orders",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_products
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.products",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_v_order_summary
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.v_order_summary",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_v_customer_revenue
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.v_customer_revenue",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_v_open_orders
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.v_open_orders",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

CREATE OR REPLACE TEMPORARY VIEW pg_v_customers_above_avg
USING jdbc
OPTIONS (
  url      "jdbc:postgresql://postgres:5432/demo_data",
  dbtable  "sales.v_customers_above_avg",
  user     "gravitino",
  password "gravitino",
  driver   "org.postgresql.Driver"
);

-- -------------------------------------------------------
-- Test queries
-- -------------------------------------------------------

-- T1: Simple scan of a view
SELECT * FROM pg_v_order_summary;

-- T2: Filter on top of a view
SELECT * FROM pg_v_order_summary WHERE region = 'west';

-- T3: Aggregation view — full scan
SELECT * FROM pg_v_customer_revenue ORDER BY total_revenue DESC;

-- T4: Filter on aggregation view
SELECT * FROM pg_v_customer_revenue WHERE tier = 'enterprise';

-- T5: Open orders view
SELECT * FROM pg_v_open_orders;

-- T6: HAVING + scalar subquery view
SELECT * FROM pg_v_customers_above_avg;

-- T7: Filter over revenue view
SELECT customer_name, total_revenue
FROM pg_v_customer_revenue
WHERE region IN ('west', 'east')
ORDER BY total_revenue DESC;

-- T8: Subquery + group + filter over order summary view
SELECT * FROM (
  SELECT customer_name, region, SUM(line_total) AS total
  FROM pg_v_order_summary
  GROUP BY customer_name, region
) t
WHERE total > 500;
