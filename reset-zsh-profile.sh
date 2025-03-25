#!/bin/bash
# reset-zsh-profile.sh - Script to reset zsh profile to system defaults
# Usage: sudo ./reset-zsh-profile.sh [username]
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
    
    echo "Resetting zsh profile for user: $username"
    echo "Home directory: $home_dir"
    
    # Create backup directory
    local backup_dir="$home_dir/zsh_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Verify that default files exist in /etc/skel/
    # Note: Zsh typically doesn't have defaults in /etc/skel, so we'll check
    # for the package defaults instead
    local default_zshrc="/etc/zsh/zshrc"
    local default_zprofile="/etc/zsh/zprofile"
    
    if [ ! -f "$default_zshrc" ]; then
        echo "Warning: Default file $default_zshrc not found"
        if [ -f "/usr/share/zsh/zshrc" ]; then
            default_zshrc="/usr/share/zsh/zshrc"
            echo "Using $default_zshrc instead"
        elif [ -f "/etc/zshrc" ]; then
            default_zshrc="/etc/zshrc"
            echo "Using $default_zshrc instead"
        else
            echo "No default zshrc found. Creating minimal default."
            default_zshrc="/tmp/default_zshrc"
            echo "# Default zshrc created by reset-zsh-profile.sh" > "$default_zshrc"
        fi
    fi
    
    # Backup existing files
    echo "Backing up existing files..."
    for file in .zshrc .zshenv .zprofile .zlogin .zlogout .zsh_history .zsh_plugins .zsh_aliases .oh-my-zsh; do
        if [ -e "$home_dir/$file" ]; then
            # If it's a directory, use -r flag for cp
            if [ -d "$home_dir/$file" ]; then
                cp -r "$home_dir/$file" "$backup_dir/" 2>/dev/null || echo "Warning: Could not backup $file"
            else
                cp "$home_dir/$file" "$backup_dir/" 2>/dev/null || echo "Warning: Could not backup $file"
            fi
        fi
    done
    
    # Also backup any Zsh configuration in .config/zsh if it exists
    if [ -d "$home_dir/.config/zsh" ]; then
        mkdir -p "$backup_dir/.config"
        cp -r "$home_dir/.config/zsh" "$backup_dir/.config/" 2>/dev/null || echo "Warning: Could not backup .config/zsh"
    fi
    
    # Check for and remove symlinks and existing files
    for file in .zshrc .zshenv .zprofile .zlogin .zlogout .zsh_plugins .zsh_aliases; do
        if [ -L "$home_dir/$file" ] || [ -f "$home_dir/$file" ]; then
            echo "Removing Zsh configuration file: $file"
            rm -f "$home_dir/$file"
        fi
    done
    
    # Create minimal default files
    echo "Creating default Zsh configuration files..."
    
    # Create minimal .zshrc
    cat > "$home_dir/.zshrc" << EOL
# Default .zshrc created by reset-zsh-profile
# Feel free to customize this file

# Set up basic PATH
export PATH=\$PATH:\$HOME/.local/bin:/usr/local/bin

# Basic history settings
HISTFILE=\$HOME/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# Basic keybindings
bindkey -e  # emacs key bindings

# Basic completion system
autoload -Uz compinit
compinit

# Add your customizations below
EOL
    
    # Create minimal .zshenv if it doesn't exist
    if [ ! -f "$home_dir/.zshenv" ]; then
        cat > "$home_dir/.zshenv" << EOL
# Default .zshenv created by reset-zsh-profile
# Environment variables go here
EOL
    fi
    
    # Set permissions
    echo "Setting correct permissions..."
    for file in .zshrc .zshenv .zprofile .zlogin .zlogout; do
        if [ -f "$home_dir/$file" ]; then
            chown "$username:$(id -gn $username)" "$home_dir/$file"
            chmod 644 "$home_dir/$file"
        fi
    done
    
    # Remove Oh My Zsh if it exists
    if [ -d "$home_dir/.oh-my-zsh" ]; then
        echo "Removing Oh My Zsh installation..."
        # Just move it to backup instead of deleting
        mv "$home_dir/.oh-my-zsh" "$backup_dir/" 2>/dev/null || echo "Warning: Could not move Oh My Zsh to backup"
    fi
    
    echo "
Zsh profile reset completed successfully!
- Backup files are stored in: $backup_dir
- Default files have been created
- Permissions have been set
- Symlinks and custom configurations have been removed

To apply changes, the user should either:
1. Log out and log back in
2. Run: source ~/.zshrc

Note: If you had custom modifications, check the backup files to restore them manually."
}

# Run main script
main "$@"
