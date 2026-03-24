#!/bin/bash
set -e

echo "=== Gravitino Quickstart Init ==="

# Wait for Gravitino
echo "Waiting for Gravitino..."
until curl -sf http://gravitino:8090/api/version > /dev/null; do
    sleep 2
done
echo "Gravitino ready."

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
until pg_isready -h postgres -U postgres > /dev/null 2>&1; do
    sleep 2
done
echo "PostgreSQL ready."

# Wait for Trino
echo "Waiting for Trino..."
until curl -sf http://trino:8082/v1/info > /dev/null; do
    sleep 2
done
echo "Trino ready."

# Create metalake
echo "Creating metalake..."
curl -sf -X POST http://gravitino:8090/api/metalakes \
  -H 'Content-Type: application/json' \
  -d '{"name": "demo", "comment": "Gravitino Quickstart Demo"}' || true

# Register catalogs
echo "Registering catalogs..."
python /register_catalogs.py

# Download NYC taxi data if not present
if [ ! -f /data/nyc_taxi/yellow_tripdata_2024-01.parquet ]; then
    echo "Downloading NYC taxi data (3 months)..."
    mkdir -p /data/nyc_taxi
    for month in 01 02 03; do
        echo "  Downloading 2024-${month}..."
        curl -L "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-${month}.parquet" \
             -o "/data/nyc_taxi/yellow_tripdata_2024-${month}.parquet"
    done
    echo "NYC taxi data downloaded."
else
    echo "NYC taxi data already present."
fi

# Load data
echo "Loading demo data..."
python /load_data.py

echo "=== Init complete ==="
