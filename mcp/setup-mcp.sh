#!/bin/bash
# setup-mcp.sh
# Installs prerequisites for the Gravitino Quickstart MCP stack:
#   - uv (Python package manager)
#   - mcp-trino binary (tuannvm/mcp-trino)
#
# Gravitino MCP server runs as a Docker service (gqs-gravitino-mcp) —
# no additional setup needed for it.
#
# Run once after cloning the repo.

set -e

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# ── uv ───────────────────────────────────────────────────────────────────────
if command -v uv > /dev/null 2>&1; then
    echo "[skip] uv already installed at $(which uv)"
else
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # uv installs to ~/.local/bin — source env to pick it up immediately
    source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
    echo "[ok] uv installed"
fi

# ── mcp-trino binary ─────────────────────────────────────────────────────────
if command -v mcp-trino > /dev/null 2>&1; then
    echo "[skip] mcp-trino already installed at $(which mcp-trino)"
else
    echo "Installing mcp-trino..."
    curl -fsSL https://raw.githubusercontent.com/tuannvm/mcp-trino/main/install.sh | bash
    echo "[ok] mcp-trino installed"
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "  NOTE: Add $INSTALL_DIR to your PATH:"
    echo "    echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc && source ~/.bashrc"
    echo ""
fi

echo ""
echo "MCP setup complete. Next steps:"
echo "  1. Start the data platform:  make up  (from gravitino-quickstart/)"
echo "  2. Start MCP servers:        ./mcp/start-mcp-sql.sh"
echo "  3. Set your API key:         export ANTHROPIC_API_KEY=sk-ant-..."
echo "  4. Start the app:            ./mcp/start-app.sh sql"
