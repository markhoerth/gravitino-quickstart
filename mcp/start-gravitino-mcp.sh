#!/bin/bash
cd ~/git/mcp-server-gravitino
source .venv/bin/activate

GRAVITINO_URI=http://localhost:8090 \
GRAVITINO_METALAKE=metalake_demo \
GRAVITINO_USERNAME=admin \
GRAVITINO_PASSWORD=admin \
GRAVITINO_ACTIVE_TOOLS=get_list_of_catalogs,get_list_of_schemas,get_list_of_tables,get_table_by_fqn,get_table_columns_by_fqn \
GRAVITINO_TRANSPORT=http \
GRAVITINO_MCP_PORT=8001 \
python -m mcp_server_gravitino.server
