# Gravitino Quickstart

One-command Gravitino data platform for POCs and developer evaluation.

## What you get

| Service | URL | Description |
|---------|-----|-------------|
| Gravitino | http://localhost:8090 | Metadata catalog + governance (V2 UI) |
| Trino | http://localhost:8082 | SQL query engine |
| CloudBeaver | http://localhost:8978 | Web SQL IDE |
| Airflow | http://localhost:8083 | Pipeline orchestration |

## Quickstart
```bash
# 1. Build (downloads connector on first run)
./build.sh

# 2. Start
docker-compose up -d

# 3. Wait ~2 minutes, then query
docker exec -it gqs-trino trino --server http://localhost:8082
```

## Interactive Trino shell
```sql
SHOW CATALOGS;
SELECT count(*) FROM postgres_demo.public.customers;
SELECT count(*) FROM hive_nyc.nyc_taxi.yellow_trips;
SELECT avg(total_amount), avg(trip_distance) FROM hive_nyc.nyc_taxi.yellow_trips;
```

## Catalogs

| Catalog | Type | Data |
|---------|------|------|
| postgres_demo | PostgreSQL | ADP financial services demo |
| hive_nyc | Hive | NYC Yellow Taxi 2024 (9.5M rows, 3 months) |
| iceberg_nyc | Iceberg | NYC taxi Iceberg catalog |
| fileset_nyc | Fileset | NYC taxi file governance |

## Credentials

All services: `gravitino` / `gravitino`  
PostgreSQL superuser: `postgres` / `postgres`  
Trino: username `admin`, no password

## Notes

- First startup downloads 3 months of NYC taxi data (~150MB)
- HMS uses Derby (embedded) for metastore — data persists in Docker volumes
- WSL2 users: all services communicate via the `gqsnet` Docker network
