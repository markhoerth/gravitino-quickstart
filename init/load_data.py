"""Load demo data into PostgreSQL and register Iceberg tables."""
import pyarrow.parquet as pq
import psycopg2
from psycopg2.extras import execute_values
import os
import requests

print("Loading ADP financial services data...")

conn = psycopg2.connect(
    host='postgres', port=5432,
    dbname='demo_data',
    user='gravitino', password='gravitino'
)
cur = conn.cursor()

# Create customers table
cur.execute("""
    CREATE TABLE IF NOT EXISTS customers (
        account_number   TEXT PRIMARY KEY,
        customer_name    TEXT NOT NULL,
        region           TEXT NOT NULL,
        account_status   TEXT NOT NULL,
        opened_at        TIMESTAMPTZ NOT NULL,
        risk_rating      TEXT NOT NULL
    )
""")

# Create transactions table  
cur.execute("""
    CREATE TABLE IF NOT EXISTS transactions (
        transaction_id      TEXT PRIMARY KEY,
        account_number      TEXT NOT NULL,
        customer_name       TEXT NOT NULL,
        transaction_date    TIMESTAMPTZ NOT NULL,
        amount_cad          NUMERIC(12,2) NOT NULL,
        transaction_type    TEXT NOT NULL,
        status              TEXT NOT NULL,
        flagged_for_review  BOOLEAN DEFAULT FALSE
    )
""")

# Insert sample customers
cur.execute("SELECT COUNT(*) FROM customers")
if cur.fetchone()[0] == 0:
    customers = [
        ('ACC-1001', 'Margaret Tran',    'ONTARIO',  'ACTIVE',    '2018-03-12', 'LOW'),
        ('ACC-1002', 'David Okafor',     'QUEBEC',   'ACTIVE',    '2019-07-22', 'LOW'),
        ('ACC-1003', 'Priya Nair',       'WESTERN',  'ACTIVE',    '2020-01-05', 'MEDIUM'),
        ('ACC-1004', 'James Whitfield',  'ONTARIO',  'SUSPENDED', '2016-11-30', 'HIGH'),
        ('ACC-1005', 'Sofia Reyes',      'ATLANTIC', 'ACTIVE',    '2021-06-18', 'LOW'),
        ('ACC-1006', 'Chen Wei',         'ONTARIO',  'ACTIVE',    '2022-02-28', 'MEDIUM'),
        ('ACC-1007', 'Amara Diallo',     'ONTARIO',  'ACTIVE',    '2017-09-14', 'LOW'),
        ('ACC-1008', 'Robert Kowalski',  'WESTERN',  'CLOSED',    '2015-04-01', 'LOW'),
        ('ACC-1009', 'Fatima Al-Hassan', 'QUEBEC',   'ACTIVE',    '2023-05-10', 'HIGH'),
        ('ACC-1010', 'Liam Nguyen',      'ONTARIO',  'ACTIVE',    '2019-12-20', 'CRITICAL'),
    ]
    execute_values(cur,
        "INSERT INTO customers VALUES %s",
        customers
    )
    print(f"[ok] Loaded {len(customers)} customers")

conn.commit()
cur.close()
conn.close()
print("Demo data loaded.")

# Register fileset schema
print("Registering fileset schema...")
r = requests.post(
    "http://gravitino:8090/api/metalakes/demo/catalogs/fileset_nyc/schemas",
    json={"name": "nyc_taxi", "comment": "NYC Yellow Taxi 2024"}
)
if r.status_code in (200, 409):
    print("[ok] Fileset schema registered")

# Register fileset
r = requests.post(
    "http://gravitino:8090/api/metalakes/demo/catalogs/fileset_nyc/schemas/nyc_taxi/filesets",
    json={
        "name": "yellow_trips_2024",
        "comment": "NYC Yellow Taxi trips 2024 - Parquet files",
        "type": "EXTERNAL",
        "storageLocation": "file:///data/nyc_taxi"
    }
)
if r.status_code in (200, 409):
    print("[ok] Fileset registered")

print("Init complete.")
