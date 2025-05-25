# DXSBash Configuration TUI 1.0

A Terminal User Interface for managing DXSBash shell environment configurations, integrated directly into the DXSBash repository.

## Quick Start

### From DXSBash Repository

```bash
# Navigate to your DXSBash repository
cd ~/linuxtoolbox/dxsbash

# Setup TUI environment  
cd tui
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run the TUI
python src/main.py