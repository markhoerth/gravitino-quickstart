#!/bin/bash
TRINO_SCHEME=http \
TRINO_HOST=localhost \
TRINO_PORT=8082 \
TRINO_USER=admin \
MCP_TRANSPORT=http \
MCP_PORT=8002 \
mcp-trino mcp
