# Gravitino Quickstart

A complete local Gravitino data platform for POCs and developer evaluation. One command to start — includes federated metadata, SQL query engines, a web SQL IDE, and natural language querying via Claude and MCP.

## What you get

| Service | URL | Description |
|---------|-----|-------------|
| Gravitino | http://localhost:8090 | Federated metadata catalog + governance (V2 UI) |
| Trino | http://localhost:8082 | SQL query engine |
| Spark SQL | `make spark-sql` | Spark SQL shell via Gravitino connector |
| CloudBeaver | http://localhost:8978 | Web SQL IDE |
| MinIO | http://localhost:9002 | S3-compatible object storage (Iceberg data) |
| LakeFS | http://localhost:8000 | Git-for-data branching layer |
| Airflow | http://localhost:8083 | Workflow orchestration |

## Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- 8GB RAM available to Docker
- ~10GB disk space (base images + 150MB NYC taxi data download on first run)

## Quickstart

```bash
git clone https://github.com/markhoerth/gravitino-quickstart.git
cd gravitino-quickstart
make up
```

`make up` builds all images and starts all services. Init runs automatically — it downloads NYC taxi data, registers catalogs, and loads ~9.5M rows into Iceberg. **Allow ~5 minutes for full initialization.**

Watch init progress:
```bash
make logs-svc SVC=init
```

## Query with Trino

```bash
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

```bash
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

| Catalog | Type | Data |
|---------|------|------|
| postgres_demo | PostgreSQL | Financial services demo (customers, transactions) |
| hive_nyc | Hive | NYC Yellow Taxi 2024 (9.5M rows, 3 months, Parquet) |
| iceberg_nyc | Iceberg REST | NYC taxi Iceberg table (MinIO-backed) |
| hive_lakefs | Hive | NYC taxi via LakeFS (main + dev branches) |
| fileset_nyc | Fileset | NYC taxi file governance |
| glue_demo | Glue | AWS Glue catalog (requires AWS credentials) |

## Credentials

| Service | Username | Password |
|---------|----------|----------|
| Gravitino / Trino / MinIO / LakeFS | `gravitino` | `gravitino` |
| PostgreSQL superuser | `postgres` | `postgres` |
| Trino | `admin` | *(none)* |
| Airflow | `admin` | `admin` |

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

- First startup downloads 3 months of NYC taxi data (~150MB) and loads them into Iceberg (~5 min total)
- Iceberg data is stored in MinIO — if you run `make clean`, the Iceberg table reloads automatically on next `make up`
- HMS uses Derby (embedded) for metastore — metadata persists in Docker volumes
- WSL2 users: all services communicate via the `gqsnet` Docker network
- AWS Glue catalog requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `GLUE_WAREHOUSE` environment variables

---

## Natural Language Queries with Claude (MCP)

Query your data using plain English via Claude and MCP. Two independent modes are available — set up only the one you need.

| Mode | What it does | MCP servers |
|------|-------------|-------------|
| `sql` | NL → Claude → SQL → Trino → Gravitino | Gravitino MCP + Trino MCP |
| `metricflow` | NL → Claude → MetricFlow → Gravitino | Gravitino MCP + Trino MCP + MetricFlow MCP |

### One-time setup

Run this once after cloning to install the `mcp-trino` binary and set up Python venvs:

```bash
./mcp/setup-mcp.sh
```

This installs `mcp-trino` v4.3.1 (tuannvm/mcp-trino) to `~/.local/bin` and sets up the app venv. Make sure `~/.local/bin` is in your PATH:

```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc && source ~/.bashrc
```

The Gravitino MCP server must be cloned separately:

```bash
git clone https://github.com/datastrato/mcp-server-gravitino ~/git/mcp-server-gravitino
```

Then re-run `./mcp/setup-mcp.sh` to set up its venv.

For `metricflow` mode, also clone:

```bash
git clone https://github.com/markhoerth/gravitino-semantic-layer-quickstart ~/gravitino-semantic-layer-quickstart
```

---

### SQL mode

Start MCP servers in the background (no extra terminals needed):

```bash
./mcp/start-mcp-sql.sh
```

Start the app:

```bash
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

```bash
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

```bash
./mcp/stop-mcp.sh
```

Logs for all MCP servers are written to `mcp/logs/`.
