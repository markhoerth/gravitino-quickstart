# Gravitino Quickstart

A complete local Gravitino data platform for POCs and developer evaluation. One command to start — includes federated metadata, SQL query engines, a web SQL IDE, and natural language querying via Claude and MCP.

## What you get

| Service     | URL                    | Description                                      | Username              | Password                  |
|-------------|------------------------|--------------------------------------------------|-----------------------|---------------------------|
| Gravitino   | http://localhost:8090  | Federated metadata catalog + governance (V2 UI)  | `gravitino`           | `gravitino`               |
| Trino       | http://localhost:8082  | SQL query engine                                 | `admin`               | *(none)*                  |
| Spark SQL   | `make spark-sql`       | Spark SQL shell via Gravitino connector          | —                     | —                         |
| CloudBeaver | http://localhost:8978  | Web SQL IDE                                      | `cbadmin`             | `Admin1234`               |
| MinIO       | http://localhost:9002  | S3-compatible object storage (Iceberg data)      | `gravitino`           | `gravitino123`            |
| LakeFS      | http://localhost:8000  | Git-for-data branching layer                     | `gravitino-lakefs-key` | `gravitino-lakefs-secret` |

## Prerequisites

* Docker Desktop (or Docker Engine + Compose v2)
* 8GB RAM available to Docker
* ~10GB disk space (base images + 150MB NYC taxi data download on first run)

## Quickstart

```
git clone https://github.com/markhoerth/gravitino-quickstart.git
cd gravitino-quickstart
make up
```

`make up` builds all images and starts all services. Init runs automatically — it downloads NYC taxi data, registers catalogs, and loads ~9.5M rows into Iceberg. **Allow ~5 minutes for full initialization.**

Watch init progress:

```
make logs-svc SVC=init
```

## Query with Trino

```
make trino-sql
```

```sql
SHOW CATALOGS;

-- PostgreSQL via Gravitino
SELECT count(*) FROM postgres_demo.public.customers;
SELECT * FROM postgres_demo.public.transactions WHERE flagged_for_review = true;

-- Hive (NYC taxi — Parquet)
SELECT count(*) FROM hive_nyc.nyc_taxi.yellow_trips;
SELECT avg(total_amount), avg(trip_distance) FROM hive_nyc.nyc_taxi.yellow_trips;

-- Iceberg (NYC taxi — Iceberg REST catalog → MinIO)
SELECT count(*) FROM iceberg_nyc.nyc_taxi.yellow_trips;
SELECT payment_type, count(*), avg(total_amount)
FROM iceberg_nyc.nyc_taxi.yellow_trips
GROUP BY payment_type ORDER BY 2 DESC;

-- LakeFS branching demo
SELECT count(*) FROM hive_lakefs.lakefs_main.yellow_trips;
SELECT count(*) FROM hive_lakefs.lakefs_dev.yellow_trips;
```

## Query with Spark SQL

```
make spark-sql
```

```sql
-- Iceberg via Gravitino Spark connector
USE iceberg_nyc.nyc_taxi;
SHOW TABLES;
SELECT COUNT(*) FROM yellow_trips;
SELECT VendorID, COUNT(*), AVG(total_amount) FROM yellow_trips GROUP BY VendorID;

-- PostgreSQL via Gravitino
SELECT * FROM postgres_demo.public.customers;
```

## Catalogs

| Catalog       | Type         | Data                                              |
|---------------|--------------|---------------------------------------------------|
| postgres_demo | PostgreSQL   | Financial services demo (customers, transactions) |
| hive_nyc      | Hive         | NYC Yellow Taxi 2024 (9.5M rows, 3 months, Parquet) |
| iceberg_nyc   | Iceberg REST | NYC taxi Iceberg table (MinIO-backed)             |
| hive_lakefs   | Hive         | NYC taxi via LakeFS (main + dev branches)         |
| fileset_nyc   | Fileset      | NYC taxi file governance                          |
| glue_demo     | Glue         | AWS Glue catalog (requires AWS credentials)       |

## Credentials

| Service              | Username            | Password               |
|----------------------|---------------------|------------------------|
| Gravitino            | `gravitino`         | `gravitino`            |
| Trino                | `admin`             | *(none)*               |
| MinIO                | `gravitino`         | `gravitino123`         |
| LakeFS               | `gravitino-lakefs-key` | `gravitino-lakefs-secret` |
| CloudBeaver          | `cbadmin`           | `Admin1234`            |
| PostgreSQL superuser | `postgres`          | `postgres`             |

## Make targets

```
make up          # Clean start — rebuilds changed images, resets postgres volume
make up-quick    # Start without rebuilding or resetting volumes
make down        # Stop all containers
make build       # Force rebuild all images ignoring cache
make spark-sql   # Spark SQL shell via Gravitino
make trino-sql   # Trino CLI via Gravitino
make psql        # psql on demo_data (postgres superuser)
make logs        # Tail all service logs
make logs-svc SVC=gravitino   # Tail a specific service
make clean       # Remove all containers and volumes
make reset       # clean + prune dangling images
```

## Notes

* First startup downloads 3 months of NYC taxi data (~150MB) and loads them into Iceberg (~5 min total)
* Iceberg data is stored in MinIO — if you run `make clean`, the Iceberg table reloads automatically on next `make up`
* HMS uses Derby (embedded) for metastore — metadata persists in Docker volumes
* WSL2 users: all services communicate via the `gqsnet` Docker network
* AWS Glue catalog requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `GLUE_WAREHOUSE` environment variables

---

## Natural Language Queries with Claude (MCP)

Query your data using plain English via Claude and MCP. Two independent modes are available — set up only the one you need.

| Mode          | What it does                                      | Additional servers needed  |
|---------------|---------------------------------------------------|----------------------------|
| `sql`         | NL → Claude → SQL → Trino → Gravitino            | Trino MCP only             |
| `metricflow`  | NL → Claude → MetricFlow → Gravitino             | Trino MCP + MetricFlow MCP |

The Gravitino MCP server runs automatically as part of the Docker stack (`gqs-gravitino-mcp`) on port 8001 — no setup needed for it.

---

### One-time setup

Run this once after cloning to install `uv` and the `mcp-trino` binary:

```
./mcp/setup-mcp.sh
```

Make sure `~/.local/bin` is in your PATH:

```
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc && source ~/.bashrc
```

For `metricflow` mode, also clone:

```
git clone https://github.com/markhoerth/gravitino-semantic-layer-quickstart ~/gravitino-semantic-layer-quickstart
```

---

### SQL mode

Start the Trino MCP server in the background:

```
./mcp/start-mcp-sql.sh
```

Start the app:

```
export ANTHROPIC_API_KEY=sk-ant-...
./mcp/start-app.sh sql
```

Try it:

```
What catalogs are available in Gravitino?
What tables are in the iceberg_nyc catalog?
What's the average fare and trip distance by vendor?
What were the top 5 busiest pickup locations by number of trips?
Show me all flagged transactions for high-risk customers.
How many trips had a fare above $50?
```

---

### MetricFlow mode

```
./mcp/start-mcp-metricflow.sh
export ANTHROPIC_API_KEY=sk-ant-...
./mcp/start-app.sh metricflow
```

Try it:

```
What governed metrics are available?
What's the total number of trips by vendor?
What is the average fare across all trips?
```

---

### Stop MCP servers

```
./mcp/stop-mcp.sh
```

Trino MCP logs are written to `mcp/logs/`. For Gravitino MCP logs:

```
make logs-svc SVC=gravitino-mcp
```
