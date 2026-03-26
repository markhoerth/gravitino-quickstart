#!/bin/bash
set -e

echo "=== Gravitino Quickstart Init ==="

# Wait for Gravitino
echo "Waiting for Gravitino..."
until curl -sf http://gravitino:8090/api/version > /dev/null; do
    sleep 2
done
echo "Gravitino ready."

# Wait for LakeFS
echo "Waiting for LakeFS..."
until curl -sf http://gqs-lakefs:8000/api/v1/healthcheck > /dev/null 2>&1; do
    sleep 2
done
echo "LakeFS ready."

# Create MinIO bucket for LakeFS storage
echo "Creating LakeFS storage bucket..."
AWS_ACCESS_KEY_ID=gravitino \
AWS_SECRET_ACCESS_KEY=gravitino123 \
aws --endpoint-url http://gqs-minio:9000 \
    s3 mb s3://lakefs --region us-east-1 2>/dev/null || true
echo "LakeFS bucket ready."

# Setup LakeFS first user
echo "Setting up LakeFS..."
curl -sf -X POST http://gqs-lakefs:8000/api/v1/setup_lakefs \
  -H "Content-Type: application/json" \
  -d '{
    "username": "gravitino",
    "key": {
      "access_key_id": "gravitino-lakefs-key",
      "secret_access_key": "gravitino-lakefs-secret"
    }
  }' || true

# Create LakeFS quickstart repository
echo "Creating LakeFS repository..."
curl -sf -X POST http://gqs-lakefs:8000/api/v1/repositories \
  -H "Authorization: Basic $(echo -n 'gravitino-lakefs-key:gravitino-lakefs-secret' | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "quickstart",
    "storage_namespace": "s3://lakefs/quickstart",
    "default_branch": "main"
  }' || true

# Create dev branch
echo "Creating LakeFS dev branch..."
curl -sf -X POST http://gqs-lakefs:8000/api/v1/repositories/quickstart/branches \
  -H "Authorization: Basic $(echo -n 'gravitino-lakefs-key:gravitino-lakefs-secret' | base64)" \
  -H "Content-Type: application/json" \
  -d '{"name": "dev", "source": "main"}' || true

echo "LakeFS initialized."

# Wait for HMS (thrift port 9083) — must be up before we can register tables via Trino
echo "Waiting for HMS..."
until bash -c 'echo >/dev/tcp/gqs-hms/9083' 2>/dev/null; do
    sleep 3
done
echo "HMS ready."

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

# ── LakeFS: upload taxi data to main branch ──────────────────────────────────
# Uploads go to the LakeFS staging area via its S3-compatible gateway.
# LakeFS path format: s3://<repo>/<branch>/<path>
# After upload we commit to make the data addressable by HMS.
echo "Uploading NYC taxi data to LakeFS main branch..."

LAKEFS_AUTH="gravitino-lakefs-key:gravitino-lakefs-secret"

# Upload Jan 2024 (main branch — will be the "production" snapshot)
AWS_ACCESS_KEY_ID=gravitino-lakefs-key \
AWS_SECRET_ACCESS_KEY=gravitino-lakefs-secret \
aws --endpoint-url http://gqs-lakefs:8000 \
    s3 cp /data/nyc_taxi/yellow_tripdata_2024-01.parquet \
          s3://quickstart/main/data/yellow_tripdata_2024-01.parquet \
    --region us-east-1 2>&1 || true

# Upload Feb + Mar to main if they exist (gives different row count from dev)
for month in 02 03; do
    if [ -f "/data/nyc_taxi/yellow_tripdata_2024-${month}.parquet" ]; then
        AWS_ACCESS_KEY_ID=gravitino-lakefs-key \
        AWS_SECRET_ACCESS_KEY=gravitino-lakefs-secret \
        aws --endpoint-url http://gqs-lakefs:8000 \
            s3 cp "/data/nyc_taxi/yellow_tripdata_2024-${month}.parquet" \
                  "s3://quickstart/main/data/yellow_tripdata_2024-${month}.parquet" \
            --region us-east-1 2>&1 || true
    fi
done

# Commit main branch — makes staged files part of the branch snapshot
echo "Committing LakeFS main branch..."
curl -sf -X POST "http://gqs-lakefs:8000/api/v1/repositories/quickstart/branches/main/commits" \
  -H "Authorization: Basic $(echo -n "${LAKEFS_AUTH}" | base64)" \
  -H "Content-Type: application/json" \
  -d '{"message": "Add NYC Yellow Taxi 2024 data", "metadata": {}}' || true

# Upload Jan data to dev branch too (gives same schema, allows HMS path to exist)
# In the demo, you'd show branching by modifying dev data after this point
AWS_ACCESS_KEY_ID=gravitino-lakefs-key \
AWS_SECRET_ACCESS_KEY=gravitino-lakefs-secret \
aws --endpoint-url http://gqs-lakefs:8000 \
    s3 cp /data/nyc_taxi/yellow_tripdata_2024-01.parquet \
          s3://quickstart/dev/data/yellow_tripdata_2024-01.parquet \
    --region us-east-1 2>&1 || true

curl -sf -X POST "http://gqs-lakefs:8000/api/v1/repositories/quickstart/branches/dev/commits" \
  -H "Authorization: Basic $(echo -n "${LAKEFS_AUTH}" | base64)" \
  -H "Content-Type: application/json" \
  -d '{"message": "Add NYC Yellow Taxi Jan 2024 to dev branch", "metadata": {}}' || true

echo "LakeFS data upload complete."
# ─────────────────────────────────────────────────────────────────────────────

# Load data (PostgreSQL ADP data + Hive/Iceberg/LakeFS HMS tables)
echo "Loading demo data..."
python /load_data.py

echo "=== Init complete ==="
