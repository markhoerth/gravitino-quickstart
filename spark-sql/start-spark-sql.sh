#!/bin/bash
exec /opt/spark/bin/spark-sql \
  --master local[*] \
  --conf spark.plugins=org.apache.gravitino.spark.connector.plugin.GravitinoSparkPlugin \
  --conf spark.sql.gravitino.uri=http://gqs-gravitino:8090 \
  --conf spark.sql.gravitino.metalake=demo
