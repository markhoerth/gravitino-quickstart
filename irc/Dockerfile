FROM apache/gravitino-iceberg-rest:1.2.0

RUN curl -L -o /root/gravitino-iceberg-rest-server/libs/postgresql-42.7.3.jar \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar && \
    curl -L -o /root/gravitino-iceberg-rest-server/libs/iceberg-aws-bundle.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.6.1/iceberg-aws-bundle-1.6.1.jar
