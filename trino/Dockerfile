FROM trinodb/trino:435

# Gravitino connector downloaded by build.sh before docker-compose build
COPY gravitino-connector /lib/trino/plugin/gravitino

COPY etc/config.properties /etc/trino/config.properties
COPY etc/node.properties /etc/trino/node.properties
COPY etc/jvm.config /etc/trino/jvm.config
COPY etc/catalog/gravitino.properties /etc/trino/catalog/gravitino.properties
