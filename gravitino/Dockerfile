FROM apache/gravitino:1.2.0

# Enable V2 UI
ENV GRAVITINO_USE_WEB_V2=true

# Add PostgreSQL JDBC driver (pre-downloaded, no curl needed)
COPY postgresql-42.7.3.jar /gravitino/catalogs/jdbc-postgresql/libs/
COPY postgresql-42.7.3.jar /gravitino/catalogs/lakehouse-iceberg/libs/

# Copy config
COPY gravitino.conf /gravitino/conf/gravitino.conf
COPY gravitino-env.sh /gravitino/conf/gravitino-env.sh
