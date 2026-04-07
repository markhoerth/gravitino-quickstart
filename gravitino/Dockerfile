FROM apache/gravitino:1.2.0
ENV GRAVITINO_USE_WEB_V2=true
COPY gravitino-start.sh /root/gravitino/bin/start-gravitino.sh
RUN chmod +x /root/gravitino/bin/start-gravitino.sh
RUN curl -L -o /root/gravitino/catalogs/lakehouse-iceberg/libs/iceberg-aws-bundle.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.6.1/iceberg-aws-bundle-1.6.1.jar
