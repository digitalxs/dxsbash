                ;;
            fish)
                if [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ]; then
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-shell-profile > /dev/null 2>&1
                else
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile > /dev/null 2>&1
                    warning_message "Using bash reset script as fallback for fish"
                fi
                ;;
        esac
        
        if [ -f "/usr/local/bin/reset-shell-profile" ]; then
            stop_spinner "success" "Reset scripts installed successfully"
            success_message "You can reset your shell configuration with: sudo reset-shell-profile [username]"
        else
            stop_spinner "error" "Failed to install reset scripts"
        fi
    else
        error_message "Reset script not found in $GITPATH"
        warning_message "Reset functionality will not be available"
    fi
    
    update_progress "Reset script installation complete"
}

# Install updater command
installUpdaterCommand() {
    section_header "Installing Updater Command"
    
    # Copy the updater script to the linuxtoolbox directory
    if [ -f "$GITPATH/updater.sh" ]; then
        start_spinner "Installing updater script..."
        
        # Use cp -p to preserve permissions from source
        cp -p "$GITPATH/updater.sh" "$LINUXTOOLBOXDIR/" > /dev/null 2>&1
        # Ensure it's executable regardless of source permissions
        chmod +x "$LINUXTOOLBOXDIR/updater.sh" > /dev/null 2>&1
        
        # Create a symbolic link to make it available system-wide
        ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/updater.sh" /usr/local/bin/upbashdxs > /dev/null 2>&1
        
        if [ -f "/usr/local/bin/upbashdxs" ]; then
            stop_spinner "success" "Updater script installed successfully"
            success_message "You can update DXSBash anytime by running: upbashdxs"
        else
            stop_spinner "error" "Failed to install updater script"
        fi
    else
        error_message "Updater script not found in $GITPATH"
        warning_message "Update functionality will not be available"
    fi
    
    update_progress "Updater command installation complete"
}

# Set up the repository
setup_repository() {
    section_header "Setting Up Repository"
    
    # Check if the linuxtoolbox directory exists
    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        start_spinner "Creating linuxtoolbox directory..."
        mkdir -p "$LINUXTOOLBOXDIR" > /dev/null 2>&1
        stop_spinner "success" "Created linuxtoolbox directory: $LINUXTOOLBOXDIR"
    else
        success_message "Linuxtoolbox directory already exists"
    fi
    
    # Clone the repository
    if [ -d "$LINUXTOOLBOXDIR/dxsbash" ]; then
        start_spinner "Removing existing dxsbash directory..."
        rm -rf "$LINUXTOOLBOXDIR/dxsbash" > /dev/null 2>&1
        stop_spinner "success" "Removed existing dxsbash directory"
    fi
    
    start_spinner "Cloning DXSBash repository..."
    git clone https://github.com/digitalxs/dxsbash "$LINUXTOOLBOXDIR/dxsbash" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        stop_spinner "success" "Successfully cloned DXSBash repository"
        cd "$LINUXTOOLBOXDIR/dxsbash" || exit 1
        GITPATH="$LINUXTOOLBOXDIR/dxsbash"
    else
        stop_spinner "error" "Failed to clone DXSBash repository"
        error_message "Installation cannot continue"
        exit 1
    fi
    
    update_progress "Repository setup complete"
}

# Create symlink to updater in home directory
create_updater_symlink() {
    section_header "Creating Update Shortcut"
    
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    start_spinner "Creating updater shortcut in home directory..."
    ln -sf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh" > /dev/null 2>&1
    
    if [ -f "$USER_HOME/update-dxsbash.sh" ]; then
        chmod +x "$USER_HOME/update-dxsbash.sh" > /dev/null 2>&1
        stop_spinner "success" "Created updater shortcut: ~/update-dxsbash.sh"
    else
        stop_spinner "warning" "Failed to create updater shortcut"
        warning_message "You can still update using the upbashdxs command"
    fi
    
    update_progress "Update shortcut creation complete"
}

# Display installation summary
show_summary() {
    section_header "Installation Summary"
    
    echo -e "  ${BRIGHT_GREEN}${BOLD}DXSBash has been successfully installed!${RESET}"
    echo
    echo -e "  ${BLUE}●${RESET} ${WHITE}Selected shell:${RESET} ${BRIGHT_YELLOW}$SELECTED_SHELL${RESET}"
    echo -e "  ${BLUE}●${RESET} ${WHITE}Installation directory:${RESET} ${BRIGHT_YELLOW}$LINUXTOOLBOXDIR/dxsbash${RESET}"
    echo -e "  ${BLUE}●${RESET} ${WHITE}Configuration files:${RESET} ${BRIGHT_YELLOW}~/.${SELECTED_SHELL}rc${RESET}"
    echo
    echo -e "  ${WHITE}${BOLD}Available commands:${RESET}"
    echo -e "  ${BRIGHT_GREEN}▸${RESET} ${BRIGHT_WHITE}upbashdxs${RESET}           - Update DXSBash to latest version"
    echo -e "  ${BRIGHT_GREEN}▸${RESET} ${BRIGHT_WHITE}reset-shell-profile${RESET} - Reset to default shell configuration"
    echo -e "  ${BRIGHT_GREEN}▸${RESET} ${BRIGHT_WHITE}help${RESET}                - Show DXSBash help and commands"
    echo
    echo -e "  ${WHITE}${BOLD}Next steps:${RESET}"
    echo -e "  ${BRIGHT_YELLOW}1.${RESET} ${WHITE}Log out and log back in to start using your new shell${RESET}"
    echo -e "  ${BRIGHT_YELLOW}2.${RESET} ${WHITE}Or run this command to use it right now:${RESET} ${BRIGHT_GREEN}exec $SELECTED_SHELL${RESET}"
    echo
    
    show_elapsed_time
}

# Main function to run the installation
main() {
    clear
    show_logo
    
    # Setup progress tracking
    TOTAL_STEPS=13  # Increased by 1 for the Starship configuration step
    CURRENT_STEP=0
    
    # Start installation process
    setup_repository
    checkEnv
    detectDistro
    selectShell
    installDepend
    installStarshipAndFzf
    installZoxide
    install_additional_dependencies
    create_fastfetch_config
    setupShellConfig
    ensure_starship_in_configs  # Added this step
    setDefaultShell
    installResetScript
    installUpdaterCommand
    configure_kde_terminal_emulators
    create_updater_symlink
    show_summary
}

# Run main function
main "$@"    if command_exists nvim; then
        stop_spinner "success" "Neovim installed successfully"
    else
        stop_spinner "error" "Failed to install Neovim"
        error_message "Manual installation may be required"
    fi
    
    update_progress "Neovim installation complete"
}

# Create Fastfetch configuration
create_fastfetch_config() {
    section_header "Setting Up System Information Display"
    
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    subsection_header "Configuring Fastfetch"
    
    if ! command_exists fastfetch; then
        warning_message "Fastfetch not found, installation will be skipped"
        info_message "You can install it later for system information display"
        update_progress "Fastfetch configuration skipped"
        return
    fi
    
    start_spinner "Setting up Fastfetch configuration..."
    
    if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch" > /dev/null 2>&1
    fi
    
    # Check if the fastfetch config file exists
    if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        rm -f "$USER_HOME/.config/fastfetch/config.jsonc" > /dev/null 2>&1
    fi
    
    ln -sf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" > /dev/null 2>&1
    
    if [ -f "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        stop_spinner "success" "Fastfetch configured successfully"
    else
        stop_spinner "error" "Failed to create symbolic link for fastfetch config"
    fi
    
    update_progress "Fastfetch configuration complete"
}

# Initialize Fedora Zsh plugins
init_fedora_zsh_plugins() {
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Handle Fedora/RHEL zsh plugins which might be in different locations
    if [ "$PACKAGER" = "dnf" ] && [ "$SELECTED_SHELL" = "zsh" ]; then
        subsection_header "Setting Up Zsh Plugins for Fedora/RHEL"
        
        # Add plugin sourcing to .zshrc if files exist
        ZSH_PLUGIN_DIR="/usr/share/zsh/plugins"
        
        start_spinner "Creating plugin loader configuration..."
        
        # Create plugin loader function
        cat > "$USER_HOME/.zsh_plugins" <<EOL
# Generated by dxsbash setup for Fedora/RHEL
# Load Zsh plugins if available

# Autosuggestions
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
EOL
        
        stop_spinner "success" "Created plugin loader configuration"
        
        # Try to install plugins manually if they're not found in standard locations
        if [ ! -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
            start_spinner "Installing Zsh autosuggestions plugin..."
            PLUGIN_DIR="$USER_HOME/.zsh/plugins"
            mkdir -p "$PLUGIN_DIR" > /dev/null 2>&1
            git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions" > /dev/null 2>&1
            
            # Add to .zsh_plugins
            echo "# Manual installation" >> "$USER_HOME/.zsh_plugins"
            echo "source $PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$USER_HOME/.zsh_plugins"
            stop_spinner "success" "Installed Zsh autosuggestions plugin"
        fi
        
        if [ ! -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
            start_spinner "Installing Zsh syntax highlighting plugin..."
            PLUGIN_DIR="$USER_HOME/.zsh/plugins"
            mkdir -p "$PLUGIN_DIR" > /dev/null 2>&1
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting" > /dev/null 2>&1
            
            # Add to .zsh_plugins
            echo "source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$USER_HOME/.zsh_plugins"
            stop_spinner "success" "Installed Zsh syntax highlighting plugin"
        fi
        
        success_message "Zsh plugins configured for Fedora/RHEL"
    fi
}

# Set up shell configuration
setupShellConfig() {
    section_header "Setting Up Shell Configuration"
    
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Make sure all required directories exist
    mkdir -p "$USER_HOME/.config/fish" > /dev/null 2>&1
    mkdir -p "$USER_HOME/.zsh" > /dev/null 2>&1
    
    info_message "Setting up configuration for $SELECTED_SHELL"
    
    # Backup existing config files
    if [ "$SELECTED_SHELL" = "bash" ]; then
        subsection_header "Configuring Bash"
        
        if [ -e "$USER_HOME/.bashrc" ]; then
            BACKUP_FILE="$USER_HOME/.bashrc.bak"
            if [ -e "$BACKUP_FILE" ]; then
                TIMESTAMP=$(date +%Y%m%d%H%M%S)
                BACKUP_FILE="$USER_HOME/.bashrc.bak.$TIMESTAMP"
            fi
            start_spinner "Backing up existing bash configuration..."
            if mv "$USER_HOME/.bashrc" "$BACKUP_FILE" > /dev/null 2>&1; then
                stop_spinner "success" "Backed up existing .bashrc to $BACKUP_FILE"
            else
                stop_spinner "warning" "Could not backup .bashrc, continuing anyway"
            fi
        fi
        
        # Link Bash config
        start_spinner "Setting up bash configuration files..."
        
        ln -sf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" > /dev/null 2>&1 && \
        ln -sf "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help" > /dev/null 2>&1
        
        if [ -f "$USER_HOME/.bashrc" ] && [ -f "$USER_HOME/.bashrc_help" ]; then
            stop_spinner "success" "Bash configuration set up successfully"
        else
            stop_spinner "error" "Failed to set up bash configuration"
            exit 1
        fi
        
        # Link aliases file if it exists
        if [ -f "$GITPATH/.bash_aliases" ]; then
            start_spinner "Setting up bash aliases..."
            ln -sf "$GITPATH/.bash_aliases" "$USER_HOME/.bash_aliases" > /dev/null 2>&1
            
            if [ -f "$USER_HOME/.bash_aliases" ]; then
                stop_spinner "success" "Bash aliases set up successfully"
            else
                stop_spinner "warning" "Failed to set up bash aliases"
            fi
        fi
        
    elif [ "$SELECTED_SHELL" = "zsh" ]; then
        subsection_header "Configuring Zsh"
        
        if [ -e "$USER_HOME/.zshrc" ]; then
            BACKUP_FILE="$USER_HOME/.zshrc.bak"
            if [ -e "$BACKUP_FILE" ]; then
                TIMESTAMP=$(date +%Y%m%d%H%M%S)
                BACKUP_FILE="$USER_HOME/.zshrc.bak.$TIMESTAMP"
            fi
            start_spinner "Backing up existing zsh configuration..."
            if mv "$USER_HOME/.zshrc" "$BACKUP_FILE" > /dev/null 2>&1; then
                stop_spinner "success" "Backed up existing .zshrc to $BACKUP_FILE"
            else
                stop_spinner "warning" "Could not backup .zshrc, continuing anyway"
            fi
        fi
        
        # Link Zsh config
        start_spinner "Setting up zsh configuration files..."
        
        ln -sf "$GITPATH/.zshrc" "$USER_HOME/.zshrc" > /dev/null 2>&1 && \
        ln -sf "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" > /dev/null 2>&1
        
        if [ -f "$USER_HOME/.zshrc" ] && [ -f "$USER_HOME/.zshrc_help" ]; then
            stop_spinner "success" "Zsh configuration set up successfully"
        else
            stop_spinner "error" "Failed to set up zsh configuration"
            exit 1
        fi
        
        # Install Oh My Zsh if not already installed
        if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
            start_spinner "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
            
            if [ -d "$USER_HOME/.oh-my-zsh" ]; then
                stop_spinner "success" "Oh My Zsh installed successfully"
            else
                stop_spinner "error" "Failed to install Oh My Zsh"
            fi
        else
            success_message "Oh My Zsh is already installed"
        fi
        
        # Setup Fedora/RHEL specific Zsh plugins
        init_fedora_zsh_plugins
        
        # Add plugin sourcing to .zshrc if it exists
        if [ -f "$USER_HOME/.zsh_plugins" ]; then
            # Add source line to .zshrc if not already present
            if ! grep -q "source ~/.zsh_plugins" "$USER_HOME/.zshrc"; then
                info_message "Adding plugins to .zshrc"
                echo "" >> "$USER_HOME/.zshrc"
                echo "# Source plugins" >> "$USER_HOME/.zshrc"
                echo "[ -f ~/.zsh_plugins ] && source ~/.zsh_plugins" >> "$USER_HOME/.zshrc"
                success_message "Added plugin configuration to .zshrc"
            fi
        fi
        
        # Link aliases file if it exists
        if [ -f "$GITPATH/.bash_aliases" ]; then
            start_spinner "Setting up zsh aliases..."
            ln -sf "$GITPATH/.bash_aliases" "$USER_HOME/.zsh_aliases" > /dev/null 2>&1
            
            if [ -f "$USER_HOME/.zsh_aliases" ]; then
                stop_spinner "success" "Zsh aliases set up successfully"
                
                # Add source line to .zshrc if not already present
                if ! grep -q "source ~/.zsh_aliases" "$USER_HOME/.zshrc"; then
                    echo "" >> "$USER_HOME/.zshrc"
                    echo "# Source aliases" >> "$USER_HOME/.zshrc"
                    echo "[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases" >> "$USER_HOME/.zshrc"
                    success_message "Added aliases configuration to .zshrc"
                fi
            else
                stop_spinner "warning" "Failed to set up zsh aliases"
            fi
        fi
        
    elif [ "$SELECTED_SHELL" = "fish" ]; then
        subsection_header "Configuring Fish"
        
        if [ -e "$USER_HOME/.config/fish/config.fish" ]; then
            BACKUP_DIR="$USER_HOME/.config/fish/backup"
            mkdir -p "$BACKUP_DIR" > /dev/null 2>&1
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            BACKUP_FILE="$BACKUP_DIR/config.fish.$TIMESTAMP"
            
            start_spinner "Backing up existing fish configuration..."
            if mv "$USER_HOME/.config/fish/config.fish" "$BACKUP_FILE" > /dev/null 2>&1; then
                stop_spinner "success" "Backed up existing config.fish to $BACKUP_FILE"
            else
                stop_spinner "warning" "Could not backup config.fish, continuing anyway"
            fi
        fi
        
        # Link Fish config
        start_spinner "Setting up fish configuration files..."
        
        ln -sf "$GITPATH/config.fish" "$USER_HOME/.config/fish/config.fish" > /dev/null 2>&1 && \
        ln -sf "$GITPATH/fish_help" "$USER_HOME/.config/fish/fish_help" > /dev/null 2>&1
        
        if [ -f "$USER_HOME/.config/fish/config.fish" ] && [ -f "$USER_HOME/.config/fish/fish_help" ]; then
            stop_spinner "success" "Fish configuration set up successfully"
        else
            stop_spinner "error" "Failed to set up fish configuration"
            exit 1
        fi
        
        # Setup Fisher plugin manager if not already installed
        if ! fish -c "type -q fisher" 2>/dev/null; then
            start_spinner "Installing Fisher plugin manager for Fish..."
            fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" > /dev/null 2>&1
            
            if fish -c "type -q fisher" 2>/dev/null; then
                stop_spinner "success" "Fisher plugin manager installed"
                
                # Install useful plugins
                start_spinner "Installing Fish plugins..."
                fish -c "fisher install PatrickF1/fzf.fish" > /dev/null 2>&1
                fish -c "fisher install jethrokuan/z" > /dev/null 2>&1
                fish -c "fisher install IlanCosman/tide@v5" > /dev/null 2>&1
                stop_spinner "success" "Fish plugins installed successfully"
            else
                stop_spinner "error" "Failed to install Fisher plugin manager"
            fi
        else
            success_message "Fisher plugin manager is already installed"
        fi
        
        # Convert aliases if bash_aliases exists
        if [ -f "$GITPATH/.bash_aliases" ]; then
            start_spinner "Converting Bash aliases to Fish..."
            FISH_ALIASES_DIR="$USER_HOME/.config/fish/conf.d"
            mkdir -p "$FISH_ALIASES_DIR" > /dev/null 2>&1
            
            # Create a fish_aliases.fish file
            FISH_ALIASES_FILE="$FISH_ALIASES_DIR/aliases.fish"
            echo "# Generated from .bash_aliases by dxsbash setup" > "$FISH_ALIASES_FILE"
            echo "" >> "$FISH_ALIASES_FILE"
            
            # Convert bash aliases to fish format
            # This is a simple conversion that handles basic cases
            grep "^alias" "$GITPATH/.bash_aliases" | sed "s/^alias //" | 
            sed "s/='\(.*\)'$/\" = '\1'/g" | sed "s/=\(.*\)$/\" = \1/g" | 
            sed "s/^/alias \"/" >> "$FISH_ALIASES_FILE"
            
            if [ -f "$FISH_ALIASES_FILE" ]; then
                stop_spinner "success" "Fish aliases created at $FISH_ALIASES_FILE"
            else
                stop_spinner "warning" "Failed to set up fish aliases"
            fi
        fi
    fi
    
    # Link starship.toml for all shells
    start_spinner "Setting up Starship prompt configuration..."
    mkdir -p "$USER_HOME/.config" > /dev/null 2>&1
    ln -sf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" > /dev/null 2>&1
    
    if [ -f "$USER_HOME/.config/starship.toml" ]; then
        stop_spinner "success" "Starship prompt configured successfully"
    else
        stop_spinner "error" "Failed to set up Starship prompt configuration"
    fi
    
    update_progress "Shell configuration complete"
}

# Ensure all shells use Starship prompt
ensure_starship_in_configs() {
    section_header "Configuring Starship Prompt"
    
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Install Starship if not already installed
    if ! command_exists starship; then
        start_spinner "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh > /dev/null 2>&1
        
        if command_exists starship; then
            stop_spinner "success" "Starship prompt installed successfully"
        else
            stop_spinner "error" "Failed to install Starship prompt"
            error_message "Starship prompt configuration will be skipped"
            return 1
        fi
    else
        success_message "Starship prompt is already installed"
    fi
    
    # Link starship.toml for all shells
    start_spinner "Setting up Starship prompt configuration..."
    mkdir -p "$USER_HOME/.config" > /dev/null 2>&1
    ln -sf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" > /dev/null 2>&1
    
    if [ ! -f "$USER_HOME/.config/starship.toml" ]; then
        stop_spinner "error" "Failed to set up Starship prompt configuration"
        return 1
    else
        stop_spinner "success" "Starship prompt configuration linked successfully"
    fi
    
    # Add Starship initialization to Bash
    if [ -f "$USER_HOME/.bashrc" ]; then
        subsection_header "Adding Starship to Bash"
        
        # Check if Starship is already initialized in .bashrc
        if ! grep -q "starship init bash" "$USER_HOME/.bashrc"; then
            start_spinner "Adding Starship initialization to .bashrc..."
            # Add the initialization line
            echo -e '\n# Initialize Starship prompt\neval "$(starship init bash)"' >> "$USER_HOME/.bashrc"
            stop_spinner "success" "Added Starship to Bash configuration"
        else
            success_message "Starship already configured in Bash"
        fi
    fi
    
    # Add Starship initialization to Zsh
    if [ -f "$USER_HOME/.zshrc" ]; then
        subsection_header "Adding Starship to Zsh"
        
        # Check if Starship is already initialized in .zshrc
        if ! grep -q "starship init zsh" "$USER_HOME/.zshrc"; then
            start_spinner "Adding Starship initialization to .zshrc..."
            # Add the initialization line
            echo -e '\n# Initialize Starship prompt\neval "$(starship init zsh)"' >> "$USER_HOME/.zshrc"
            stop_spinner "success" "Added Starship to Zsh configuration"
        else
            success_message "Starship already configured in Zsh"
        fi
    fi
    
    # Add Starship initialization to Fish
    if [ -f "$USER_HOME/.config/fish/config.fish" ]; then
        subsection_header "Adding Starship to Fish"
        
        # Check if Starship is already initialized in config.fish
        if ! grep -q "starship init fish" "$USER_HOME/.config/fish/config.fish"; then
            start_spinner "Adding Starship initialization to config.fish..."
            # Add the initialization line
            echo -e '\n# Initialize Starship prompt\nstarship init fish | source' >> "$USER_HOME/.config/fish/config.fish"
            stop_spinner "success" "Added Starship to Fish configuration"
        else
            success_message "Starship already configured in Fish"
        fi
    fi
    
    success_message "Starship prompt is now configured for all shells"
    update_progress "Starship prompt configuration complete"
}

# Set default shell
setDefaultShell() {
    section_header "Setting Default Shell"
    
    SHELL_PATH=""
    case "$SELECTED_SHELL" in
        bash)
            SHELL_PATH=$(which bash)
            ;;
        zsh)
            SHELL_PATH=$(which zsh)
            ;;
        fish)
            SHELL_PATH=$(which fish)
            ;;
    esac
    
    if [ -z "$SHELL_PATH" ]; then
        error_message "Could not find path to $SELECTED_SHELL"
        warning_message "Please set your default shell manually"
        update_progress "Default shell setting skipped"
        return 1
    fi
    
    # Check if the shell is in /etc/shells
    if ! grep -q "^$SHELL_PATH$" /etc/shells; then
        start_spinner "Adding $SHELL_PATH to /etc/shells..."
        echo "$SHELL_PATH" | ${SUDO_CMD} tee -a /etc/shells > /dev/null
        stop_spinner "success" "Added $SHELL_PATH to /etc/shells"
    else
        success_message "$SHELL_PATH is already in /etc/shells"
    fi
    
    # Change the default shell
    start_spinner "Setting $SELECTED_SHELL as your default shell..."
    ${SUDO_CMD} chsh -s "$SHELL_PATH" "$USER" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        stop_spinner "success" "Default shell set to $SELECTED_SHELL"
    else
        stop_spinner "error" "Failed to set default shell"
        warning_message "Please set your default shell manually with:"
        cmd_message "chsh -s $SHELL_PATH"
    fi
    
    update_progress "Default shell configuration complete"
}

# Configure KDE terminal emulators
configure_kde_terminal_emulators() {
    section_header "Configuring Terminal Emulators"
    
    # Check if running in KDE environment
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || command_exists konsole; then
        success_message "KDE environment detected"
        
        # Get user home directory
        USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
        
        # Configure Konsole
        if command_exists konsole; then
            subsection_header "Configuring Konsole"
            
            # Create Konsole profile directory if it doesn't exist
            KONSOLE_DIR="$USER_HOME/.local/share/konsole"
            mkdir -p "$KONSOLE_DIR" > /dev/null 2>&1
            
            # Create/update Konsole profile with FiraCode Nerd Font
            PROFILE_NAME="DXSBash.profile"
            PROFILE_PATH="$KONSOLE_DIR/$PROFILE_NAME"
            
            # Create profile file
            start_spinner "Creating Konsole profile with FiraCode Nerd Font..."
            
            cat > "$PROFILE_PATH" << EOL
[Appearance]
ColorScheme=Breeze
Font=FiraCode Nerd Font,12,-1,5,50,0,0,0,0,0

[General]
Name=DXSBash
Parent=FALLBACK/
TerminalCenter=false
TerminalMargin=1

[Scrolling]
HistoryMode=2
ScrollBarPosition=2

[Terminal Features]
BlinkingCursorEnabled=true
EOL
            
            # Make sure permissions are correct
            chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$PROFILE_PATH" > /dev/null 2>&1
            
            if [ -f "$PROFILE_PATH" ]; then
                stop_spinner "success" "Konsole profile created successfully"
            else
                stop_spinner "error" "Failed to create Konsole profile"
                update_progress "Konsole configuration skipped"
                return
            fi
            
            # Create/update Konsole configuration to use the new profile by default
            KONSOLERC="$USER_HOME/.config/konsolerc"
            
            start_spinner "Setting DXSBash as default Konsole profile..."
            
            if [ -f "$KONSOLERC" ]; then
                # If konsolerc exists, update or add the DefaultProfile line
                if grep -q "DefaultProfile=" "$KONSOLERC"; then
                    # Replace existing DefaultProfile line
                    sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$KONSOLERC" > /dev/null 2>&1
                else
                    # Add DefaultProfile line if it doesn't exist
                    echo "DefaultProfile=DXSBash.profile" >> "$KONSOLERC"
                fi
            else
                # Create a new konsolerc file if it doesn't exist
                cat > "$KONSOLERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[MainWindow]
MenuBar=Disabled
ToolBarsMovable=Disabled

[TabBar]
NewTabButton=true
EOL
            fi
            
            chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$KONSOLERC" > /dev/null 2>&1
            
            if [ -f "$KONSOLERC" ] && grep -q "DefaultProfile=DXSBash.profile" "$KONSOLERC"; then
                stop_spinner "success" "Set DXSBash as default Konsole profile"
            else
                stop_spinner "warning" "Could not set DXSBash as default Konsole profile"
            fi
            
            success_message "Konsole configured to use FiraCode Nerd Font"
        else
            info_message "Konsole not found, configuration skipped"
        fi
        
        # Configure Yakuake if installed
        if command_exists yakuake; then
            subsection_header "Configuring Yakuake"
            
            # Yakuake uses the same profiles as Konsole, so we just need to update yakuakerc
            USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
            YAKUAKERC="$USER_HOME/.config/yakuakerc"
            
            start_spinner "Setting DXSBash as default Yakuake profile..."
            
            if [ -f "$YAKUAKERC" ]; then
                # If yakuakerc exists, update or add the DefaultProfile line
                if grep -q "DefaultProfile=" "$YAKUAKERC"; then
                    # Replace existing DefaultProfile line
                    sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$YAKUAKERC" > /dev/null 2>&1
                else
                    # Add DefaultProfile line if it doesn't exist
                    echo "DefaultProfile=DXSBash.profile" >> "$YAKUAKERC"
                fi
            else
                # Create new yakuakerc
                mkdir -p "$USER_HOME/.config" > /dev/null 2>&1
                cat > "$YAKUAKERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[Dialogs]
FirstRun=false

[Window]
KeepOpen=false
EOL
            fi
            
            chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$YAKUAKERC" > /dev/null 2>&1
            
            if [ -f "$YAKUAKERC" ] && grep -q "DefaultProfile=DXSBash.profile" "$YAKUAKERC"; then
                stop_spinner "success" "Set DXSBash as default Yakuake profile"
            else
                stop_spinner "warning" "Could not set DXSBash as default Yakuake profile"
            fi
            
            success_message "Yakuake configured to use FiraCode Nerd Font"
        else
            info_message "Yakuake not found, configuration skipped"
        fi
    else
        info_message "KDE environment not detected, terminal emulator configuration skipped"
    fi
    
    update_progress "Terminal emulator configuration complete"
}

# Install reset script
installResetScript() {
    section_header "Installing Reset Script"
    
    # Copy the reset script to the linuxtoolbox directory
    if [ -f "$GITPATH/reset-bash-profile.sh" ]; then
        start_spinner "Installing reset scripts..."
        
        cp "$GITPATH/reset-bash-profile.sh" "$LINUXTOOLBOXDIR/" > /dev/null 2>&1
        chmod +x "$LINUXTOOLBOXDIR/reset-bash-profile.sh" > /dev/null 2>&1
        
        # Copy for other shells if available
        if [ -f "$GITPATH/reset-zsh-profile.sh" ]; then
            cp "$GITPATH/reset-zsh-profile.sh" "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" > /dev/null 2>&1
            chmod +x "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" > /dev/null 2>&1
        fi
        
        if [ -f "$GITPATH/reset-fish-profile.sh" ]; then
            cp "$GITPATH/reset-fish-profile.sh" "$LINUXTOOLBOXDIR/reset-fish-profile.sh" > /dev/null 2>&1
            chmod +x "$LINUXTOOLBOXDIR/reset-fish-profile.sh" > /dev/null 2>&1
        fi
        
        # Create a symbolic link for the appropriate reset script based on selected shell
        case "$SELECTED_SHELL" in
            bash)
                ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile > /dev/null 2>&1
                ;;
            zsh)
                if [ -f "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" ]; then
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" /usr/local/bin/reset-shell-profile > /dev/null 2>&1
                else
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile > /dev/null 2>&1
                    warning_message "Using bash reset script as fallback for zsh"
                fi
                #!/bin/bash
#
# DXSBash Setup Script
# A beautiful and functional shell environment installer
#

# Ensure bash is used
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Terminal colors and formatting
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"

# Foreground colors
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"

# Background colors
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

# Clear the screen
clear

# Variables
CONFIGDIR="$HOME/.config"
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
GITPATH=""
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
SELECTED_SHELL=""
DISTRO=""
INSTALL_START_TIME=$(date +%s)

# Progress animation variables
SPIN_PID=""
CURRENT_STEP=0
TOTAL_STEPS=13

# DXSBash ASCII art logo with color
show_logo() {
    echo -e "${BRIGHT_BLUE}"
    cat << "EOF"
 ____  __  __ ____  ____   __   ____  _   _ 
|  _ \ \ \/ // ___|| __ ) / /\ / /  \| | | |
| | | | \  / \___ \|  _ \| |\ V /| |_|| |_| |
| |_| | /  \  ___) | |_) | | | | |___|  _  |
|____/ /_/\_\|____/|____/|_| |_|\____|_| |_|
                                            
EOF
    echo -e "${RESET}"
    echo -e "${CYAN}${BOLD}====================================================${RESET}"
    echo -e "${BRIGHT_WHITE}${BOLD}          Enhanced Shell Environment Installer${RESET}"
    echo -e "${CYAN}${BOLD}====================================================${RESET}"
    echo
}

# Print a formatted section header
section_header() {
    echo
    echo -e "${CYAN}${BOLD}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${RESET}"
    echo -e "   ${BRIGHT_WHITE}${BOLD}$1${RESET}"
    echo -e "${CYAN}${BOLD}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${RESET}"
}

# Print a formatted subsection header
subsection_header() {
    echo -e "  ${BRIGHT_YELLOW}${BOLD}$1${RESET}"
    echo -e "  ${BRIGHT_BLACK}${DIM}$(printf '%.s─' $(seq 1 50))${RESET}"
}

# Print a formatted info message
info_message() {
    echo -e "  ${BLUE}●${RESET} ${WHITE}$1${RESET}"
}

# Print a formatted success message
success_message() {
    echo -e "  ${GREEN}✓${RESET} ${WHITE}$1${RESET}"
}

# Print a formatted warning message
warning_message() {
    echo -e "  ${YELLOW}⚠${RESET} ${YELLOW}$1${RESET}"
}

# Print a formatted error message
error_message() {
    echo -e "  ${RED}✗${RESET} ${RED}$1${RESET}"
}

# Print a formatted command
cmd_message() {
    echo -e "    ${DIM}${BRIGHT_BLACK}\$ $1${RESET}"
}

# Print a task status
task_status() {
    local status=$1
    local message=$2
    
    case $status in
        "pending")
            echo -e "  ${BLUE}○${RESET} ${DIM}$message${RESET}"
            ;;
        "success")
            echo -e "  ${GREEN}✓${RESET} ${GREEN}$message${RESET}"
            ;;
        "warning")
            echo -e "  ${YELLOW}⚠${RESET} ${YELLOW}$message${RESET}"
            ;;
        "error")
            echo -e "  ${RED}✗${RESET} ${RED}$message${RESET}"
            ;;
    esac
}

# Update progress bar
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))
    
    echo -ne "\r  ${BLUE}[${BRIGHT_BLUE}"
    printf "%${completed}s" | tr " " "■"
    echo -ne "${BLUE}"
    printf "%${remaining}s" | tr " " "□"
    echo -ne "${BLUE}]${RESET} ${WHITE}${BOLD}${percent}%${RESET} $1"
}

# Spinner animation for long-running tasks
start_spinner() {
    local message=$1
    local i=1
    local sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    echo -ne "  ${BLUE}${sp:0:1}${RESET} ${DIM}$message${RESET}"
    
    (
        while :; do
            echo -ne "\r  ${BLUE}${sp:i++%${#sp}:1}${RESET} ${DIM}$message${RESET}"
            sleep 0.1
        done
    ) &
    
    SPIN_PID=$!
}

# Stop spinner animation
stop_spinner() {
    local status=$1
    local message=$2
    
    if [ -n "$SPIN_PID" ]; then
        kill -9 $SPIN_PID 2>/dev/null
        wait $SPIN_PID 2>/dev/null
        SPIN_PID=""
    fi
    
    echo -ne "\r"
    
    case $status in
        "success")
            success_message "$message"
            ;;
        "warning")
            warning_message "$message"
            ;;
        "error")
            error_message "$message"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Display elapsed time
show_elapsed_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - INSTALL_START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    
    echo
    echo -e "  ${BRIGHT_BLACK}${DIM}Installation completed in ${minutes}m ${seconds}s${RESET}"
}

# Check environment requirements
checkEnv() {
    section_header "Checking Environment"
    
    ## Check for requirements.
    subsection_header "Verifying Requirements"
    REQUIREMENTS='curl groups git'
    local missing_req=""
    
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            missing_req="$missing_req $req"
        else
            success_message "Found required tool: $req"
        fi
    done
    
    if [ -n "$missing_req" ]; then
        error_message "Missing required tools:$missing_req"
        echo
        echo -e "  ${RED}${BOLD}Error: Required tools missing. Please install them first.${RESET}"
        exit 1
    fi

    ## Check Package Handler
    subsection_header "Detecting Package Manager"
    PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
    
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            success_message "Using package manager: $PACKAGER"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        error_message "No supported package manager found"
        exit 1
    fi

    ## Check for sudo or alternatives
    subsection_header "Setting Up Privilege Escalation"
    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi
    success_message "Using $SUDO_CMD for privilege escalation"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        error_message "Current directory is not writable"
        exit 1
    fi
    success_message "Current directory is writable"

    ## Check SuperUser Group
    subsection_header "Verifying Permissions"
    SUPERUSERGROUP='wheel sudo root'
    local found_group=0
    
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            success_message "Found superuser group: $SUGROUP"
            found_group=1
            break
        fi
    done

    if [ $found_group -eq 0 ]; then
        warning_message "No superuser group found. Some operations might fail."
    fi
    
    update_progress "Environment check complete"
}

# Detect distribution
detectDistro() {
    section_header "Detecting Linux Distribution"
    
    # Detect the specific distribution for better handling
    DISTRO="unknown"
    
    # Distribution icons
    local debian_icon="${BRIGHT_RED}⬢${RESET}"
    local fedora_icon="${BRIGHT_BLUE}⬢${RESET}"
    local arch_icon="${BRIGHT_CYAN}⬢${RESET}"
    local suse_icon="${BRIGHT_GREEN}⬢${RESET}"
    local generic_icon="${BRIGHT_WHITE}⬢${RESET}"
    
    if [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
        success_message "${fedora_icon} Detected Fedora Linux"
    elif [ -f /etc/redhat-release ]; then
        if grep -q "CentOS" /etc/redhat-release; then
            DISTRO="centos"
            success_message "${fedora_icon} Detected CentOS Linux"
        elif grep -q "Red Hat Enterprise Linux" /etc/redhat-release; then
            DISTRO="rhel"
            success_message "${fedora_icon} Detected Red Hat Enterprise Linux"
        else
            DISTRO="redhat-based"
            success_message "${fedora_icon} Detected Red Hat-based Linux"
        fi
    elif [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
        DISTRO="ubuntu"
        success_message "${debian_icon} Detected Ubuntu Linux"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        success_message "${debian_icon} Detected Debian Linux"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        success_message "${arch_icon} Detected Arch Linux"
    elif [ -f /etc/SuSE-release ] || [ -f /etc/opensuse-release ]; then
        DISTRO="suse"
        success_message "${suse_icon} Detected SUSE Linux"
    else
        # Generic detection
        if command_exists apt; then
            DISTRO="debian-based"
            success_message "${debian_icon} Detected Debian-based Linux"
        elif command_exists dnf; then
            DISTRO="fedora-based"
            success_message "${fedora_icon} Detected Fedora-based Linux"
        elif command_exists pacman; then
            DISTRO="arch-based"
            success_message "${arch_icon} Detected Arch-based Linux"
        elif command_exists zypper; then
            DISTRO="suse-based"
            success_message "${suse_icon} Detected SUSE-based Linux"
        else
            warning_message "${generic_icon} Unknown distribution, using generic settings"
        fi
    fi
    
    update_progress "Distribution detection complete"
}

# Select preferred shell
selectShell() {
    section_header "Shell Selection"
    
    # Shell icons
    local bash_icon="${YELLOW}⬢${RESET}"
    local zsh_icon="${MAGENTA}⬢${RESET}"
    local fish_icon="${BRIGHT_BLUE}⬢${RESET}"
    
    echo -e "  ${WHITE}Please select your preferred shell:${RESET}"
    echo
    echo -e "  ${BOLD}${bash_icon} 1)${RESET} ${YELLOW}Bash${RESET}    - ${DIM}Default shell, available everywhere${RESET}"
    echo -e "  ${BOLD}${zsh_icon} 2)${RESET} ${MAGENTA}Zsh${RESET}     - ${DIM}Enhanced features, plugins, completions${RESET}"
    echo -e "  ${BOLD}${fish_icon} 3)${RESET} ${BRIGHT_BLUE}Fish${RESET}    - ${DIM}User-friendly, modern syntax${RESET}"
    echo
    
    # Default to bash if no selection is made
    SELECTED_SHELL="bash"
    
    read -p "  ${BRIGHT_GREEN}Enter your choice [1-3] (default: 1):${RESET} " shell_choice
    
    case "$shell_choice" in
        2)
            SELECTED_SHELL="zsh"
            if command_exists zsh; then
                success_message "Selected Zsh as preferred shell"
            else
                info_message "Zsh will be installed during setup"
            fi
            ;;
        3)
            SELECTED_SHELL="fish"
            if command_exists fish; then
                success_message "Selected Fish as preferred shell"
            else
                info_message "Fish will be installed during setup"
            fi
            ;;
        *)
            SELECTED_SHELL="bash"
            success_message "Selected Bash as preferred shell"
            ;;
    esac
    
    update_progress "Shell selection complete"
}

# Install dependencies
installDepend() {
    section_header "Installing Dependencies"
    
    ## Check for dependencies.
    subsection_header "Preparing Package Lists"
    
    COMMON_DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nano zoxide fzf pwgen'
    
    # Shell-specific dependencies
    ZSH_DEPENDENCIES="zsh"
    FISH_DEPENDENCIES="fish"
    
    # Combine dependencies based on the selected shell and distribution
    DEPENDENCIES="$COMMON_DEPENDENCIES"
    
    # Add distribution-specific packages
    if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
        DEPENDENCIES="$DEPENDENCIES nala plocate trash-cli powerline"
        info_message "Added Debian/Ubuntu specific packages"
    elif [ "$PACKAGER" = "dnf" ]; then
        DEPENDENCIES="$DEPENDENCIES dnf-plugins-core dnf-utils mlocate trash-cli powerline"
        info_message "Added Fedora/RHEL specific packages"
    elif [ "$PACKAGER" = "pacman" ]; then
        DEPENDENCIES="$DEPENDENCIES plocate trash-cli powerline"
        info_message "Added Arch Linux specific packages"
    fi
    
    # Add shell-specific dependencies
    if [ "$SELECTED_SHELL" = "zsh" ]; then
        DEPENDENCIES="$DEPENDENCIES $ZSH_DEPENDENCIES"
        
        # Add distribution-specific Zsh plugins
        if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
            DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
            info_message "Added Zsh plugins for Debian/Ubuntu"
        elif [ "$PACKAGER" = "dnf" ]; then
            # Fedora/RHEL package names may differ
            if ${SUDO_CMD} dnf list zsh-autosuggestions &>/dev/null; then
                DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions"
            fi
            if ${SUDO_CMD} dnf list zsh-syntax-highlighting &>/dev/null; then
                DEPENDENCIES="$DEPENDENCIES zsh-syntax-highlighting"
            fi
            info_message "Added Zsh plugins for Fedora/RHEL"
        elif [ "$PACKAGER" = "pacman" ]; then
            DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
            info_message "Added Zsh plugins for Arch Linux"
        fi
    elif [ "$SELECTED_SHELL" = "fish" ]; then
        DEPENDENCIES="$DEPENDENCIES $FISH_DEPENDENCIES"
        info_message "Added Fish shell packages"
    fi
    
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
        info_message "Added Neovim editor"
    fi
    
    subsection_header "Installing Packages"
    start_spinner "Updating package repositories..."
    
    # Update repositories first
    if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
        ${SUDO_CMD} $PACKAGER update -y > /dev/null 2>&1
        stop_spinner "success" "Package repositories updated"
    elif [ "$PACKAGER" = "dnf" ]; then
        ${SUDO_CMD} $PACKAGER check-update -y > /dev/null 2>&1 || true  # dnf returns 100 if updates available
        stop_spinner "success" "Package repositories updated"
    elif [ "$PACKAGER" = "pacman" ]; then
        ${SUDO_CMD} $PACKAGER -Sy > /dev/null 2>&1
        stop_spinner "success" "Package repositories updated"
    else
        stop_spinner "warning" "Skipping repository update for $PACKAGER"
    fi
    
    # Install packages
    start_spinner "Installing required packages..."
    
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel > /dev/null 2>&1
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git > /dev/null 2>&1
            ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git > /dev/null 2>&1
            cd yay-git && makepkg --noconfirm -si > /dev/null 2>&1
            success_message "Installed AUR helper: yay"
            AUR_HELPER="yay"
        else
            if command_exists yay; then
                AUR_HELPER="yay"
            else
                AUR_HELPER="paru"
            fi
            success_message "Using existing AUR helper: $AUR_HELPER"
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES} > /dev/null 2>&1
    elif [ "$PACKAGER" = "nala" ] || [ "$PACKAGER" = "apt" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES} > /dev/null 2>&1
    elif [ "$PACKAGER" = "dnf" ]; then
        # Fedora-specific handling
        # Check for EPEL repository if on RHEL/CentOS
        if [ -f /etc/redhat-release ] && ! grep -q "Fedora" /etc/redhat-release; then
            if ! ${SUDO_CMD} ${PACKAGER} list installed epel-release > /dev/null 2>&1; then
                ${SUDO_CMD} ${PACKAGER} install -y epel-release > /dev/null 2>&1
                success_message "Installed EPEL repository"
            fi
        fi
        
        # Install RPM Fusion repositories for Fedora
        if grep -q "Fedora" /etc/redhat-release 2>/dev/null; then
            if ! ${SUDO_CMD} ${PACKAGER} list installed rpmfusion-free-release > /dev/null 2>&1; then
                ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm > /dev/null 2>&1
                ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm > /dev/null 2>&1
                success_message "Installed RPM Fusion repositories"
            fi
        fi
        
        # Adjust package names for Fedora/RHEL
        FEDORA_DEPENDENCIES=$(echo "$DEPENDENCIES" | sed 's/batcat/bat/g' | sed 's/nala/dnf-utils/g')
        
        # Install Fedora/RHEL packages
        ${SUDO_CMD} ${PACKAGER} install -y $FEDORA_DEPENDENCIES > /dev/null 2>&1
    elif [ "$PACKAGER" = "emerge" ]; then
        ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch > /dev/null 2>&1
        if [ "$SELECTED_SHELL" = "zsh" ]; then
            ${SUDO_CMD} ${PACKAGER} -v app-shells/zsh app-shells/zsh-completions > /dev/null 2>&1
        elif [ "$SELECTED_SHELL" = "fish" ]; then
            ${SUDO_CMD} ${PACKAGER} -v app-shells/fish > /dev/null 2>&1
        fi
    else
        ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES} > /dev/null 2>&1
    fi
    
    stop_spinner "success" "Installed required packages"
    
    # Check installation status
    subsection_header "Verifying Installations"
    
    local missing_packages=""
    for pkg in bash git curl wget; do
        if ! command_exists $pkg; then
            missing_packages="$missing_packages $pkg"
        else
            success_message "Verified: $pkg"
        fi
    done
    
    if [ -n "$missing_packages" ]; then
        warning_message "Some packages might not have installed correctly:$missing_packages"
    fi
    
    # Font installation
    subsection_header "Installing Nerd Font"
    
    FONT_NAME="FiraCode Nerd Font"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        success_message "Font '$FONT_NAME' is already installed"
    else
        start_spinner "Installing font '$FONT_NAME'..."
        
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        # check if the file is accessible
        if wget -q --spider "$FONT_URL"; then
            TEMP_DIR=$(mktemp -d)
            wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip > /dev/null 2>&1
            unzip -q "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR" > /dev/null 2>&1
            mkdir -p "$FONT_DIR"/"$FONT_NAME" > /dev/null 2>&1
            cp "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME" 2>/dev/null || cp "${TEMP_DIR}"/*/*.ttf "$FONT_DIR"/"$FONT_NAME" 2>/dev/null
            # Update the font cache
            fc-cache -fv > /dev/null 2>&1
            # delete the files created from this
            rm -rf "${TEMP_DIR}" > /dev/null 2>&1
            
            stop_spinner "success" "Font '$FONT_NAME' installed successfully"
        else
            stop_spinner "error" "Font URL is not accessible"
        fi
    fi
    
    update_progress "Package installation complete"
}

# Install Starship prompt and FZF
installStarshipAndFzf() {
    section_header "Installing Prompt & Tools"
    
    subsection_header "Setting Up Starship Prompt"
    if command_exists starship; then
        success_message "Starship prompt is already installed"
    else
        start_spinner "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh > /dev/null 2>&1
        
        if command_exists starship; then
            stop_spinner "success" "Starship prompt installed successfully"
        else
            stop_spinner "error" "Failed to install Starship"
            error_message "Manual installation may be required"
            echo
        fi
    fi
    
    subsection_header "Setting Up FZF Fuzzy Finder"
    if command_exists fzf; then
        success_message "FZF is already installed"
    else
        start_spinner "Installing FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf > /dev/null 2>&1
        ~/.fzf/install --all > /dev/null 2>&1
        
        if command_exists fzf; then
            stop_spinner "success" "FZF installed successfully"
        else
            stop_spinner "error" "Failed to install FZF"
            error_message "Manual installation may be required"
            echo
        fi
    fi
    
    update_progress "Tool installation complete"
}

# Install Zoxide directory jumper
installZoxide() {
    section_header "Installing Zoxide Directory Jumper"
    
    if command_exists zoxide; then
        success_message "Zoxide is already installed"
    else
        start_spinner "Installing Zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh > /dev/null 2>&1
        
        if command_exists zoxide; then
            stop_spinner "success" "Zoxide installed successfully"
        else
            stop_spinner "error" "Failed to install Zoxide"
            error_message "Manual installation may be required"
            echo
        fi
    fi
    
    update_progress "Zoxide installation complete"
}

# Install additional dependencies (like Neovim)
install_additional_dependencies() {
    section_header "Installing Neovim Editor"
    
    # Check if Neovim is already installed
    if command_exists nvim; then
        success_message "Neovim is already installed"
        update_progress "Neovim installation complete"
        return
    fi
    
    start_spinner "Installing Neovim..."
    
    case "$PACKAGER" in
        apt|nala)
            if [ ! -d "/opt/neovim" ]; then
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage > /dev/null 2>&1
                chmod u+x nvim.appimage > /dev/null 2>&1
                ./nvim.appimage --appimage-extract > /dev/null 2>&1
                ${SUDO_CMD} mv squashfs-root /opt/neovim > /dev/null 2>&1
                ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim > /dev/null 2>&1
            fi
            ;;
        zypper)
            ${SUDO_CMD} zypper refresh > /dev/null 2>&1
            ${SUDO_CMD} zypper -n install neovim > /dev/null 2>&1
            ;;
        dnf)
            # Check if Neovim is available in standard repositories
            if ${SUDO_CMD} dnf list neovim &>/dev/null; then
                ${SUDO_CMD} dnf install -y neovim > /dev/null 2>&1
            else
                # Try to install from COPR repository if not available
                ${SUDO_CMD} dnf copr enable -y agriffis/neovim-nightly > /dev/null 2>&1
                ${SUDO_CMD} dnf install -y neovim > /dev/null 2>&1
            fi
            ;;
        pacman)
            ${SUDO_CMD} pacman -Syu > /dev/null 2>&1
            ${SUDO_CMD} pacman -S --noconfirm neovim > /dev/null 2>&1
            ;;
        *)
            stop_spinner "error" "No supported package manager found for Neovim"
            warning_message "Please install Neovim manually"
            update_progress "Neovim installation skipped"
            return
            ;;
    esac
    
    if command_exists nvim; then
