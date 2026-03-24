CREATE DATABASE gravitino_meta;
CREATE DATABASE iceberg_catalog;
CREATE DATABASE hms_meta;
CREATE DATABASE demo_data;
CREATE DATABASE airflow_meta;

CREATE USER gravitino WITH PASSWORD 'gravitino';
GRANT ALL PRIVILEGES ON DATABASE gravitino_meta TO gravitino;
GRANT ALL PRIVILEGES ON DATABASE iceberg_catalog TO gravitino;
GRANT ALL PRIVILEGES ON DATABASE hms_meta TO gravitino;
GRANT ALL PRIVILEGES ON DATABASE demo_data TO gravitino;
GRANT ALL PRIVILEGES ON DATABASE airflow_meta TO gravitino;

\connect demo_data
GRANT ALL ON SCHEMA public TO gravitino;

\connect iceberg_catalog
GRANT ALL ON SCHEMA public TO gravitino;

\connect gravitino_meta
GRANT ALL ON SCHEMA public TO gravitino;

\connect hms_meta
GRANT ALL ON SCHEMA public TO gravitino;
