#!/bin/bash
bin_dir="$(dirname "${BASH_SOURCE-$0}")"
gravitino_dir="$(cd "${bin_dir}/../" > /dev/null; pwd)"
cd "${gravitino_dir}"

python bin/rewrite_gravitino_server_config.py

CONF="${gravitino_dir}/conf/gravitino.conf"

# Disable the embedded Iceberg REST server — we use the standalone IRC container
# Remove the auxService entirely and change its port so it can't conflict
sed -i 's|gravitino.auxService.names = .*|gravitino.auxService.names =|' "$CONF"
sed -i 's|gravitino.iceberg-rest.httpPort = .*|gravitino.iceberg-rest.httpPort = 19001|' "$CONF"

echo "[gravitino-start] Embedded Iceberg REST server disabled (port moved to 19001)"

JAVA_OPTS+=" -XX:-UseContainerSupport"
export JAVA_OPTS

./bin/gravitino.sh start

mkdir -p "${gravitino_dir}/logs"
tail -f "${gravitino_dir}/logs/gravitino-server.log" 2>/dev/null || \
  tail -f /dev/null
