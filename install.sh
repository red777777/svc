#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Install requires root. Run with sudo."
    exit 1
fi

cp "$SCRIPT_DIR/svc" "$INSTALL_DIR/svc"
chmod +x "$INSTALL_DIR/svc"

echo "svc installed to $INSTALL_DIR/svc"
echo "Run 'svc' to get started."
