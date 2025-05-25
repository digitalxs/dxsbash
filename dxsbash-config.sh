#!/bin/bash
# DXSBash Configuration TUI Launcher
# This script launches the TUI from anywhere in the system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUI_DIR="$SCRIPT_DIR/tui"

# Check if TUI is set up
if [ ! -d "$TUI_DIR/venv" ]; then
    echo "Setting up DXSBash Configuration TUI..."
    cd "$TUI_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    echo "Setup complete!"
fi

# Activate virtual environment and run TUI
cd "$TUI_DIR"
source venv/bin/activate
python src/main.py --dxsbash-root "$SCRIPT_DIR" "$@"
