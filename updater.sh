#!/bin/bash
# dxsbash Updater Script
# This script checks for and installs updates to the dxsbash repository
# With support for Bash, Zsh, and Fish shells

# Color codes
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[34m'
CYAN='\033[36m'

# Load dxsbash utilities for logging if available
DXSBASH_UTILS="$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh"
if [ -f "$DXSBASH_UTILS" ]; then
    source "$DXSBASH_UTILS"
    # Create logs directory if it doesn't exist
    mkdir -p "$HOME/.dxsbash/logs"
else
    # Define a fallback log function if the utilities file isn't available
    log() {
        local level="$1"
        local message="$2"
        # Do nothing - silent fallback
    }
    
    rotate_logs() {
        # Do nothing - silent fallback
        :
    }
fi

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

# Check network connectivity
echo -e "${YELLOW}Checking network connectivity...${RC}"
if ! ping -c 1 github.com &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to GitHub. Check your internet connection.${RC}"
    exit 1
fi

# Detect currently used shell
detect_current_shell() {
    # Try to determine from SHELL environment variable first
    CURRENT_SHELL_PATH="$SHELL"
    CURRENT_SHELL=$(basename "$CURRENT_SHELL_PATH")
    
    # Check if the current shell is already a symlink to one of our configurations
    if [ -L "$HOME/.bashrc" ] && [ "$(readlink "$HOME/.bashrc")" = "$DXSBASH_DIR/.bashrc" ]; then
        DETECTED_SHELL="bash"
    elif [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc")" = "$DXSBASH_DIR/.zshrc" ]; then
        DETECTED_SHELL="zsh"
    elif [ -L "$HOME/.config/fish/config.fish" ] && [ "$(readlink "$HOME/.config/fish/config.fish")" = "$DXSBASH_DIR/config.fish" ]; then
        DETECTED_SHELL="fish"
    else
        # Default to detecting based on current shell
        case "$CURRENT_SHELL" in
            bash)
                DETECTED_SHELL="bash"
                ;;
            zsh)
                DETECTED_SHELL="zsh"
                ;;
            fish)
                DETECTED_SHELL="fish"
                ;;
            *)
                # Default to bash if we can't determine
                DETECTED_SHELL="bash"
                echo -e "${YELLOW}Could not determine shell type. Defaulting to bash.${RC}"
                ;;
        esac
    fi
    
    echo -e "${BLUE}Detected shell: ${CYAN}$DETECTED_SHELL${RC}"
    return 0
}

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
            remote_version=$(curl -s https://raw.githubusercontent.com/digitalxs/dxsbash/refs/heads/main/version.txt)
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

# Function to update shell configurations
update_shell_configs() {
    local user_home="$1"
    local dxsbash_dir="$2"
    local detected_shell="$3"

    echo -e "${YELLOW}Updating shell configurations...${RC}"
    
    # Update shell-specific configuration
    case "$detected_shell" in
        bash)
            # Update Bash configuration
            ln -svf "$dxsbash_dir/.bashrc" "$user_home/.bashrc" && \
            (echo -e "${GREEN}Updated .bashrc${RC}"; log "INFO" "Updated .bashrc") || \
            (echo -e "${RED}Failed to update .bashrc${RC}"; log "ERROR" "Failed to update .bashrc")
            
            ln -svf "$dxsbash_dir/.bashrc_help" "$user_home/.bashrc_help" && \
            echo -e "${GREEN}Updated .bashrc_help${RC}" || \
            echo -e "${RED}Failed to update .bashrc_help${RC}"
            ;;
            
        zsh)
            # Update Zsh configuration
            ln -svf "$dxsbash_dir/.zshrc" "$user_home/.zshrc" && \
            echo -e "${GREEN}Updated .zshrc${RC}" || \
            echo -e "${RED}Failed to update .zshrc${RC}"
            
            ln -svf "$dxsbash_dir/.zshrc_help" "$user_home/.zshrc_help" && \
            echo -e "${GREEN}Updated .zshrc_help${RC}" || \
            echo -e "${RED}Failed to update .zshrc_help${RC}"
            
            # Check for Zsh plugins file and update if exists
            if [ -f "$dxsbash_dir/.zsh_plugins" ]; then
                ln -svf "$dxsbash_dir/.zsh_plugins" "$user_home/.zsh_plugins" && \
                echo -e "${GREEN}Updated .zsh_plugins${RC}" || \
                echo -e "${RED}Failed to update .zsh_plugins${RC}"
            fi
            ;;
            
        fish)
            # Update Fish configuration
            mkdir -p "$user_home/.config/fish"
            
            ln -svf "$dxsbash_dir/config.fish" "$user_home/.config/fish/config.fish" && \
            echo -e "${GREEN}Updated config.fish${RC}" || \
            echo -e "${RED}Failed to update config.fish${RC}"
            
            ln -svf "$dxsbash_dir/fish_help" "$user_home/.config/fish/fish_help" && \
            echo -e "${GREEN}Updated fish_help${RC}" || \
            echo -e "${RED}Failed to update fish_help${RC}"
            ;;
            
        *)
            echo -e "${RED}Unknown shell type: $detected_shell. Shell configurations not updated.${RC}"
            return 1
            ;;
    esac
    
    # Update common configurations
    mkdir -p "$user_home/.config"
    
    # Update Starship configuration
    ln -svf "$dxsbash_dir/starship.toml" "$user_home/.config/starship.toml" && \
    echo -e "${GREEN}Updated starship.toml${RC}" || \
    echo -e "${RED}Failed to update starship.toml${RC}"
    
    # Update Fastfetch configuration if it exists
    if [ -f "$dxsbash_dir/config.jsonc" ]; then
        mkdir -p "$user_home/.config/fastfetch"
        ln -svf "$dxsbash_dir/config.jsonc" "$user_home/.config/fastfetch/config.jsonc" && \
        echo -e "${GREEN}Updated fastfetch configuration${RC}" || \
        echo -e "${RED}Failed to update fastfetch configuration${RC}"
    fi
    
    return 0
}

# Function to update Konsole configuration if present
update_konsole_config() {
    local user_home="$1"
    local dxsbash_dir="$2"
    
    # Check if Konsole configuration files exist
    if [ -f "$dxsbash_dir/DXSBash.profile" ]; then
        echo -e "${YELLOW}Updating Konsole configuration...${RC}"
        
        # Create Konsole profile directory if it doesn't exist
        mkdir -p "$user_home/.local/share/konsole"
        
        # Update Konsole profile
        ln -svf "$dxsbash_dir/DXSBash.profile" "$user_home/.local/share/konsole/DXSBash.profile" && \
        echo -e "${GREEN}Updated Konsole profile${RC}" || \
        echo -e "${RED}Failed to update Konsole profile${RC}"
        
        # Check if konsolerc exists and update if it does
        if [ -f "$user_home/.config/konsolerc" ]; then
            # Check if DefaultProfile is already set to DXSBash.profile
            if ! grep -q "DefaultProfile=DXSBash.profile" "$user_home/.config/konsolerc"; then
                # Update DefaultProfile in konsolerc
                if grep -q "DefaultProfile=" "$user_home/.config/konsolerc"; then
                    # Replace existing DefaultProfile line
                    sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$user_home/.config/konsolerc" && \
                    echo -e "${GREEN}Updated Konsole default profile${RC}" || \
                    echo -e "${RED}Failed to update Konsole default profile${RC}"
                else
                    # Add DefaultProfile line if it doesn't exist
                    echo "DefaultProfile=DXSBash.profile" >> "$user_home/.config/konsolerc" && \
                    echo -e "${GREEN}Added Konsole default profile${RC}" || \
                    echo -e "${RED}Failed to add Konsole default profile${RC}"
                fi
            fi
        fi
        
        # Do the same for Yakuake if it exists
        if [ -f "$user_home/.config/yakuakerc" ]; then
            echo -e "${YELLOW}Updating Yakuake configuration...${RC}"
            
            if ! grep -q "DefaultProfile=DXSBash.profile" "$user_home/.config/yakuakerc"; then
                if grep -q "DefaultProfile=" "$user_home/.config/yakuakerc"; then
                    # Replace existing DefaultProfile line
                    sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$user_home/.config/yakuakerc" && \
                    echo -e "${GREEN}Updated Yakuake default profile${RC}" || \
                    echo -e "${RED}Failed to update Yakuake default profile${RC}"
                else
                    # Add DefaultProfile line if it doesn't exist
                    echo "DefaultProfile=DXSBash.profile" >> "$user_home/.config/yakuakerc" && \
                    echo -e "${GREEN}Added Yakuake default profile${RC}" || \
                    echo -e "${RED}Failed to add Yakuake default profile${RC}"
                fi
            fi
        fi
    fi
    
    return 0
}

# Function to update dxsbash
update_dxsbash() {
    echo -e "${YELLOW}Updating dxsbash...${RC}"
    log "INFO" "Starting dxsbash update"
    
    # Create backup of current installation
    local backup_dir="$LINUXTOOLBOXDIR/dxsbash_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Creating backup at $backup_dir${RC}"
    cp -r "$DXSBASH_DIR" "$backup_dir"
    log "INFO" "Created backup at $backup_dir"
    
    # Store the old version before updating
    local old_version=$(get_current_version)
    log "INFO" "Updating from version $old_version"
    
    # Get user home directory
    USER_HOME="$HOME"
    
    # Detect current shell before updating
    detect_current_shell
    local SHELL_TYPE="$DETECTED_SHELL"
    
    # Pull latest changes
    cd "$DXSBASH_DIR" || exit 1
    
    # Check for local modifications
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}Local modifications detected. These will be preserved in the backup.${RC}"
    fi
    
    # Store current branch
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    
    # Stash any local changes
    git stash -q
    log "INFO" "Stashed local changes"
    
    # Fetch latest changes
    if git pull origin main; then
        echo -e "${GREEN}Successfully updated dxsbash repository!${RC}"
        log "INFO" "Git pull successful"
        
        # Get the new version after update
        local new_version=$(get_current_version)
        echo -e "${GREEN}Updated from version ${YELLOW}$old_version${GREEN} to ${YELLOW}$new_version${RC}"
        log "INFO" "Updated from version $old_version to $new_version"
        
        # Define sudo command
        local sudo_cmd="sudo"
        if ! command -v sudo >/dev/null 2>&1; then
            if command -v doas >/dev/null 2>&1 && [ -f "/etc/doas.conf" ]; then
                sudo_cmd="doas"
            else
                sudo_cmd="su -c"
            fi
        fi
        
        # Update shell configurations
        update_shell_configs "$USER_HOME" "$DXSBASH_DIR" "$SHELL_TYPE"
        log "INFO" "Updated shell configurations for $SHELL_TYPE"
        
        # Update Konsole configuration if present
        update_konsole_config "$USER_HOME" "$DXSBASH_DIR"
        
        # Update the updater script in home directory
        ln -svf "$DXSBASH_DIR/updater.sh" "$USER_HOME/update-dxsbash.sh"
        chmod +x "$USER_HOME/update-dxsbash.sh" && \
        echo -e "${GREEN}Updated updater script in home directory${RC}" || \
        echo -e "${RED}Failed to update updater script in home directory${RC}"
        
        # Update system-wide commands
        echo -e "${YELLOW}Updating system-wide commands...${RC}"
        
        # Update reset-shell-profile
        if [ -f "$DXSBASH_DIR/reset-bash-profile.sh" ]; then
            cp -p "$DXSBASH_DIR/reset-bash-profile.sh" "$LINUXTOOLBOXDIR/"
            chmod +x "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
            $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-bash-profile && \
            echo -e "${GREEN}Updated reset-bash-profile script${RC}" || \
            echo -e "${RED}Failed to update reset-bash-profile script${RC}"
        fi
        
        # Update shell-specific reset scripts if they exist
        if [ -f "$DXSBASH_DIR/reset-zsh-profile.sh" ]; then
            cp -p "$DXSBASH_DIR/reset-zsh-profile.sh" "$LINUXTOOLBOXDIR/"
            chmod +x "$LINUXTOOLBOXDIR/reset-zsh-profile.sh"
            $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" /usr/local/bin/reset-zsh-profile && \
            echo -e "${GREEN}Updated reset-zsh-profile script${RC}" || \
            echo -e "${RED}Failed to update reset-zsh-profile script${RC}"
        fi
        
        if [ -f "$DXSBASH_DIR/reset-fish-profile.sh" ]; then
            cp -p "$DXSBASH_DIR/reset-fish-profile.sh" "$LINUXTOOLBOXDIR/"
            chmod +x "$LINUXTOOLBOXDIR/reset-fish-profile.sh"
            $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-fish-profile && \
            echo -e "${GREEN}Updated reset-fish-profile script${RC}" || \
            echo -e "${RED}Failed to update reset-fish-profile script${RC}"
        fi
        
        # Update the generic reset-shell-profile link based on detected shell
        case "$SHELL_TYPE" in
            bash)
                $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                ;;
            zsh)
                if [ -f "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" ]; then
                    $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" /usr/local/bin/reset-shell-profile
                else
                    $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                fi
                ;;
            fish)
                if [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ]; then
                    $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-shell-profile
                else
                    $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                fi
                ;;
        esac
        
        # Update system-wide updater command
        if [ -f "$DXSBASH_DIR/updater.sh" ]; then
            cp -p "$DXSBASH_DIR/updater.sh" "$LINUXTOOLBOXDIR/"
            chmod +x "$LINUXTOOLBOXDIR/updater.sh"
        if $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/updater.sh" /usr/local/bin/upbashdxs; then
            echo -e "${GREEN}Updated system-wide updater command${RC}"
            log "INFO" "Updated system-wide updater command"
        else
            echo -e "${RED}Failed to update system-wide updater command${RC}"
            log "ERROR" "Failed to update system-wide updater command"
        fi
}

        # Update utilities script
        if [ -f "$DXSBASH_DIR/dxsbash-utils.sh" ]; then
            cp -p "$DXSBASH_DIR/dxsbash-utils.sh" "$LINUXTOOLBOXDIR/"
            chmod +x "$LINUXTOOLBOXDIR/dxsbash-utils.sh"
            log "INFO" "Updated dxsbash-utils.sh"
        fi
        
        echo -e "${GREEN}Update completed successfully!${RC}"
        log "INFO" "Update completed successfully"
        echo -e "${YELLOW}To apply changes to your current session, run: source ~/.${SHELL_TYPE}rc${RC}"
        return 0
    else
        echo -e "${RED}Failed to update dxsbash repository.${RC}"
        log "ERROR" "Failed to update dxsbash repository"
        echo -e "${YELLOW}Restoring from backup...${RC}"
        rm -rf "$DXSBASH_DIR"
        cp -r "$backup_dir" "$DXSBASH_DIR"
        echo -e "${YELLOW}Restored from backup.${RC}"
        log "INFO" "Restored from backup $backup_dir"
        return 1
    fi
}

# Rotate logs if needed
rotate_logs

# Main function
main() {
    echo -e "${YELLOW}Checking for dxsbash updates...${RC}"
    log "INFO" "Starting check for dxsbash updates"
    
    # Check if dxsbash directory exists
    if [ ! -d "$DXSBASH_DIR" ]; then
        echo -e "${RED}Error: dxsbash directory not found at $DXSBASH_DIR${RC}"
        log "ERROR" "dxsbash directory not found at $DXSBASH_DIR"
        echo -e "${YELLOW}Run the installer first:${RC}"
        echo -e "git clone --depth=1 https://github.com/digitalxs/dxsbash.git"
        echo -e "cd dxsbash"
        echo -e "./setup.sh"
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
        echo -e "${YELLOW}A newer version is available!${RC}"
        log "INFO" "Found a new version available"
        
        # Ask for user confirmation
        read -p "Do you want to proceed with the update? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Update cancelled.${RC}"
            exit 0
        fi
        
        if update_dxsbash; then
            echo -e "${GREEN}dxsbash has been updated to version $latest_version${RC}"
            log "INFO" "dxsbash has been updated to version $latest_version"
        else
            echo -e "${RED}Update failed. Please try again later or update manually.${RC}"
            log "ERROR" "Update failed"
        fi
    else
        echo -e "${YELLOW}You have a newer version than the repository. No update needed.${RC}"
    fi
}

# Run the main function
main "$@"
