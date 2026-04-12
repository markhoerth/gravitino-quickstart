FROM apache/spark:3.5.5

USER root

RUN curl -fsSL -o /opt/spark/jars/gravitino-spark-connector.jar \
    https://repo1.maven.org/maven2/org/apache/gravitino/gravitino-spark-connector-runtime-3.5_2.12/1.2.0/gravitino-spark-connector-runtime-3.5_2.12-1.2.0.jar && \
    curl -fsSL -o /opt/spark/jars/postgresql.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.3.jar && \
    curl -fsSL -o /opt/spark/jars/iceberg-spark-runtime.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.10.0/iceberg-spark-runtime-3.5_2.12-1.10.0.jar && \
    curl -fsSL -o /opt/spark/jars/iceberg-aws-bundle.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.10.0/iceberg-aws-bundle-1.10.0.jar

COPY start-spark-sql.sh /opt/spark/bin/start-spark-sql.sh
RUN chmod +x /opt/spark/bin/start-spark-sql.sh

USER spark
