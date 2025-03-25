#!/bin/bash
# reset-fish-profile.sh - Script to reset fish shell configuration to defaults
# Usage: sudo ./reset-fish-profile.sh [username]
# Author: Luis Miguel P. Freitas
# Contact me at: luis@digitalxs.ca or https://digitalxs.ca
# YOU ARE ABSOLUTELY FREE TO USE THIS SCRIPT AS YOU WANT. IT'S YOUR RESPONSABILITY ALONE!

# Function to check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Please run as root (use sudo)"
        exit 1
    fi
}

# Function to validate username
validate_user() {
    local username=$1
    if ! id "$username" >/dev/null 2>&1; then
        echo "Error: User '$username' does not exist"
        exit 1
    fi
}

# Function to get user home directory
get_home_dir() {
    local username=$1
    echo "$(getent passwd "$username" | cut -d: -f6)"
}

# Main script
main() {
    # Check if username is provided
    if [ $# -ne 1 ]; then
        echo "Usage: $0 [username]"
        echo "Example: $0 johndoe"
        exit 1
    fi
    
    # Store username
    local username=$1
    
    # Check root privileges
    check_root
    
    # Validate username
    validate_user "$username"
    
    # Get user's home directory
    local home_dir=$(get_home_dir "$username")
    
    echo "Resetting fish shell configuration for user: $username"
    echo "Home directory: $home_dir"
    
    # Fish configuration directory
    local fish_config_dir="$home_dir/.config/fish"
    
    # Create backup directory
    local backup_dir="$home_dir/fish_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir/.config"
    
    # Backup existing fish configuration
    if [ -d "$fish_config_dir" ]; then
        echo "Backing up existing fish configuration..."
        cp -r "$fish_config_dir" "$backup_dir/.config/" 2>/dev/null || echo "Warning: Could not backup fish configuration"
    else
        echo "No existing fish configuration found."
    fi
    
    # Remove existing configuration
    if [ -d "$fish_config_dir" ]; then
        echo "Removing existing fish configuration..."
        rm -rf "$fish_config_dir"
    fi
    
    # Create minimal fish configuration
    echo "Creating default fish configuration..."
    mkdir -p "$fish_config_dir/functions" "$fish_config_dir/conf.d" "$fish_config_dir/completions"
    
    # Create basic config.fish
    cat > "$fish_config_dir/config.fish" << EOL
# Default config.fish created by reset-fish-profile.sh
# Feel free to customize this file

# Set up basic PATH
set -x PATH \$PATH \$HOME/.local/bin /usr/local/bin

# Set basic environment variables
set -x EDITOR nano
set -x VISUAL nano

# Add your customizations below

function fish_greeting
    echo "Welcome to Fish, the friendly interactive shell"
end
EOL
    
    # Create a functions directory with a basic prompt function
    cat > "$fish_config_dir/functions/fish_prompt.fish" << EOL
function fish_prompt
    set -l last_status \$status
    
    # User and hostname
    set_color green
    echo -n (whoami)
    set_color normal
    echo -n '@'
    set_color blue
    echo -n (hostname)
    set_color normal
    
    # Current directory
    set_color yellow
    echo -n ' '(prompt_pwd)
    set_color normal
    
    # Git status if available
    if command -sq git
        set -l git_branch (git branch 2>/dev/null | sed -n '/\* /s///p')
        if test -n "\$git_branch"
            set_color magenta
            echo -n " (\$git_branch)"
            set_color normal
        end
    end
    
    # Status indicator
    if test \$last_status -eq 0
        set_color green
    else
        set_color red
    end
    echo -n " > "
    set_color normal
end
EOL
    
    # Set permissions
    echo "Setting correct permissions..."
    chown -R "$username:$(id -gn $username)" "$fish_config_dir"
    chmod -R 755 "$fish_config_dir"
    
    # Remove fisher and other plugins
    local fisher_functions=(
        "fisher"
        "fish_user_key_bindings"
        "tide"
        "fzf_key_bindings"
    )
    
    for func in "${fisher_functions[@]}"; do
        if [ -f "$fish_config_dir/functions/$func.fish" ]; then
            echo "Removing fish function: $func"
            rm -f "$fish_config_dir/functions/$func.fish"
        fi
    done
    
    # Clean conf.d directory from plugin configurations
    rm -f "$fish_config_dir/conf.d/z.fish" 2>/dev/null
    rm -f "$fish_config_dir/conf.d/fzf.fish" 2>/dev/null
    rm -f "$fish_config_dir/conf.d/tide.fish" 2>/dev/null
    rm -f "$fish_config_dir/conf.d/aliases.fish" 2>/dev/null
    
    echo "
Fish shell configuration reset completed successfully!
- Backup files are stored in: $backup_dir
- Default configuration has been created
- Permissions have been set
- Fisher and plugins have been removed

To apply changes, the user should either:
1. Log out and log back in
2. Start a new fish session

Note: If you had custom modifications, check the backup files to restore them manually."
}

# Run main script
main "$@"
