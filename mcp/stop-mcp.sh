#!/bin/bash
# stop-mcp.sh — stops all MCP servers started by start-mcp-*.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$SCRIPT_DIR/logs"

stop_pid() {
    local name=$1
    local pidfile="$LOGDIR/${name}.pid"
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "[ok] Stopped $name (pid $pid)"
        else
            echo "[skip] $name not running"
        fi
        rm -f "$pidfile"
    else
        echo "[skip] $name pid file not found"
    fi
}

stop_pid "gravitino-mcp"
stop_pid "trino-mcp"
stop_pid "metricflow-mcp"

# Belt and suspenders
pkill -f "mcp_server_gravitino" 2>/dev/null && echo "[ok] Killed stray gravitino-mcp processes" || true
pkill -f "mcp-trino" 2>/dev/null && echo "[ok] Killed stray mcp-trino processes" || true
pkill -f "metricflow_mcp" 2>/dev/null && echo "[ok] Killed stray metricflow-mcp processes" || true

echo "Done."
