#!/bin/bash
# dxsbash Updater Script - Enhanced Version for Complete Repository Sync
# This script checks for and installs updates to the dxsbash repository
# With support for Bash, Zsh, and Fish shells
# Version 2.2.9 - Now updates ALL repository files locally

# Color codes
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[34m'
CYAN='\033[36m'

# Script version for debugging
UPDATER_VERSION="2.2.9"

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
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local log_file="$HOME/.dxsbash/logs/updater.log"
        
        # Create log directory if it doesn't exist
        mkdir -p "$(dirname "$log_file")"
        
        # Format and append the log message
        echo "[$timestamp] [$level] $message" >> "$log_file"
    }
    
    rotate_logs() {
        local log_dir="$HOME/.dxsbash/logs"
        local main_log="$log_dir/updater.log"
        local max_size=1048576  # 1MB
        
        # Check if log exists and is larger than max size
        if [ -f "$main_log" ] && [ $(stat -c %s "$main_log" 2>/dev/null || echo 0) -gt $max_size ]; then
            local timestamp=$(date "+%Y%m%d_%H%M%S")
            mv "$main_log" "$log_dir/updater_$timestamp.log"
            # Keep only the 5 most recent log files
            ls -t "$log_dir"/updater_*.log 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
        fi
    }
fi

# Base directory
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"
VERSION_FILE="$DXSBASH_DIR/version.txt"

# Rotate logs at start
rotate_logs

# Check if the required commands exist
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Required commands check with better error messages
check_dependencies() {
    local missing_deps=()
    
    for cmd in git curl; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${RC}"
        echo -e "${YELLOW}Please install the missing dependencies and try again.${RC}"
        log "ERROR" "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

# Improved network connectivity check
check_network() {
    echo -e "${YELLOW}Checking network connectivity...${RC}"
    
    # Try multiple methods for better reliability
    if command_exists curl; then
        if curl -s --connect-timeout 10 --max-time 15 https://api.github.com/repos/digitalxs/dxsbash >/dev/null 2>&1; then
            return 0
        fi
    elif command_exists wget; then
        if wget --spider --timeout=15 --tries=2 https://github.com/digitalxs/dxsbash >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Fallback to ping
    if ping -c 1 -W 5 github.com >/dev/null 2>&1; then
        return 0
    fi
    
    echo -e "${RED}Error: Cannot connect to GitHub. Please check your internet connection.${RC}"
    log "ERROR" "Network connectivity check failed"
    return 1
}

# Detect currently used shell with improved logic
detect_current_shell() {
    echo -e "${BLUE}Detecting current shell configuration...${RC}"
    
    # Check for existing symlinks to determine active shell
    if [ -L "$HOME/.bashrc" ] && [ "$(readlink "$HOME/.bashrc" 2>/dev/null)" = "$DXSBASH_DIR/.bashrc" ]; then
        DETECTED_SHELL="bash"
    elif [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc" 2>/dev/null)" = "$DXSBASH_DIR/.zshrc" ]; then
        DETECTED_SHELL="zsh"
    elif [ -L "$HOME/.config/fish/config.fish" ] && [ "$(readlink "$HOME/.config/fish/config.fish" 2>/dev/null)" = "$DXSBASH_DIR/config.fish" ]; then
        DETECTED_SHELL="fish"
    else
        # Fallback to detecting based on current shell
        CURRENT_SHELL=$(basename "${SHELL:-/bin/bash}")
        case "$CURRENT_SHELL" in
            bash|zsh|fish)
                DETECTED_SHELL="$CURRENT_SHELL"
                ;;
            *)
                DETECTED_SHELL="bash"
                echo -e "${YELLOW}Could not determine shell type. Defaulting to bash.${RC}"
                ;;
        esac
    fi
    
    echo -e "${BLUE}Detected shell: ${CYAN}$DETECTED_SHELL${RC}"
    log "INFO" "Detected shell: $DETECTED_SHELL"
}

# Function to get current installed version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0"
    else
        echo "0.0.0"
    fi
}

# Function to get latest version from repository with better error handling
get_latest_version() {
    local remote_version=""
    
    # Try to get version from GitHub API first (more reliable)
    if command_exists curl; then
        remote_version=$(curl -s --connect-timeout 10 --max-time 15 \
            "https://raw.githubusercontent.com/digitalxs/dxsbash/main/version.txt" 2>/dev/null | tr -d '[:space:]')
    elif command_exists wget; then
        remote_version=$(wget -qO- --timeout=15 \
            "https://raw.githubusercontent.com/digitalxs/dxsbash/main/version.txt" 2>/dev/null | tr -d '[:space:]')
    fi
    
    # Validate version format (should be like X.Y.Z)
    if [[ "$remote_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$remote_version"
        return 0
    else
        # Fallback: try git ls-remote to check if repository is accessible
        if git ls-remote --quiet https://github.com/digitalxs/dxsbash.git HEAD >/dev/null 2>&1; then
            echo "$(get_current_version)"
            log "WARN" "Could not fetch remote version, but repository is accessible"
            return 1
        else
            echo "$(get_current_version)"
            log "ERROR" "Repository not accessible"
            return 1
        fi
    fi
}

# Fixed version comparison function
version_gt() {
    # Returns 0 (true) if $1 is greater than $2
    if [ "$1" = "$2" ]; then
        return 1  # Equal versions
    fi
    
    local sorted_versions
    sorted_versions=$(printf '%s\n%s' "$1" "$2" | sort -V)
    local highest_version
    highest_version=$(echo "$sorted_versions" | tail -n1)
    
    [ "$highest_version" = "$1" ]
}

# Function to create safer backups
create_backup() {
    local source_dir="$1"
    local backup_name="dxsbash_backup_$(date +%Y%m%d_%H%M%S)_$$"
    local backup_path="$LINUXTOOLBOXDIR/$backup_name"
    
    echo -e "${YELLOW}Creating backup at $backup_path${RC}"
    
    if cp -r "$source_dir" "$backup_path" 2>/dev/null; then
        echo "$backup_path"
        log "INFO" "Created backup at $backup_path"
        return 0
    else
        echo -e "${RED}Failed to create backup${RC}"
        log "ERROR" "Failed to create backup at $backup_path"
        return 1
    fi
}

# Function to get current git branch
get_current_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null)
    fi
    echo "${branch:-main}"
}

# Function to get list of all repository files
get_repository_files() {
    # Get all tracked files in the repository
    git ls-files 2>/dev/null | grep -v '^\.git' || true
}

# Function to update all repository files locally
update_all_repository_files() {
    local user_home="$1"
    local dxsbash_dir="$2"
    
    echo -e "${CYAN}Updating ALL repository files locally...${RC}"
    
    # Change to repository directory
    if ! cd "$dxsbash_dir" 2>/dev/null; then
        echo -e "${RED}Error: Cannot access dxsbash directory${RC}"
        return 1
    fi
    
    # Get list of all repository files
    local repo_files
    repo_files=$(get_repository_files)
    
    if [ -z "$repo_files" ]; then
        echo -e "${YELLOW}Warning: Could not get repository file list${RC}"
        return 1
    fi
    
    local updated_count=0
    local total_files=0
    local shell_configs=0
    local app_configs=0
    local scripts_updated=0
    local docs_found=0
    
    # Count total files for progress indication
    total_files=$(echo "$repo_files" | wc -l)
    echo -e "${BLUE}Found $total_files files in repository to process${RC}"
    
    # Process each file in the repository
    while IFS= read -r file; do
        # Skip if file doesn't exist (might be deleted in remote)
        if [ ! -f "$dxsbash_dir/$file" ]; then
            continue
        fi
        
        # Determine where this file should be linked/copied based on its location
        local target_path=""
        local should_link=false
        local file_category=""
        
        case "$file" in
            # Shell configuration files - these get symlinked to home
            ".bashrc"|".zshrc"|".bash_aliases"|".bashrc_help"|".zshrc_help")
                target_path="$user_home/$file"
                should_link=true
                file_category="shell_config"
                ;;
            
            # Fish configuration
            "config.fish")
                mkdir -p "$user_home/.config/fish"
                target_path="$user_home/.config/fish/config.fish"
                should_link=true
                file_category="fish_config"
                ;;
            "fish_help")
                mkdir -p "$user_home/.config/fish"
                target_path="$user_home/.config/fish/fish_help"
                should_link=true
                file_category="fish_config"
                ;;
            
            # Starship configuration
            "starship.toml")
                mkdir -p "$user_home/.config"
                target_path="$user_home/.config/starship.toml"
                should_link=true
                file_category="app_config"
                ;;
            
            # Fastfetch configuration
            "config.jsonc")
                mkdir -p "$user_home/.config/fastfetch"
                target_path="$user_home/.config/fastfetch/config.jsonc"
                should_link=true
                file_category="app_config"
                ;;
            
            # Konsole profile
            "DXSBash.profile")
                mkdir -p "$user_home/.local/share/konsole"
                target_path="$user_home/.local/share/konsole/DXSBash.profile"
                should_link=true
                file_category="terminal_config"
                ;;
            
            # Executable scripts - these stay in the repository but get updated
            "setup.sh"|"updater.sh"|"clean.sh"|"install.sh"|"reset-"*".sh"|"dxsbash-utils.sh")
                # These files are already in the right place (repository)
                # Just ensure they're executable
                chmod +x "$dxsbash_dir/$file" 2>/dev/null
                file_category="executable_script"
                echo -e "${GREEN}  ✓ Updated permissions for $file${RC}"
                ;;
            
            # Documentation and metadata files - these stay in repository
            "README.md"|"CHANGELOG.md"|"LICENSE"|"CONTRIBUTING.md"|"SECURITY.md"|"commands.md"|"version.txt")
                # These files are already in the right place
                file_category="documentation"
                echo -e "${CYAN}  ℹ  Documentation: $file (repository)${RC}"
                ;;
            
            # Configuration files that stay in repository
            ".github/"*|".vscode/"*|"*.yml"|"*.yaml")
                # These stay in the repository directory
                file_category="repo_config"
                echo -e "${CYAN}  ℹ  Repository config: $file${RC}"
                ;;
            
            # Any other files - categorize and log them
            *)
                file_category="unprocessed"
                echo -e "${DIM}  Skipping: $file (unprocessed file type)${RC}"
                continue
                ;;
        esac
        
        # If we have a target path, update the file
        if [ -n "$target_path" ] && [ "$should_link" = true ]; then
            if update_file_link "$dxsbash_dir/$file" "$target_path" "$file"; then
                ((updated_count++))
                case "$file_category" in
                    "shell_config"|"fish_config") ((shell_configs++)) ;;
                    "app_config"|"terminal_config") ((app_configs++)) ;;
                esac
            fi
        elif [ "$file_category" = "executable_script" ]; then
            ((scripts_updated++))
        elif [ "$file_category" = "documentation" ]; then
            ((docs_found++))
        fi
        
    done <<< "$repo_files"
    
    echo -e "${GREEN}✓ Repository synchronization completed${RC}"
    echo -e "${BLUE}━━━ SYNC SUMMARY ━━━${RC}"
    echo -e "${GREEN}  • Shell configurations: $shell_configs updated${RC}"
    echo -e "${GREEN}  • Application configs: $app_configs updated${RC}"
    echo -e "${GREEN}  • Executable scripts: $scripts_updated processed${RC}"
    echo -e "${CYAN}  • Documentation files: $docs_found found${RC}"
    echo -e "${BLUE}  • Total files linked: $updated_count${RC}"
    echo -e "${BLUE}  • Total files processed: $total_files${RC}"
    log "INFO" "Updated $updated_count repository files locally"
    
    return 0
}

# Function to update shell configurations with better error handling
update_shell_configs() {
    local user_home="$1"
    local dxsbash_dir="$2"
    local detected_shell="$3"

    echo -e "${YELLOW}Updating shell configurations for $detected_shell...${RC}"
    
    case "$detected_shell" in
        bash)
            update_file_link "$dxsbash_dir/.bashrc" "$user_home/.bashrc" "Bash config" || return 1
            update_file_link "$dxsbash_dir/.bashrc_help" "$user_home/.bashrc_help" "Bash help" || true
            update_file_link "$dxsbash_dir/.bash_aliases" "$user_home/.bash_aliases" "Bash aliases" || true
            ;;
        zsh)
            update_file_link "$dxsbash_dir/.zshrc" "$user_home/.zshrc" "Zsh config" || return 1
            update_file_link "$dxsbash_dir/.zshrc_help" "$user_home/.zshrc_help" "Zsh help" || true
            ;;
        fish)
            mkdir -p "$user_home/.config/fish"
            update_file_link "$dxsbash_dir/config.fish" "$user_home/.config/fish/config.fish" "Fish config" || return 1
            update_file_link "$dxsbash_dir/fish_help" "$user_home/.config/fish/fish_help" "Fish help" || true
            ;;
        *)
            echo -e "${RED}Unknown shell type: $detected_shell${RC}"
            log "ERROR" "Unknown shell type: $detected_shell"
            return 1
            ;;
    esac
    
    # Update common configurations
    mkdir -p "$user_home/.config"
    update_file_link "$dxsbash_dir/starship.toml" "$user_home/.config/starship.toml" "Starship config" || true
    
    # Update Fastfetch configuration if it exists
    if [ -f "$dxsbash_dir/config.jsonc" ]; then
        mkdir -p "$user_home/.config/fastfetch"
        update_file_link "$dxsbash_dir/config.jsonc" "$user_home/.config/fastfetch/config.jsonc" "Fastfetch config" || true
    fi
    
    log "INFO" "Updated shell configurations for $detected_shell"
    return 0
}

# Helper function to update file links safely
update_file_link() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [ ! -f "$source" ]; then
        echo -e "${YELLOW}Warning: Source file $source not found for $description${RC}"
        return 1
    fi
    
    # Create target directory if needed
    local target_dir
    target_dir=$(dirname "$target")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir" 2>/dev/null || {
            echo -e "${RED}  ✗ Failed to create directory for $description${RC}"
            return 1
        }
    fi
    
    # Remove existing file/link
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -f "$target"
    fi
    
    # Create new symlink
    if ln -sf "$source" "$target" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Updated $description${RC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to update $description${RC}"
        return 1
    fi
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
        if update_file_link "$dxsbash_dir/DXSBash.profile" "$user_home/.local/share/konsole/DXSBash.profile" "Konsole profile"; then
            # Update konsolerc
            update_konsole_default_profile "$user_home/.config/konsolerc"
            # Update yakuakerc if it exists
            if [ -f "$user_home/.config/yakuakerc" ]; then
                echo -e "${YELLOW}  Updating Yakuake configuration...${RC}"
                update_konsole_default_profile "$user_home/.config/yakuakerc"
            fi
        fi
    fi
}

# Helper function to update Konsole/Yakuake default profile
update_konsole_default_profile() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        if grep -q "DefaultProfile=" "$config_file"; then
            sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$config_file"
        else
            echo "DefaultProfile=DXSBash.profile" >> "$config_file"
        fi
    fi
}

# Enhanced privilege escalation detection
detect_sudo_command() {
    if command_exists sudo && sudo -n true 2>/dev/null; then
        echo "sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        echo "doas"
    elif command_exists su; then
        echo "su -c"
    else
        echo -e "${RED}Error: No suitable privilege escalation method found${RC}"
        log "ERROR" "No suitable privilege escalation method found"
        exit 1
    fi
}

# Main update function with improved error handling and complete file sync
update_dxsbash() {
    echo -e "${YELLOW}Starting dxsbash update process...${RC}"
    log "INFO" "Starting dxsbash update (updater version: $UPDATER_VERSION)"
    
    # Validate dxsbash directory
    if [ ! -d "$DXSBASH_DIR" ]; then
        echo -e "${RED}Error: dxsbash directory not found at $DXSBASH_DIR${RC}"
        log "ERROR" "dxsbash directory not found at $DXSBASH_DIR"
        return 1
    fi
    
    # Change to dxsbash directory
    if ! cd "$DXSBASH_DIR"; then
        echo -e "${RED}Error: Cannot access dxsbash directory${RC}"
        log "ERROR" "Cannot access dxsbash directory"
        return 1
    fi
    
    # Create backup before any changes
    local backup_dir
    backup_dir=$(create_backup "$DXSBASH_DIR")
    if [ -z "$backup_dir" ]; then
        echo -e "${RED}Error: Failed to create backup. Aborting update.${RC}"
        return 1
    fi
    
    # Store versions
    local old_version
    old_version=$(get_current_version)
    log "INFO" "Current version: $old_version"
    
    # Detect shell configuration
    detect_current_shell
    local SHELL_TYPE="$DETECTED_SHELL"
    
    # Get current branch
    local current_branch
    current_branch=$(get_current_branch)
    echo -e "${BLUE}Current branch: $current_branch${RC}"
    
    # Check for local modifications
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo -e "${YELLOW}Local modifications detected. Stashing changes...${RC}"
        git stash push -m "dxsbash-updater-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || {
            echo -e "${RED}Warning: Could not stash local changes${RC}"
        }
    fi
    
    # Attempt to update repository
    echo -e "${YELLOW}Fetching latest changes from repository...${RC}"
    if ! git fetch origin "$current_branch" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Could not fetch from origin, trying default remote...${RC}"
        git fetch 2>/dev/null || {
            echo -e "${RED}Error: Could not fetch updates from repository${RC}"
            restore_from_backup "$backup_dir"
            return 1
        }
    fi
    
    # Perform the actual pull
    if git pull origin "$current_branch" 2>/dev/null || git pull 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully updated dxsbash repository${RC}"
        log "INFO" "Git pull successful"
        
        # Get new version
        local new_version
        new_version=$(get_current_version)
        echo -e "${GREEN}Updated from version ${YELLOW}$old_version${GREEN} to ${YELLOW}$new_version${RC}"
        log "INFO" "Updated from version $old_version to $new_version"
        
        # Detect and set sudo command
        local sudo_cmd
        sudo_cmd=$(detect_sudo_command)
        
        # Update ALL repository files locally - this is the main enhancement
        echo -e "${CYAN}━━━ UPDATING ALL REPOSITORY FILES ━━━${RC}"
        if ! update_all_repository_files "$HOME" "$DXSBASH_DIR"; then
            echo -e "${RED}Warning: Some repository files failed to update${RC}"
        fi
        
        # Update shell configurations (this might be redundant now, but keep for safety)
        if ! update_shell_configs "$HOME" "$DXSBASH_DIR" "$SHELL_TYPE"; then
            echo -e "${RED}Warning: Some shell configurations failed to update${RC}"
        fi
        
        # Update terminal configurations
        update_konsole_config "$HOME" "$DXSBASH_DIR"
        
        # Update system-wide scripts
        update_system_scripts "$sudo_cmd"
        
        echo -e "${GREEN}✓ Complete repository sync completed successfully!${RC}"
        log "INFO" "Complete repository sync completed successfully"
        echo -e "${YELLOW}To apply changes to your current session, run: source ~/.${SHELL_TYPE}rc${RC}"
        
        # Clean up old backup (keep only recent ones)
        cleanup_old_backups
        
        return 0
    else
        echo -e "${RED}✗ Failed to update dxsbash repository${RC}"
        log "ERROR" "Git pull failed"
        restore_from_backup "$backup_dir"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    local backup_dir="$1"
    
    if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
        echo -e "${YELLOW}Restoring from backup...${RC}"
        rm -rf "$DXSBASH_DIR"
        if mv "$backup_dir" "$DXSBASH_DIR"; then
            echo -e "${GREEN}✓ Restored from backup${RC}"
            log "INFO" "Restored from backup: $backup_dir"
        else
            echo -e "${RED}✗ Failed to restore from backup${RC}"
            log "ERROR" "Failed to restore from backup: $backup_dir"
        fi
    fi
}

# Function to update system-wide scripts
update_system_scripts() {
    local sudo_cmd="$1"
    
    echo -e "${YELLOW}Updating system-wide commands...${RC}"
    
    # Update reset scripts
    local reset_scripts_updated=0
    for script in "reset-bash-profile.sh" "reset-zsh-profile.sh" "reset-fish-profile.sh"; do
        if [ -f "$DXSBASH_DIR/$script" ]; then
            if cp -p "$DXSBASH_DIR/$script" "$LINUXTOOLBOXDIR/" 2>/dev/null && \
               chmod +x "$LINUXTOOLBOXDIR/$script" 2>/dev/null; then
                echo -e "${GREEN}  ✓ Updated $script${RC}"
                ((reset_scripts_updated++))
            else
                echo -e "${YELLOW}  Warning: Could not update $script${RC}"
            fi
        fi
    done
    
    # Create appropriate reset-shell-profile link
    local reset_script="reset-bash-profile.sh"
    case "$DETECTED_SHELL" in
        zsh) [ -f "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" ] && reset_script="reset-zsh-profile.sh" ;;
        fish) [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ] && reset_script="reset-fish-profile.sh" ;;
    esac
    
    # Try to create system-wide reset command with better error handling
    if [ -f "$LINUXTOOLBOXDIR/$reset_script" ]; then
        if $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/$reset_script" /usr/local/bin/reset-shell-profile 2>/dev/null; then
            echo -e "${GREEN}  ✓ Updated reset-shell-profile command${RC}"
        else
            # Try to provide helpful information about why it failed
            if [ ! -d "/usr/local/bin" ]; then
                echo -e "${YELLOW}  ℹ  /usr/local/bin doesn't exist - reset-shell-profile not installed system-wide${RC}"
                echo -e "${YELLOW}  ℹ  You can still use: $LINUXTOOLBOXDIR/$reset_script${RC}"
            elif [ ! -w "/usr/local/bin" ]; then
                echo -e "${YELLOW}  ℹ  No write permission to /usr/local/bin - reset-shell-profile not installed system-wide${RC}"
                echo -e "${YELLOW}  ℹ  You can still use: $LINUXTOOLBOXDIR/$reset_script${RC}"
            else
                echo -e "${YELLOW}  ℹ  Could not create system-wide reset-shell-profile command${RC}"
                echo -e "${YELLOW}  ℹ  You can still use: $LINUXTOOLBOXDIR/$reset_script${RC}"
            fi
        fi
    else
        echo -e "${YELLOW}  Warning: Reset script $reset_script not found${RC}"
    fi
    
    # Update updater script
    if [ -f "$DXSBASH_DIR/updater.sh" ]; then
        if cp -p "$DXSBASH_DIR/updater.sh" "$LINUXTOOLBOXDIR/" 2>/dev/null && \
           chmod +x "$LINUXTOOLBOXDIR/updater.sh" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Updated updater.sh in linuxtoolbox${RC}"
            
            # Try to update system-wide updater command
            if $sudo_cmd ln -sf "$LINUXTOOLBOXDIR/updater.sh" /usr/local/bin/upbashdxs 2>/dev/null; then
                echo -e "${GREEN}  ✓ Updated system-wide updater command (upbashdxs)${RC}"
            else
                # Provide helpful information about alternatives
                if [ ! -d "/usr/local/bin" ]; then
                    echo -e "${YELLOW}  ℹ  /usr/local/bin doesn't exist - upbashdxs not available system-wide${RC}"
                elif [ ! -w "/usr/local/bin" ]; then
                    echo -e "${YELLOW}  ℹ  No write permission to /usr/local/bin - upbashdxs not available system-wide${RC}"
                else
                    echo -e "${YELLOW}  ℹ  Could not create system-wide upbashdxs command${RC}"
                fi
                echo -e "${CYAN}  ℹ  Alternative ways to update dxsbash:${RC}"
                echo -e "${CYAN}    • $LINUXTOOLBOXDIR/updater.sh${RC}"
                echo -e "${CYAN}    • ~/update-dxsbash.sh${RC}"
            fi
            
            # Always try to update home directory shortcut (this should work)
            if ln -sf "$LINUXTOOLBOXDIR/updater.sh" "$HOME/update-dxsbash.sh" 2>/dev/null && \
               chmod +x "$HOME/update-dxsbash.sh" 2>/dev/null; then
                echo -e "${GREEN}  ✓ Updated ~/update-dxsbash.sh shortcut${RC}"
            else
                echo -e "${YELLOW}  Warning: Could not create ~/update-dxsbash.sh shortcut${RC}"
            fi
        else
            echo -e "${YELLOW}  Warning: Could not update updater.sh${RC}"
        fi
    else
        echo -e "${YELLOW}  Warning: updater.sh not found in repository${RC}"
    fi
    
    # Update utilities script
    if [ -f "$DXSBASH_DIR/dxsbash-utils.sh" ]; then
        if cp -p "$DXSBASH_DIR/dxsbash-utils.sh" "$LINUXTOOLBOXDIR/" 2>/dev/null && \
           chmod +x "$LINUXTOOLBOXDIR/dxsbash-utils.sh" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Updated dxsbash-utils.sh${RC}"
        else
            echo -e "${YELLOW}  Warning: Could not update dxsbash-utils.sh${RC}"
        fi
    fi
    
    # Summary of system script updates
    echo -e "${BLUE}  System scripts update summary:${RC}"
    echo -e "${BLUE}    • Reset scripts: $reset_scripts_updated updated${RC}"
    echo -e "${BLUE}    • Updater available at: $LINUXTOOLBOXDIR/updater.sh${RC}"
    if command -v upbashdxs &> /dev/null; then
        echo -e "${BLUE}    • System-wide updater: upbashdxs (available)${RC}"
    else
        echo -e "${BLUE}    • System-wide updater: not available (use alternatives above)${RC}"
    fi
}

# Function to clean up old backups (keep only 3 most recent)
cleanup_old_backups() {
    local backup_count
    backup_count=$(find "$LINUXTOOLBOXDIR" -maxdepth 1 -name "dxsbash_backup_*" -type d | wc -l)
    
    if [ "$backup_count" -gt 3 ]; then
        echo -e "${YELLOW}Cleaning up old backups (keeping 3 most recent)...${RC}"
        find "$LINUXTOOLBOXDIR" -maxdepth 1 -name "dxsbash_backup_*" -type d -printf '%T@ %p\n' | \
            sort -n | head -n -3 | cut -d' ' -f2- | \
            while read -r old_backup; do
                rm -rf "$old_backup" 2>/dev/null && \
                    echo -e "${GREEN}  ✓ Removed old backup: $(basename "$old_backup")${RC}"
            done
    fi
}

# Main function with comprehensive error handling
main() {
    echo -e "${CYAN}DXSBash Updater v$UPDATER_VERSION${RC}"
    echo -e "${CYAN}Enhanced Complete Repository Sync${RC}"
    echo -e "${CYAN}Checking for dxsbash updates...${RC}"
    log "INFO" "Starting update check (updater version: $UPDATER_VERSION)"
    
    # Check dependencies
    check_dependencies
    
    # Check network connectivity
    if ! check_network; then
        exit 1
    fi
    
    # Check if dxsbash directory exists
    if [ ! -d "$DXSBASH_DIR" ]; then
        echo -e "${RED}Error: dxsbash directory not found at $DXSBASH_DIR${RC}"
        log "ERROR" "dxsbash directory not found at $DXSBASH_DIR"
        echo -e "${YELLOW}Run the installer first:${RC}"
        echo -e "${WHITE}curl -fsSL https://raw.githubusercontent.com/digitalxs/dxsbash/main/install.sh | bash${RC}"
        exit 1
    fi
    
    # Get current and latest versions
    local current_version latest_version
    current_version=$(get_current_version)
    echo -e "${BLUE}Current version: ${YELLOW}$current_version${RC}"
    
    latest_version=$(get_latest_version)
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Latest version: ${GREEN}$latest_version${RC}"
    else
        echo -e "${YELLOW}Warning: Could not determine latest version. Proceeding with repository check...${RC}"
        latest_version="$current_version"
    fi
    
    # Compare versions and decide whether to update
    if [ "$current_version" = "$latest_version" ]; then
        echo -e "${GREEN}✓ You already have the latest version of dxsbash.${RC}"
        log "INFO" "Already at latest version: $current_version"
        
        # Ask if user wants to force a complete sync anyway
        echo ""
        read -p "Do you want to force a complete repository sync anyway? (y/N): " -r force_sync
        echo ""
        
        if [[ "$force_sync" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            echo -e "${YELLOW}🔄 Performing forced complete repository sync...${RC}"
            if update_dxsbash; then
                echo -e "${GREEN}🎉 Complete repository sync completed successfully${RC}"
                log "INFO" "Forced complete repository sync completed"
            else
                echo -e "${RED}❌ Repository sync failed. Please check the logs and try again.${RC}"
                log "ERROR" "Forced repository sync failed"
                exit 1
            fi
        else
            echo -e "${YELLOW}No changes made.${RC}"
            log "INFO" "User declined forced sync"
        fi
    elif version_gt "$latest_version" "$current_version"; then
        echo -e "${YELLOW}📦 A newer version is available: $current_version → $latest_version${RC}"
        log "INFO" "Update available: $current_version → $latest_version"
        
        # Ask for user confirmation
        echo ""
        read -p "Do you want to proceed with the update? (y/N): " -r confirm
        echo ""
        
        if [[ "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            if update_dxsbash; then
                echo -e "${GREEN}🎉 dxsbash has been successfully updated to version $latest_version${RC}"
                echo -e "${CYAN}━━━ UPDATE SUMMARY ━━━${RC}"
                echo -e "${GREEN}✓ All repository files synchronized locally${RC}"
                echo -e "${GREEN}✓ Shell configurations updated${RC}"
                echo -e "${GREEN}✓ System scripts updated${RC}"
                echo -e "${GREEN}✓ Terminal configurations updated${RC}"
                echo -e "${YELLOW}Don't forget to reload your shell: source ~/.bashrc (or ~/.zshrc, ~/.config/fish/config.fish)${RC}"
                log "INFO" "Update completed successfully to version $latest_version"
            else
                echo -e "${RED}❌ Update failed. Please check the logs and try again.${RC}"
                log "ERROR" "Update process failed"
                exit 1
            fi
        else
            echo -e "${YELLOW}Update cancelled by user.${RC}"
            log "INFO" "Update cancelled by user"
        fi
    else
        echo -e "${BLUE}ℹ️  You have a development version ($current_version) which is newer than the latest release ($latest_version).${RC}"
        log "INFO" "Running development version: $current_version"
        
        # Ask if user wants to sync anyway for development versions
        echo ""
        read -p "Do you want to sync with the repository anyway? (y/N): " -r dev_sync
        echo ""
        
        if [[ "$dev_sync" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            echo -e "${YELLOW}🔄 Syncing development version with repository...${RC}"
            if update_dxsbash; then
                echo -e "${GREEN}🎉 Development version synchronized successfully${RC}"
                log "INFO" "Development version sync completed"
            else
                echo -e "${RED}❌ Development sync failed. Please check the logs and try again.${RC}"
                log "ERROR" "Development sync failed"
                exit 1
            fi
        else
            echo -e "${YELLOW}No changes made.${RC}"
            log "INFO" "User declined development sync"
        fi
    fi
}

# Set error handling
set -e
trap 'echo -e "${RED}An unexpected error occurred. Check the logs for details.${RC}"; log "ERROR" "Script terminated unexpectedly at line $LINENO"' ERR

# Run the main function
main "$@"
