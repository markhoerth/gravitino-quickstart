FROM trinodb/trino:435

# Gravitino connector downloaded by build.sh before docker-compose build
COPY gravitino-connector /lib/trino/plugin/gravitino

COPY etc/config.properties /etc/trino/config.properties
COPY etc/node.properties /etc/trino/node.properties
COPY etc/jvm.config /etc/trino/jvm.config
COPY etc/catalog/ /etc/trino/catalog/

# Import SingleStore CA certificate for SSL connections
ADD https://portal.singlestore.com/static/ca/singlestore_bundle.pem /tmp/singlestore_bundle.pem
USER root
RUN keytool -import -alias singlestore -file /tmp/singlestore_bundle.pem \
    -keystore /usr/lib/jvm/jdk-21.0/lib/security/cacerts \
    -storepass changeit -noprompt
USER trino
