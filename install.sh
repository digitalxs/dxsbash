#!/bin/bash
# Simple DXSBash Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/digitalxs/dxsbash/refs/heads/main/install.sh | bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}
██████╗ ██╗  ██╗███████╗██████╗  █████╗ ███████╗██╗  ██╗
██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║  ██║
██║  ██║ ╚███╔╝ ███████╗██████╔╝███████║███████╗███████║
██║  ██║ ██╔██╗ ╚════██║██╔══██╗██╔══██║╚════██║██╔══██║
██████╔╝██╔╝ ██╗███████║██████╔╝██║  ██║███████║██║  ██║
╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${NC}"
echo -e "${CYAN}Professional Shell Environment for Linux Power Users${NC}"
echo -e "${YELLOW}digitalxs.ca${NC}\n"

# Create directory if it doesn't exist
mkdir -p "$HOME/linuxtoolbox"

# Change to the home directory to ensure we're in a valid location
cd "$HOME"

# Clone the repository
echo -e "${GREEN}Cloning DXSBash repository...${NC}"
git clone --depth=1 https://github.com/digitalxs/dxsbash.git "$HOME/linuxtoolbox/dxsbash"

# Change to the repository directory
cd "$HOME/linuxtoolbox/dxsbash" || { echo "Failed to navigate to repository directory"; exit 1; }

# Make the setup script executable
chmod +x setup.sh

# Run the setup script
echo -e "${GREEN}Running setup script...${NC}"
./setup.sh

# Display completion message
echo -e "${GREEN}Installation complete!${NC}"
echo -e "You may need to restart your terminal or source your shell configuration file."
echo -e "For help, type: ${CYAN}help${NC}"
