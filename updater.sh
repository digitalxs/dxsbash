#!/bin/bash
# dxsbash Updater Script
# This script checks for and installs updates to the dxsbash repository

# Color codes
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Base directory
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"
VERSION_FILE="$DXSBASH_DIR/version.txt"

# Check if the required commands exist
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Required commands
for cmd in git curl wget; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}Error: $cmd is required but not installed.${RC}"
        exit 1
    fi
done

# Function to get current installed version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"  # Default if no version file exists
    fi
}

# Function to get latest version from repository
get_latest_version() {
    # First try with git ls-remote
    if command_exists git; then
        # Check if we can access GitHub
        if git ls-remote --quiet https://github.com/digitalxs/dxsbash.git HEAD &>/dev/null; then
            # Try to get version.txt content from the repository
            local remote_version
            remote_version=$(curl -s https://raw.githubusercontent.com/digitalxs/dxsbash/main/version.txt)
            if [ -n "$remote_version" ]; then
                echo "$remote_version"
                return 0
            fi
        fi
    fi
    
    # Fallback: Return current version if we can't get the latest
    get_current_version
    return 1
}

# Function to compare versions
version_gt() {
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

# Function to update dxsbash
update_dxsbash() {
    echo -e "${YELLOW}Updating dxsbash...${RC}"
    
    # Create backup of current installation
    local backup_dir="$LINUXTOOLBOXDIR/dxsbash_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Creating backup at $backup_dir${RC}"
    cp -r "$DXSBASH_DIR" "$backup_dir"
    
    # Pull latest changes
    cd "$DXSBASH_DIR" || exit 1
    
    # Store current branch
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    
    # Stash any local changes
    git stash -q
    
    # Fetch latest changes
    if git pull origin main; then
        echo -e "${GREEN}Successfully updated dxsbash!${RC}"
        
        # Run setup script to apply changes
        echo -e "${YELLOW}Applying updates...${RC}"
        bash "$DXSBASH_DIR/setup.sh"
        
        # Update was successful
        echo -e "${GREEN}Update completed successfully!${RC}"
        return 0
    else
        echo -e "${RED}Failed to update dxsbash.${RC}"
        echo -e "${YELLOW}Restoring from backup...${RC}"
        rm -rf "$DXSBASH_DIR"
        cp -r "$backup_dir" "$DXSBASH_DIR"
        echo -e "${YELLOW}Restored from backup.${RC}"
        return 1
    fi
}

# Main function
main() {
    echo -e "${YELLOW}Checking for dxsbash updates...${RC}"
    
    # Check if dxsbash directory exists
    if [ ! -d "$DXSBASH_DIR" ]; then
        echo -e "${RED}Error: dxsbash directory not found at $DXSBASH_DIR${RC}"
        echo -e "${YELLOW}Run the installer first:${RC}"
        echo -e "git clone --depth=1 https://github.com/digitalxs/dxsbash.git"
        exit 1
    fi
    
    # Get current and latest versions
    local current_version
    local latest_version
    
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    echo -e "Current version: ${YELLOW}$current_version${RC}"
    echo -e "Latest version: ${GREEN}$latest_version${RC}"
    
    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        echo -e "${GREEN}You already have the latest version of dxsbash.${RC}"
    elif version_gt "$latest_version" "$current_version"; then
        echo -e "${YELLOW}A newer version is available. Updating...${RC}"
        if update_dxsbash; then
            echo -e "${GREEN}dxsbash has been updated to version $latest_version${RC}"
        else
            echo -e "${RED}Update failed. Please try again later or update manually.${RC}"
        fi
    else
        echo -e "${YELLOW}You have a newer version than the repository. No update needed.${RC}"
    fi
}

# Run the main function
main "$@"
