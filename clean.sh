#!/bin/bash
#
# clean.sh - Script to remove all files installed by dxsbash
# Author: Luis Miguel P. Freitas
#
# This script removes all files and symlinks created by dxsbash installation
# It does not remove system-wide components that require sudo

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}
█▀▄ ▀▄▀ █▀ █▄▄ ▄▀█ █▀ █░█   █▀▀ █░░ █▀▀ ▄▀█ █▄░█ █░█ █▀█
█▄▀ █░█ ▄█ █▄█ █▀█ ▄█ █▀█   █▄▄ █▄▄ ██▄ █▀█ █░▀█ █▄█ █▀▀${NC}"
echo -e "${CYAN}Removing all DXSBash files from user home directory${NC}"
echo ""

# Ask for confirmation
read -p "This will remove all DXSBash files from your home directory. THIS FEATURE IS EXPERIMENTAL. DO IT AT YOUR OWN RISK! Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Starting cleanup...${NC}"

# Define common paths
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"

# Check if dxsbash directory exists
if [ ! -d "$DXSBASH_DIR" ]; then
    echo -e "${YELLOW}Warning: DXSBash directory not found at $DXSBASH_DIR${NC}"
else
    echo -e "${CYAN}Found DXSBash installation directory${NC}"
fi

# Function to safely remove a file or symlink
remove_file() {
    local file="$1"
    if [ -L "$file" ]; then
        echo -e "  Removing symlink: ${YELLOW}$file${NC}"
        rm -f "$file"
    elif [ -f "$file" ]; then
        # Check if it's a symlink pointing to dxsbash or a regular file
        if [ -L "$file" ] && [[ "$(readlink "$file")" == *"dxsbash"* ]]; then
            echo -e "  Removing symlink: ${YELLOW}$file${NC}"
            rm -f "$file"
        else
            echo -e "  Creating backup of file: ${YELLOW}$file${NC}"
            mv "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
        fi
    fi
}

# Function to safely remove a directory
remove_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo -e "  Removing directory: ${YELLOW}$dir${NC}"
        rm -rf "$dir"
    fi
}

echo -e "${CYAN}Removing shell configuration files...${NC}"

# Remove Bash configuration files
remove_file "$HOME/.bashrc"
remove_file "$HOME/.bashrc_help"
remove_file "$HOME/.bash_aliases"

# Remove Zsh configuration files
remove_file "$HOME/.zshrc"
remove_file "$HOME/.zshrc_help"
remove_file "$HOME/.zsh_plugins"

# Remove Fish configuration files
remove_file "$HOME/.config/fish/config.fish"
remove_file "$HOME/.config/fish/fish_help"

echo -e "${CYAN}Removing terminal configuration files...${NC}"

# Remove starship configuration
remove_file "$HOME/.config/starship.toml"

# Remove fastfetch configuration
remove_file "$HOME/.config/fastfetch/config.jsonc"
remove_dir "$HOME/.config/fastfetch"

# Remove Konsole profile
remove_file "$HOME/.local/share/konsole/DXSBash.profile"

# Update konsolerc and yakuakerc if they exist
if [ -f "$HOME/.config/konsolerc" ]; then
    echo -e "  Updating Konsole configuration: ${YELLOW}$HOME/.config/konsolerc${NC}"
    sed -i '/DefaultProfile=DXSBash.profile/d' "$HOME/.config/konsolerc"
fi

if [ -f "$HOME/.config/yakuakerc" ]; then
    echo -e "  Updating Yakuake configuration: ${YELLOW}$HOME/.config/yakuakerc${NC}"
    sed -i '/DefaultProfile=DXSBash.profile/d' "$HOME/.config/yakuakerc"
fi

# Remove updater script
remove_file "$HOME/update-dxsbash.sh"

# Remove logs directory
remove_dir "$HOME/.dxsbash"

echo -e "${CYAN}Checking for dxsbash backups...${NC}"
# List any backup directories but don't remove them automatically
find "$LINUXTOOLBOXDIR" -name "dxsbash_backup_*" -type d | while read backup_dir; do
    echo -e "  Found backup: ${YELLOW}$backup_dir${NC}"
done

# Ask if user wants to remove the dxsbash directory
read -p "Do you want to remove the dxsbash directory ($DXSBASH_DIR)? (y/N): " remove_dxsbash
if [[ "$remove_dxsbash" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing dxsbash directory...${NC}"
    rm -rf "$DXSBASH_DIR"
    echo -e "${GREEN}DXSBash directory removed.${NC}"
    
    # Check if linuxtoolbox is empty
    if [ -z "$(ls -A "$LINUXTOOLBOXDIR" 2>/dev/null)" ]; then
        read -p "The linuxtoolbox directory is empty. Remove it? (y/N): " remove_toolbox
        if [[ "$remove_toolbox" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Removing empty linuxtoolbox directory...${NC}"
            rm -rf "$LINUXTOOLBOXDIR"
            echo -e "${GREEN}Empty linuxtoolbox directory removed.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Keeping dxsbash directory.${NC}"
fi

echo -e "${GREEN}Cleanup completed!${NC}"
echo -e "${YELLOW}Note: System-wide components installed with sudo were not removed.${NC}"
echo -e "${YELLOW}To remove them, run the following commands with sudo:${NC}"
echo -e "  sudo rm -f /usr/local/bin/reset-shell-profile"
echo -e "  sudo rm -f /usr/local/bin/reset-bash-profile"
echo -e "  sudo rm -f /usr/local/bin/reset-zsh-profile"
echo -e "  sudo rm -f /usr/local/bin/reset-fish-profile"
echo -e "  sudo rm -f /usr/local/bin/upbashdxs"

echo -e "${BLUE}You may want to restore your original shell configuration files.${NC}"
echo -e "${BLUE}If you had backups, they should be available with .bak extension.${NC}"
echo ""
echo -e "${CYAN}For complete removal, you might want to switch back to your original shell:${NC}"
echo -e "  chsh -s \$(which bash) # Replace 'bash' with your preferred shell${NC}"
