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

# Insert sample transactions
cur.execute("SELECT COUNT(*) FROM transactions")
if cur.fetchone()[0] == 0:
    transactions = [
        # Margaret Tran (ACC-1001, LOW risk, ONTARIO, ACTIVE)
        ('TXN-0001', 'ACC-1001', 'Margaret Tran', '2025-10-03 09:14:00-04', 1250.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0002', 'ACC-1001', 'Margaret Tran', '2025-10-15 14:32:00-04', 89.50,    'PURCHASE',        'COMPLETED',  False),
        ('TXN-0003', 'ACC-1001', 'Margaret Tran', '2025-11-01 11:05:00-04', 3200.00,  'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0004', 'ACC-1001', 'Margaret Tran', '2025-11-22 16:45:00-04', 450.75,   'BILL_PAYMENT',    'COMPLETED',  False),
        ('TXN-0005', 'ACC-1001', 'Margaret Tran', '2025-12-10 08:20:00-04', 675.00,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0006', 'ACC-1001', 'Margaret Tran', '2026-01-08 10:00:00-04', 5000.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0007', 'ACC-1001', 'Margaret Tran', '2026-02-14 13:30:00-04', 120.25,   'PURCHASE',        'COMPLETED',  False),
        # David Okafor (ACC-1002, LOW risk, QUEBEC, ACTIVE)
        ('TXN-0008', 'ACC-1002', 'David Okafor',  '2025-10-07 10:00:00-04', 780.00,   'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0009', 'ACC-1002', 'David Okafor',  '2025-10-19 15:20:00-04', 345.60,   'BILL_PAYMENT',    'COMPLETED',  False),
        ('TXN-0010', 'ACC-1002', 'David Okafor',  '2025-11-05 09:45:00-04', 2100.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0011', 'ACC-1002', 'David Okafor',  '2025-12-01 14:10:00-04', 55.99,    'PURCHASE',        'COMPLETED',  False),
        ('TXN-0012', 'ACC-1002', 'David Okafor',  '2026-01-20 11:30:00-04', 1800.00,  'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0013', 'ACC-1002', 'David Okafor',  '2026-02-28 16:00:00-04', 430.00,   'BILL_PAYMENT',    'COMPLETED',  False),
        # Priya Nair (ACC-1003, MEDIUM risk, WESTERN, ACTIVE)
        ('TXN-0014', 'ACC-1003', 'Priya Nair',    '2025-10-11 08:30:00-07', 9500.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0015', 'ACC-1003', 'Priya Nair',    '2025-10-25 12:15:00-07', 320.40,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0016', 'ACC-1003', 'Priya Nair',    '2025-11-14 09:00:00-07', 15000.00, 'WIRE_TRANSFER',   'UNDER_REVIEW', True),
        ('TXN-0017', 'ACC-1003', 'Priya Nair',    '2025-12-03 14:50:00-07', 870.00,   'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0018', 'ACC-1003', 'Priya Nair',    '2026-01-15 10:20:00-07', 4400.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0019', 'ACC-1003', 'Priya Nair',    '2026-02-09 15:35:00-07', 210.00,   'PURCHASE',        'COMPLETED',  False),
        # James Whitfield (ACC-1004, HIGH risk, ONTARIO, SUSPENDED)
        ('TXN-0020', 'ACC-1004', 'James Whitfield', '2025-10-02 09:00:00-04', 25000.00, 'WIRE_TRANSFER', 'BLOCKED',    True),
        ('TXN-0021', 'ACC-1004', 'James Whitfield', '2025-10-02 09:05:00-04', 25000.00, 'WIRE_TRANSFER', 'BLOCKED',    True),
        ('TXN-0022', 'ACC-1004', 'James Whitfield', '2025-10-18 11:30:00-04', 8750.00,  'WITHDRAWAL',    'BLOCKED',    True),
        ('TXN-0023', 'ACC-1004', 'James Whitfield', '2025-11-07 14:00:00-04', 500.00,   'PURCHASE',      'DECLINED',   True),
        ('TXN-0024', 'ACC-1004', 'James Whitfield', '2026-01-03 10:15:00-04', 12000.00, 'WIRE_TRANSFER', 'BLOCKED',    True),
        # Sofia Reyes (ACC-1005, LOW risk, ATLANTIC, ACTIVE)
        ('TXN-0025', 'ACC-1005', 'Sofia Reyes',   '2025-10-06 13:00:00-03', 540.00,   'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0026', 'ACC-1005', 'Sofia Reyes',   '2025-10-20 10:45:00-03', 78.30,    'PURCHASE',        'COMPLETED',  False),
        ('TXN-0027', 'ACC-1005', 'Sofia Reyes',   '2025-11-10 15:20:00-03', 1100.00,  'BILL_PAYMENT',    'COMPLETED',  False),
        ('TXN-0028', 'ACC-1005', 'Sofia Reyes',   '2025-12-05 09:10:00-03', 2300.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0029', 'ACC-1005', 'Sofia Reyes',   '2026-01-22 14:00:00-03', 190.50,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0030', 'ACC-1005', 'Sofia Reyes',   '2026-02-18 11:30:00-03', 660.00,   'DEPOSIT',         'COMPLETED',  False),
        # Chen Wei (ACC-1006, MEDIUM risk, ONTARIO, ACTIVE)
        ('TXN-0031', 'ACC-1006', 'Chen Wei',      '2025-10-09 10:30:00-04', 4200.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0032', 'ACC-1006', 'Chen Wei',      '2025-10-23 14:00:00-04', 890.00,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0033', 'ACC-1006', 'Chen Wei',      '2025-11-12 09:20:00-04', 18500.00, 'WIRE_TRANSFER',   'UNDER_REVIEW', True),
        ('TXN-0034', 'ACC-1006', 'Chen Wei',      '2025-11-30 16:10:00-04', 1500.00,  'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0035', 'ACC-1006', 'Chen Wei',      '2025-12-18 11:45:00-04', 3300.00,  'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0036', 'ACC-1006', 'Chen Wei',      '2026-01-14 13:00:00-04', 720.00,   'BILL_PAYMENT',    'COMPLETED',  False),
        ('TXN-0037', 'ACC-1006', 'Chen Wei',      '2026-02-25 10:15:00-04', 240.00,   'PURCHASE',        'COMPLETED',  False),
        # Amara Diallo (ACC-1007, LOW risk, ONTARIO, ACTIVE)
        ('TXN-0038', 'ACC-1007', 'Amara Diallo',  '2025-10-14 09:00:00-04', 1650.00,  'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0039', 'ACC-1007', 'Amara Diallo',  '2025-10-28 15:30:00-04', 430.20,   'BILL_PAYMENT',    'COMPLETED',  False),
        ('TXN-0040', 'ACC-1007', 'Amara Diallo',  '2025-11-18 10:45:00-04', 960.00,   'WIRE_TRANSFER',   'COMPLETED',  False),
        ('TXN-0041', 'ACC-1007', 'Amara Diallo',  '2025-12-08 14:20:00-04', 115.75,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0042', 'ACC-1007', 'Amara Diallo',  '2026-01-27 09:50:00-04', 2800.00,  'DEPOSIT',         'COMPLETED',  False),
        ('TXN-0043', 'ACC-1007', 'Amara Diallo',  '2026-02-12 13:00:00-04', 380.00,   'BILL_PAYMENT',    'COMPLETED',  False),
        # Robert Kowalski (ACC-1008, LOW risk, WESTERN, CLOSED)
        ('TXN-0044', 'ACC-1008', 'Robert Kowalski', '2025-10-01 10:00:00-07', 200.00,  'WITHDRAWAL',     'COMPLETED',  False),
        ('TXN-0045', 'ACC-1008', 'Robert Kowalski', '2025-10-01 10:05:00-07', 1840.55, 'WITHDRAWAL',     'COMPLETED',  False),
        ('TXN-0046', 'ACC-1008', 'Robert Kowalski', '2025-10-02 09:00:00-07', 12500.00,'WIRE_TRANSFER',  'COMPLETED',  False),
        # Account closed after above — subsequent attempts declined
        ('TXN-0047', 'ACC-1008', 'Robert Kowalski', '2025-11-15 11:30:00-07', 500.00,  'PURCHASE',       'DECLINED',   False),
        # Fatima Al-Hassan (ACC-1009, HIGH risk, QUEBEC, ACTIVE)
        ('TXN-0048', 'ACC-1009', 'Fatima Al-Hassan', '2025-10-05 09:30:00-04', 32000.00, 'WIRE_TRANSFER','UNDER_REVIEW', True),
        ('TXN-0049', 'ACC-1009', 'Fatima Al-Hassan', '2025-10-05 09:45:00-04', 32000.00, 'WIRE_TRANSFER','BLOCKED',    True),
        ('TXN-0050', 'ACC-1009', 'Fatima Al-Hassan', '2025-10-17 14:00:00-04', 7500.00,  'WITHDRAWAL',   'UNDER_REVIEW', True),
        ('TXN-0051', 'ACC-1009', 'Fatima Al-Hassan', '2025-11-08 10:15:00-04', 450.00,   'PURCHASE',     'COMPLETED',  False),
        ('TXN-0052', 'ACC-1009', 'Fatima Al-Hassan', '2025-12-20 16:30:00-04', 41000.00, 'WIRE_TRANSFER','BLOCKED',    True),
        ('TXN-0053', 'ACC-1009', 'Fatima Al-Hassan', '2026-01-10 09:00:00-04', 890.00,   'BILL_PAYMENT', 'COMPLETED',  False),
        ('TXN-0054', 'ACC-1009', 'Fatima Al-Hassan', '2026-02-03 13:45:00-04', 28000.00, 'WIRE_TRANSFER','UNDER_REVIEW', True),
        # Liam Nguyen (ACC-1010, CRITICAL risk, ONTARIO, ACTIVE)
        ('TXN-0055', 'ACC-1010', 'Liam Nguyen',   '2025-10-04 08:00:00-04', 75000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0056', 'ACC-1010', 'Liam Nguyen',   '2025-10-04 08:02:00-04', 75000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0057', 'ACC-1010', 'Liam Nguyen',   '2025-10-11 11:00:00-04', 48000.00, 'WITHDRAWAL',      'BLOCKED',    True),
        ('TXN-0058', 'ACC-1010', 'Liam Nguyen',   '2025-10-29 14:30:00-04', 92000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0059', 'ACC-1010', 'Liam Nguyen',   '2025-11-03 09:15:00-04', 320.00,   'PURCHASE',        'COMPLETED',  False),
        ('TXN-0060', 'ACC-1010', 'Liam Nguyen',   '2025-11-20 15:00:00-04', 55000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0061', 'ACC-1010', 'Liam Nguyen',   '2025-12-12 10:45:00-04', 67000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0062', 'ACC-1010', 'Liam Nguyen',   '2026-01-06 08:30:00-04', 83000.00, 'WIRE_TRANSFER',   'BLOCKED',    True),
        ('TXN-0063', 'ACC-1010', 'Liam Nguyen',   '2026-02-01 13:00:00-04', 41000.00, 'WIRE_TRANSFER',   'UNDER_REVIEW', True),
    ]
    execute_values(cur,
        "INSERT INTO transactions VALUES %s",
        transactions
    )
    print(f"[ok] Loaded {len(transactions)} transactions")

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

# Initialize Hive schema and table for NYC taxi data
import trino
import time

# Poll until hive_nyc catalog is visible in Trino (Gravitino connector may lag)
print("Waiting for Trino catalogs to load from Gravitino...")
for attempt in range(30):
    try:
        _conn = trino.dbapi.connect(host='trino', port=8082, user='admin')
        _cur = _conn.cursor()
        _cur.execute("SHOW CATALOGS")
        catalogs = [row[0] for row in _cur.fetchall()]
        _cur.close()
        _conn.close()
        if 'hive_nyc' in catalogs and 'iceberg_nyc' in catalogs:
            print(f"[ok] hive_nyc and iceberg_nyc catalogs visible after {attempt * 2}s")
            break
        missing = [c for c in ['hive_nyc', 'iceberg_nyc'] if c not in catalogs]
        print(f"  waiting for catalogs {missing}... ({attempt * 2}s)")
    except Exception as e:
        print(f"  Trino not ready yet: {e}")
    time.sleep(2)
else:
    print("[warn] hive_nyc catalog never appeared — Hive init may fail")

print("Initializing Hive NYC taxi schema and table...")

def run_trino(sql, description):
    conn = trino.dbapi.connect(host='trino', port=8082, user='admin')
    cur = conn.cursor()
    try:
        cur.execute(sql)
        cur.fetchall()  # consume result
        print(f"[ok] {description}")
    except Exception as e:
        if 'already exists' in str(e).lower():
            print(f"[skip] {description} (already exists)")
        else:
            print(f"[warn] {description}: {e}")
    finally:
        cur.close()
        conn.close()

run_trino(
    "CREATE SCHEMA IF NOT EXISTS hive_nyc.nyc_taxi "
    "WITH (location = 'file:///data/nyc_taxi')",
    "Hive schema hive_nyc.nyc_taxi"
)

run_trino("""
    CREATE TABLE IF NOT EXISTS hive_nyc.nyc_taxi.yellow_trips (
        VendorID              integer,
        tpep_pickup_datetime  timestamp(3),
        tpep_dropoff_datetime timestamp(3),
        passenger_count       bigint,
        trip_distance         double,
        RatecodeID            bigint,
        store_and_fwd_flag    varchar,
        PULocationID          integer,
        DOLocationID          integer,
        payment_type          bigint,
        fare_amount           double,
        extra                 double,
        mta_tax               double,
        tip_amount            double,
        tolls_amount          double,
        improvement_surcharge double,
        total_amount          double,
        congestion_surcharge  double,
        Airport_fee           double
    ) WITH (
        location = 'file:///data/nyc_taxi',
        format = 'PARQUET'
    )
""", "Hive table hive_nyc.nyc_taxi.yellow_trips")

print("Hive init complete.")

# Initialize Iceberg table via Trino → Gravitino REST server → MinIO
print("Initializing Iceberg NYC taxi schema and table...")

run_trino(
    "CREATE SCHEMA IF NOT EXISTS iceberg_nyc.nyc_taxi",
    "Iceberg schema iceberg_nyc.nyc_taxi"
)

run_trino("""
    CREATE TABLE IF NOT EXISTS iceberg_nyc.nyc_taxi.yellow_trips (
        VendorID              integer,
        tpep_pickup_datetime  timestamp(3),
        tpep_dropoff_datetime timestamp(3),
        passenger_count       bigint,
        trip_distance         double,
        RatecodeID            bigint,
        store_and_fwd_flag    varchar,
        PULocationID          integer,
        DOLocationID          integer,
        payment_type          bigint,
        fare_amount           double,
        extra                 double,
        mta_tax               double,
        tip_amount            double,
        tolls_amount          double,
        improvement_surcharge double,
        total_amount          double,
        congestion_surcharge  double,
        Airport_fee           double
    )
""", "Iceberg table iceberg_nyc.nyc_taxi.yellow_trips")

# Check if already populated
def trino_query(sql):
    conn = trino.dbapi.connect(host='trino', port=8082, user='admin')
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

try:
    rows = trino_query("SELECT count(*) FROM iceberg_nyc.nyc_taxi.yellow_trips")
    count = rows[0][0]
    if count > 0:
        print(f"[skip] Iceberg table already populated ({count:,} rows)")
    else:
        print("Loading Iceberg table via INSERT INTO ... SELECT (9.5M rows, ~3-5 min)...")
        run_trino(
            "INSERT INTO iceberg_nyc.nyc_taxi.yellow_trips "
            "SELECT * FROM hive_nyc.nyc_taxi.yellow_trips",
            "Iceberg INSERT iceberg_nyc.nyc_taxi.yellow_trips"
        )
except Exception as e:
    print(f"[warn] Iceberg load check failed: {e}")

print("Iceberg init complete.")

# ── LakeFS HMS: create schemas and external tables per branch ─────────────────
# The hive_lakefs catalog federates two HMS schemas:
#   lakefs_main  →  s3a://quickstart/main/data/   (production snapshot)
#   lakefs_dev   →  s3a://quickstart/dev/data/    (isolated dev branch)
#
# Tables are EXTERNAL — the data lives in LakeFS, HMS just holds the metadata.
# HMS talks to LakeFS via the S3A filesystem wired in hive-site.xml.

print("Initializing LakeFS HMS schemas and tables...")

# Poll until hive_lakefs catalog is visible in Trino
for attempt in range(30):
    try:
        _conn = trino.dbapi.connect(host='trino', port=8082, user='admin')
        _cur = _conn.cursor()
        _cur.execute("SHOW CATALOGS")
        catalogs = [row[0] for row in _cur.fetchall()]
        _cur.close()
        _conn.close()
        if 'hive_lakefs' in catalogs:
            print(f"[ok] hive_lakefs catalog visible after {attempt * 2}s")
            break
        print(f"  waiting for hive_lakefs catalog... ({attempt * 2}s)")
    except Exception as e:
        print(f"  Trino not ready: {e}")
    time.sleep(2)
else:
    print("[warn] hive_lakefs catalog never appeared — LakeFS HMS init may fail")

# Schema for main branch — location is the LakeFS S3A virtual path for main
run_trino(
    "CREATE SCHEMA IF NOT EXISTS hive_lakefs.lakefs_main "
    "WITH (location = 's3a://quickstart/main/')",
    "Schema hive_lakefs.lakefs_main"
)

# Schema for dev branch
run_trino(
    "CREATE SCHEMA IF NOT EXISTS hive_lakefs.lakefs_dev "
    "WITH (location = 's3a://quickstart/dev/')",
    "Schema hive_lakefs.lakefs_dev"
)

# External table on main branch — reads Parquet files from LakeFS main
run_trino("""
    CREATE TABLE IF NOT EXISTS hive_lakefs.lakefs_main.yellow_trips (
        VendorID              integer,
        tpep_pickup_datetime  timestamp(3),
        tpep_dropoff_datetime timestamp(3),
        passenger_count       bigint,
        trip_distance         double,
        RatecodeID            bigint,
        store_and_fwd_flag    varchar,
        PULocationID          integer,
        DOLocationID          integer,
        payment_type          bigint,
        fare_amount           double,
        extra                 double,
        mta_tax               double,
        tip_amount            double,
        tolls_amount          double,
        improvement_surcharge double,
        total_amount          double,
        congestion_surcharge  double,
        Airport_fee           double
    ) WITH (
        external_location = 's3a://quickstart/main/data/',
        format = 'PARQUET'
    )
""", "Table hive_lakefs.lakefs_main.yellow_trips")

# External table on dev branch — same schema, empty until data is committed to dev
run_trino("""
    CREATE TABLE IF NOT EXISTS hive_lakefs.lakefs_dev.yellow_trips (
        VendorID              integer,
        tpep_pickup_datetime  timestamp(3),
        tpep_dropoff_datetime timestamp(3),
        passenger_count       bigint,
        trip_distance         double,
        RatecodeID            bigint,
        store_and_fwd_flag    varchar,
        PULocationID          integer,
        DOLocationID          integer,
        payment_type          bigint,
        fare_amount           double,
        extra                 double,
        mta_tax               double,
        tip_amount            double,
        tolls_amount          double,
        improvement_surcharge double,
        total_amount          double,
        congestion_surcharge  double,
        Airport_fee           double
    ) WITH (
        external_location = 's3a://quickstart/dev/data/',
        format = 'PARQUET'
    )
""", "Table hive_lakefs.lakefs_dev.yellow_trips")

# Quick sanity check — main should have rows, dev should be 0
try:
    rows = trino_query("SELECT count(*) FROM hive_lakefs.lakefs_main.yellow_trips")
    print(f"[ok] hive_lakefs.lakefs_main.yellow_trips — {rows[0][0]:,} rows")
except Exception as e:
    print(f"[warn] main row count check failed: {e}")

try:
    rows = trino_query("SELECT count(*) FROM hive_lakefs.lakefs_dev.yellow_trips")
    print(f"[ok] hive_lakefs.lakefs_dev.yellow_trips — {rows[0][0]:,} rows (dev branch is isolated)")
except Exception as e:
    print(f"[warn] dev row count check failed: {e}")

print("LakeFS HMS init complete.")
print("Init complete.")
