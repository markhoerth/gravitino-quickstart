#!/bin/bash
exec /opt/spark/bin/spark-sql \
  --master local[*] \
  --conf spark.plugins=org.apache.gravitino.spark.connector.plugin.GravitinoSparkPlugin \
  --conf spark.sql.gravitino.uri=http://gqs-gravitino:8090 \
  --conf spark.sql.gravitino.metalake=demo \
  --conf spark.sql.gravitino.enableIcebergSupport=true \
  --conf spark.sql.catalog.iceberg_nyc.s3.endpoint=http://gqs-minio:9000 \
  --conf spark.sql.catalog.iceberg_nyc.s3.path-style-access=true \
  --conf spark.sql.catalog.iceberg_nyc.s3.region=us-east-1
