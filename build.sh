#!/bin/bash
set -e

echo "=== Gravitino Quickstart Build ==="

# Download Gravitino Trino connector
if [ ! -d "trino/gravitino-connector" ]; then
    echo "Downloading Gravitino Trino connector..."
    curl -L https://github.com/apache/gravitino/releases/download/v1.2.0/gravitino-trino-connector-435-439-1.2.0.tar.gz \
         -o /tmp/gravitino-connector.tar.gz
    tar -xzf /tmp/gravitino-connector.tar.gz -C /tmp/
    mv /tmp/gravitino-trino-connector-435-439-1.2.0 trino/gravitino-connector
    rm -f /tmp/gravitino-connector.tar.gz
    echo "Connector downloaded."
else
    echo "Connector already present."
fi

# Build and start
echo "Building images..."
docker compose build

echo "=== Build complete. Run 'docker compose up -d' to start ==="
