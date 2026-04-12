#!/bin/bash
# start-mcp-metricflow.sh
# Starts Gravitino MCP + Trino MCP + MetricFlow MCP in the background (metricflow mode)
# Logs go to mcp/logs/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$SCRIPT_DIR/logs"
mkdir -p "$LOGDIR"

# ── Gravitino MCP ────────────────────────────────────────────────────────────
if pgrep -f "mcp_server_gravitino" > /dev/null 2>&1; then
    echo "[skip] Gravitino MCP already running"
else
    echo "Starting Gravitino MCP server (port 8001)..."
    cd ~/git/mcp-server-gravitino
    source .venv/bin/activate
    GRAVITINO_URI=http://localhost:8090 \
    GRAVITINO_METALAKE=demo \
    GRAVITINO_USERNAME=admin \
    GRAVITINO_PASSWORD=admin \
    GRAVITINO_ACTIVE_TOOLS=get_list_of_catalogs,get_list_of_schemas,get_list_of_tables,get_table_by_fqn,get_table_columns_by_fqn \
    GRAVITINO_TRANSPORT=http \
    GRAVITINO_MCP_PORT=8001 \
    nohup python -m mcp_server_gravitino.server > "$LOGDIR/gravitino-mcp.log" 2>&1 &
    echo $! > "$LOGDIR/gravitino-mcp.pid"
    echo "[ok] Gravitino MCP started (pid $(cat $LOGDIR/gravitino-mcp.pid))"
fi

# ── Trino MCP ────────────────────────────────────────────────────────────────
if pgrep -f "mcp-trino" > /dev/null 2>&1; then
    echo "[skip] Trino MCP already running"
else
    echo "Starting Trino MCP server (port 8002)..."
    TRINO_SCHEME=http \
    TRINO_HOST=localhost \
    TRINO_PORT=8082 \
    TRINO_USER=admin \
    MCP_TRANSPORT=http \
    MCP_PORT=8002 \
    nohup mcp-trino mcp > "$LOGDIR/trino-mcp.log" 2>&1 &
    echo $! > "$LOGDIR/trino-mcp.pid"
    echo "[ok] Trino MCP started (pid $(cat $LOGDIR/trino-mcp.pid))"
fi

# ── MetricFlow MCP ───────────────────────────────────────────────────────────
if pgrep -f "metricflow_mcp" > /dev/null 2>&1; then
    echo "[skip] MetricFlow MCP already running"
else
    echo "Starting MetricFlow MCP server (port 8003)..."
    if [ ! -f ~/gravitino-semantic-layer-quickstart/start-metricflow-mcp.sh ]; then
        echo "[error] MetricFlow MCP not found at ~/gravitino-semantic-layer-quickstart/"
        echo "  Clone it from: https://github.com/markhoerth/gravitino-semantic-layer-quickstart"
        exit 1
    fi
    cd ~/gravitino-semantic-layer-quickstart
    nohup ./start-metricflow-mcp.sh > "$LOGDIR/metricflow-mcp.log" 2>&1 &
    echo $! > "$LOGDIR/metricflow-mcp.pid"
    echo "[ok] MetricFlow MCP started (pid $(cat $LOGDIR/metricflow-mcp.pid))"
fi

echo ""
echo "All MCP servers running. Logs in $LOGDIR/"
echo "Next:"
echo "  export ANTHROPIC_API_KEY=sk-ant-..."
echo "  ./mcp/start-app.sh metricflow"
