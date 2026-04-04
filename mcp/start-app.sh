#!/bin/bash
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is not set"
    echo "Run: export ANTHROPIC_API_KEY=sk-ant-..."
    exit 1
fi

cd ~/gravitino-quickstart/mcp/app
source .venv/bin/activate
python3 app.py
