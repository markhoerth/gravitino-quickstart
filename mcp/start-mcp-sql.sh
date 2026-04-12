#!/bin/bash
# start-mcp-sql.sh
# Starts Trino MCP server in the background (sql mode)
# Gravitino MCP is already running as gqs-gravitino-mcp via docker-compose

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$SCRIPT_DIR/logs"
mkdir -p "$LOGDIR"

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

echo ""
echo "Gravitino MCP: already running at http://localhost:8001/mcp (Docker)"
echo "Trino MCP:     running at http://localhost:8002/mcp"
echo ""
echo "Next:"
echo "  export ANTHROPIC_API_KEY=sk-ant-..."
echo "  ./mcp/start-app.sh sql"
