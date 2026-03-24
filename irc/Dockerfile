FROM apache/gravitino-iceberg-rest:1.2.0

# Add PostgreSQL JDBC driver (not included in base image)
RUN curl -L -o /root/gravitino-iceberg-rest-server/libs/postgresql-42.7.3.jar \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar
