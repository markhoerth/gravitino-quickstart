#!/bin/bash
# start-app.sh
# Runs the MCP app using uv run — no venv management needed

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is not set"
    echo "Run: export ANTHROPIC_API_KEY=sk-ant-..."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

MODE=${1:-sql}
case $MODE in
    sql)        APP="app-sql.py" ;;
    metricflow) APP="app-metricflow.py" ;;
    *)          echo "Usage: start-app.sh [sql|metricflow]"; exit 1 ;;
esac

echo "Starting MCP app in $MODE mode..."
cd "$APP_DIR"
uv run --with anthropic --with "mcp==1.27.0" python3 "$APP"
