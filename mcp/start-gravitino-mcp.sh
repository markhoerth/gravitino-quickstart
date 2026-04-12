#!/bin/bash
# start-gravitino-mcp.sh
# NOTE: The Gravitino MCP server now runs automatically as a Docker service
# (gqs-gravitino-mcp) when you run `make up`. It is available at:
#   http://localhost:8001/mcp
#
# This script is no longer needed for normal use.
# It is kept for reference only.

echo "Gravitino MCP server runs automatically via Docker (gqs-gravitino-mcp)."
echo "It should already be available at http://localhost:8001/mcp"
echo ""
echo "Check its status with:  docker logs gqs-gravitino-mcp"
