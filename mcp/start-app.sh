#!/bin/bash
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is not set"
    echo "Run: export ANTHROPIC_API_KEY=sk-ant-..."
    exit 1
fi
cd ~/gravitino-quickstart/mcp/app
source .venv/bin/activate
MODE=${1:-sql}
case $MODE in
    sql)         python3 app-sql.py ;;
    metricflow)  python3 app-metricflow.py ;;
    *)           echo "Usage: start-app.sh [sql|metricflow]"; exit 1 ;;
esac
