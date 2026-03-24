FROM apache/hive:4.0.0

USER root
RUN apt-get update && \
    apt-get install -y curl && \
    curl -L https://jdbc.postgresql.org/download/postgresql-42.7.3.jar \
    -o /opt/hive/lib/postgresql-42.7.3.jar && \
    rm -rf /var/lib/apt/lists/*
USER hive
