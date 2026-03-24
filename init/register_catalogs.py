"""Register all Gravitino catalogs for the quickstart."""
import requests
import sys

BASE = "http://gravitino:8090"
METALAKE = "demo"

def post(path, data):
    r = requests.post(f"{BASE}{path}", json=data)
    if r.status_code == 200:
        print(f"[ok] {path}")
    elif r.status_code == 409:
        print(f"[exists] {path}")
    else:
        print(f"[warn] {r.status_code}: {r.text[:200]}")

# PostgreSQL catalog (ADP financial services)
post(f"/api/metalakes/{METALAKE}/catalogs", {
    "name": "postgres_demo",
    "type": "RELATIONAL",
    "provider": "jdbc-postgresql",
    "comment": "Demo PostgreSQL catalog",
    "properties": {
        "jdbc-url": "jdbc:postgresql://postgres:5432/demo_data",
        "jdbc-database": "demo_data",
        "jdbc-user": "gravitino",
        "jdbc-password": "gravitino",
        "jdbc-driver": "org.postgresql.Driver"
    }
})

# Hive catalog (NYC taxi via HMS)
post(f"/api/metalakes/{METALAKE}/catalogs", {
    "name": "hive_nyc",
    "type": "RELATIONAL",
    "provider": "hive",
    "comment": "NYC taxi data via Hive",
    "properties": {
        "metastore.uris": "thrift://hms:9083",
        "gravitino.bypass.hive.metastore.client.capability.check": "false"
    }
})

# Iceberg catalog (NYC taxi queryable)
post(f"/api/metalakes/{METALAKE}/catalogs", {
    "name": "iceberg_nyc",
    "type": "RELATIONAL",
    "provider": "lakehouse-iceberg",
    "comment": "NYC taxi Iceberg catalog",
    "properties": {
        "catalog-backend": "jdbc",
        "uri": "jdbc:postgresql://postgres:5432/iceberg_catalog",
        "jdbc-driver": "org.postgresql.Driver",
        "jdbc-user": "gravitino",
        "jdbc-password": "gravitino",
        "jdbc-initialize": "true",
        "warehouse": "/data/iceberg"
    }
})

# Fileset catalog (NYC taxi file governance)
post(f"/api/metalakes/{METALAKE}/catalogs", {
    "name": "fileset_nyc",
    "type": "FILESET",
    "provider": "hadoop",
    "comment": "NYC taxi Parquet files - governance layer",
    "properties": {
        "location": "file:///data/nyc_taxi"
    }
})

print("Catalog registration complete.")
