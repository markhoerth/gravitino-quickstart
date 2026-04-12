#!/bin/bash
# setup-mcp.sh
# Installs prerequisites for the Gravitino Quickstart MCP stack:
#   - mcp-trino binary (tuannvm/mcp-trino v4.3.1)
#   - Gravitino MCP server Python venv
#   - App Python venv
#
# Run once after cloning the repo.

set -e

MCP_TRINO_VERSION="4.3.1"
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# ── Detect platform ──────────────────────────────────────────────────────────
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS/$ARCH" in
    Linux/x86_64)   PLATFORM="Linux_x86_64" ;;
    Linux/aarch64)  PLATFORM="Linux_arm64" ;;
    Darwin/arm64)   PLATFORM="Darwin_arm64" ;;
    Darwin/x86_64)  PLATFORM="Darwin_x86_64" ;;
    *)
        echo "Unsupported platform: $OS/$ARCH"
        exit 1
        ;;
esac

# ── mcp-trino binary ─────────────────────────────────────────────────────────
if command -v mcp-trino > /dev/null 2>&1; then
    echo "[skip] mcp-trino already installed at $(which mcp-trino)"
else
    echo "Installing mcp-trino v${MCP_TRINO_VERSION} for ${PLATFORM}..."
    URL="https://github.com/tuannvm/mcp-trino/releases/download/v${MCP_TRINO_VERSION}/mcp-trino_${PLATFORM}.tar.gz"
    curl -fsSL "$URL" | tar xz -C "$INSTALL_DIR" mcp-trino
    chmod +x "$INSTALL_DIR/mcp-trino"
    echo "[ok] mcp-trino installed to $INSTALL_DIR/mcp-trino"
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "  NOTE: Add $INSTALL_DIR to your PATH:"
    echo "    echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc && source ~/.bashrc"
    echo ""
fi

# ── Gravitino MCP server venv ────────────────────────────────────────────────
GRAVITINO_MCP_DIR="$HOME/git/mcp-server-gravitino"
if [ ! -d "$GRAVITINO_MCP_DIR" ]; then
    echo ""
    echo "  NOTE: Gravitino MCP server not found at $GRAVITINO_MCP_DIR"
    echo "  Clone it with:"
    echo "    git clone https://github.com/datastrato/mcp-server-gravitino ~/git/mcp-server-gravitino"
    echo "  Then re-run this script."
    echo ""
else
    if [ ! -d "$GRAVITINO_MCP_DIR/.venv" ]; then
        echo "Setting up Gravitino MCP server venv..."
        cd "$GRAVITINO_MCP_DIR"
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -q -r requirements.txt
        deactivate
        echo "[ok] Gravitino MCP server venv ready"
    else
        echo "[skip] Gravitino MCP server venv already exists"
    fi
fi

# ── App venv ─────────────────────────────────────────────────────────────────
APP_DIR="$(dirname "$0")/app"
if [ ! -d "$APP_DIR/.venv" ]; then
    echo "Setting up app venv..."
    cd "$APP_DIR"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -q -r requirements.txt
    deactivate
    echo "[ok] App venv ready"
else
    echo "[skip] App venv already exists"
fi

echo ""
echo "MCP setup complete. Next steps:"
echo "  1. Start the data platform:  make up  (from gravitino-quickstart/)"
echo "  2. Start MCP servers:        ./mcp/start-mcp-sql.sh"
echo "  3. Set your API key:         export ANTHROPIC_API_KEY=sk-ant-..."
echo "  4. Start the app:            ./mcp/start-app.sh sql"
