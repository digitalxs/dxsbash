
# Direct Installation =================================

# Install from repository
cd ~/linuxtoolbox/dxsbash/tui
pip install -e .

# Run anywhere
dxsbash-config

# Basic Commands ======================================

# Run with auto-detected DXSBash path
python src/main.py

# Use custom DXSBash directory
python src/main.py --dxsbash-root ~/my-dxsbash

# Debug mode
python src/main.py --debug

# Key Shortcuts ========================================

Ctrl+S >> Save configuration
Ctrl+A >> Apply changes to DXSBash files
Ctrl+R >> Reset to defaults
F1 >> Show help
F5 >> Refresh from files
Q >> Quit