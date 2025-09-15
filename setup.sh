#!/bin/bash
#=================================================================
# DXSBash - Enhanced Shell Environment for Debian and Ubuntu
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#=================================================================

# Set strict error handling mode
set -e

#=================================================================
# Color definitions for rich terminal output
#=================================================================
RC='\033[0m'          # Reset Color
RED='\033[1;31m'      # Bold Red
YELLOW='\033[1;33m'   # Bold Yellow
GREEN='\033[1;32m'    # Bold Green
BLUE='\033[1;34m'     # Bold Blue
CYAN='\033[1;36m'     # Bold Cyan
WHITE='\033[1;37m'    # Bold White

#=================================================================
# Display welcome banner
#=================================================================
display_banner() {
  echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${BLUE}║                                                        ║${RC}"
  echo -e "${BLUE}║  ${WHITE}██████╗ ██╗  ██╗███████╗██████╗  █████╗ ███████╗██╗  ██╗${BLUE}  ${RC}"
  echo -e "${BLUE}║  ${WHITE}██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║  ██║${BLUE}  ${RC}"
  echo -e "${BLUE}║  ${WHITE}██║  ██║ ╚███╔╝ ███████╗██████╔╝███████║███████╗███████║${BLUE}  ${RC}"
  echo -e "${BLUE}║  ${WHITE}██║  ██║ ██╔██╗ ╚════██║██╔══██╗██╔══██║╚════██║██╔══██║${BLUE}  ${RC}"
  echo -e "${BLUE}║  ${WHITE}██████╔╝██╔╝ ██╗███████║██████╔╝██║  ██║███████║██║  ██║${BLUE}  ${RC}"
  echo -e "${BLUE}║  ${WHITE}╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${BLUE}  ${RC}"
  echo -e "${BLUE}║                                                        ║${RC}"
  echo -e "${BLUE}║  ${CYAN}Enhanced Shell Environment for Debian & Ubuntu${BLUE}        ║${RC}"
  echo -e "${BLUE}║  ${YELLOW}  $(date +%Y) digitalxs.ca${BLUE}                                   ║${RC}"
  echo -e "${BLUE}║                                                        ║${RC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
  echo ""
}

#=================================================================
# Initialize environment and check prerequisites
#=================================================================
initialize() {
  echo -e "${CYAN}▶ Initializing setup...${RC}"

  # Ensure the .config directory exists
  CONFIGDIR="$HOME/.config"
  if [ ! -d "$CONFIGDIR" ]; then
    echo -e "${YELLOW}  Creating .config directory: ${WHITE}$CONFIGDIR${RC}"
    mkdir -p "$CONFIGDIR"
    echo -e "${GREEN}  ✓ .config directory created${RC}"
  fi

  # Check if the linuxtoolbox folder exists, create it if it doesn't
  LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
  if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo -e "${YELLOW}  Creating linuxtoolbox directory: ${WHITE}$LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo -e "${GREEN}  ✓ linuxtoolbox directory created${RC}"
  fi

  # Remove existing dxsbash directory if it exists to ensure clean installation
  if [ -d "$LINUXTOOLBOXDIR/dxsbash" ]; then
    echo -e "${YELLOW}  Cleaning existing installation...${RC}"
    rm -rf "$LINUXTOOLBOXDIR/dxsbash"
    echo -e "${GREEN}  ✓ Environment prepared for fresh installation${RC}"
  fi

  # Clone the repository
  echo -e "${YELLOW}  Cloning DXSBash repository...${RC}"
  git clone https://github.com/digitalxs/dxsbash "$LINUXTOOLBOXDIR/dxsbash"
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Repository cloned successfully${RC}"
  else
    echo -e "${RED}  ✗ Failed to clone repository! Check your internet connection.${RC}"
    exit 1
  fi

  # Change to the repository directory
  cd "$LINUXTOOLBOXDIR/dxsbash" || exit 1
  echo -e "${GREEN}▶ Initialization complete${RC}"
  echo ""
}

# Main variables that will be used across functions
SUDO_CMD=""
GITPATH=""
SELECTED_SHELL=""
IS_DEBIAN_BASED=false

# Display welcome banner
display_banner

# Initialize the environment
initialize

#=================================================================
# Utility functions
#=================================================================
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

#=================================================================
# Environment checking
#=================================================================
checkEnv() {
  echo -e "${CYAN}▶ Checking environment requirements...${RC}"

  ## Check for required tools
  REQUIREMENTS='curl sudo git'
  for req in $REQUIREMENTS; do
    if ! command_exists "$req"; then
      echo -e "${RED}  ✗ Required tool missing: ${WHITE}$req${RC}"
      echo -e "${YELLOW}  Please install the following requirements and try again: ${WHITE}$REQUIREMENTS${RC}"
      exit 1
    fi
  done
  echo -e "${GREEN}  ✓ All required tools are installed${RC}"

  ## Check for privilege escalation tool
  if command_exists sudo; then
    SUDO_CMD="sudo"
  else
    echo -e "${RED}  ✗ sudo is required for this installation${RC}"
    exit 1
  fi
  echo -e "${GREEN}  ✓ Using ${WHITE}$SUDO_CMD${GREEN} for privilege escalation${RC}"

  ## Check if the current directory is writable
  GITPATH=$(dirname "$(realpath "$0")")
  if [ ! -w "$GITPATH" ]; then
    echo -e "${RED}  ✗ Cannot write to directory: ${WHITE}$GITPATH${RC}"
    exit 1
  fi

  ## Ensure user has sudo privileges
  if ! groups | grep -q "sudo"; then
    echo -e "${RED}  ✗ You need to be a member of the ${WHITE}sudo${RED} group to run this script!${RC}"
    exit 1
  fi

  echo -e "${GREEN}▶ Environment check passed${RC}"
  echo ""
}

#=================================================================
# Distribution detection
#=================================================================
detectDistro() {
  echo -e "${CYAN}▶ Detecting Linux distribution...${RC}"

  # Detect if we're on Debian or Ubuntu
  if [ -f /etc/debian_version ]; then
    if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
    echo -e "${GREEN}  ✓ Detected ${WHITE}Ubuntu Linux${RC}"
    IS_DEBIAN_BASED=true
    elif [ -f /etc/debian_version ]; then
    echo -e "${GREEN}  ✓ Detected ${WHITE}Debian Linux${RC}"
    IS_DEBIAN_BASED=true
fi
  else
    echo -e "${RED}  ⚠ Warning: DXSBash is designed specifically for Debian and Ubuntu.${RC}"
    echo -e "${YELLOW}  Your system appears to be running a different distribution.${RC}"
    echo -e "${YELLOW}  Some features may not work as expected.${RC}"
    echo ""
    read -p "  Do you want to continue anyway? (y/N): " continue_install
    if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
      echo -e "${RED}  Installation aborted.${RC}"
      exit 1
    fi
  fi
  echo ""
}

#=================================================================
# Dependency installation
#=================================================================
installDepend() {
  echo -e "${CYAN}▶ Installing dependencies...${RC}"

  ## Check for dependencies.
  COMMON_DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nano zoxide fzf pwgen ripgrep'

  # Shell-specific dependencies
  BASH_DEPENDENCIES=""
  ZSH_DEPENDENCIES="zsh zsh-autosuggestions zsh-syntax-highlighting"
  FISH_DEPENDENCIES="fish"

  # Combine dependencies based on the selected shell
  DEPENDENCIES="$COMMON_DEPENDENCIES nala plocate trash-cli powerline"

  # Add shell-specific dependencies
  if [ "$SELECTED_SHELL" = "zsh" ]; then
    DEPENDENCIES="$DEPENDENCIES $ZSH_DEPENDENCIES"
  elif [ "$SELECTED_SHELL" = "fish" ]; then
    DEPENDENCIES="$DEPENDENCIES $FISH_DEPENDENCIES"
  fi

  if ! command_exists nvim; then
    DEPENDENCIES="${DEPENDENCIES} neovim"
  fi

  echo -e "${YELLOW}  Installing required packages: ${WHITE}$DEPENDENCIES${RC}"
  if [ "$IS_DEBIAN_BASED" = true ]; then
    # First check if nala is installed, if not install it
    if ! command_exists nala; then
      echo -e "${YELLOW}  Installing nala package manager...${RC}"
      ${SUDO_CMD} apt update
      ${SUDO_CMD} apt install -y nala
    fi

    # Use nala for better package management experience
    ${SUDO_CMD} nala update
    ${SUDO_CMD} nala install -y $DEPENDENCIES
  else
    # Fallback to apt if available for non-Debian distros
    if command_exists apt; then
      ${SUDO_CMD} apt update
      ${SUDO_CMD} apt install -y $DEPENDENCIES
    else
      echo -e "${RED}  ✗ Unable to find a supported package manager.${RC}"
      echo -e "${YELLOW}  Please install the following packages manually: ${WHITE}$DEPENDENCIES${RC}"
      read -p "  Press Enter to continue..."
    fi
  fi

  echo -e "${GREEN}  ✓ Dependencies installed successfully${RC}"

  # Check to see if the FiraCode Nerd Font is installed
  FONT_NAME="FiraCode Nerd Font"
  if fc-list | grep -q "FiraCode"; then
    echo -e "${GREEN}  ✓ Font '$FONT_NAME' is already installed${RC}"
  else
    echo -e "${YELLOW}  Installing font '$FONT_NAME'...${RC}"
      FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
      FONT_CHECKSUM="8b3c6e1b5e4f9e4c96c5e8f5a8c5e8f5a8c5e8f5a8c5e8f5a8c5e8f5a8c5e8f5"  # Add actual checksum
      FONT_DIR="$HOME/.local/share/fonts"
    # check if the file is accessible
  if wget -q --spider "$FONT_URL"; then
      TEMP_DIR=$(mktemp -d)
      if wget -q --show-progress $FONT_URL -O "$TEMP_DIR/FiraCode.zip"; then
        # Add checksum verification
        # ACTUAL_CHECKSUM=$(sha256sum "$TEMP_DIR/FiraCode.zip" | cut -d' ' -f1)
        # if [ "$ACTUAL_CHECKSUM" != "$FONT_CHECKSUM" ]; then
        #     echo -e "${RED}  ✗ Font checksum mismatch. Skipping installation.${RC}"
        #     rm -rf "$TEMP_DIR"
        # else
            unzip -q "$TEMP_DIR/FiraCode.zip" -d "$TEMP_DIR"
            mkdir -p "$FONT_DIR/FiraCode"
            mv "$TEMP_DIR"/*.ttf "$FONT_DIR/FiraCode" 2>/dev/null || true
            fc-cache -fv >/dev/null 2>&1
            echo -e "${GREEN}  ✓ Font '$FONT_NAME' installed successfully${RC}"
        # fi
      fi
      rm -rf "$TEMP_DIR"
  else
    echo -e "${YELLOW}  ⚠ Font URL not accessible. Continuing without font.${RC}"
  fi
fi

  echo -e "${GREEN}▶ All dependencies installed${RC}"
  echo ""
}

#=================================================================
# Additional tools installation
#=================================================================
installStarshipAndFzf() {
  echo -e "${CYAN}▶ Installing Starship prompt...${RC}"
  if command_exists starship; then
    echo -e "${GREEN}  ✓ Starship already installed${RC}"
  else
    echo -e "${YELLOW}  Installing Starship prompt...${RC}"
    if curl -sS https://starship.rs/install.sh | sh; then
      echo -e "${GREEN}  ✓ Starship installed successfully${RC}"
    else
      echo -e "${RED}  ✗ Something went wrong during Starship installation!${RC}"
      echo -e "${YELLOW}  Continuing without Starship...${RC}"
    fi
  fi

  echo -e "${CYAN}▶ Installing FZF...${RC}"
  if command_exists fzf; then
    echo -e "${GREEN}  ✓ FZF already installed${RC}"
  else
    echo -e "${YELLOW}  Installing FZF...${RC}"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all >/dev/null
    echo -e "${GREEN}  ✓ FZF installed successfully${RC}"
  fi
  echo ""
}

installZoxide() {
  echo -e "${CYAN}▶ Installing Zoxide...${RC}"
  if command_exists zoxide; then
    echo -e "${GREEN}  ✓ Zoxide already installed${RC}"
    return
  fi

  echo -e "${YELLOW}  Installing Zoxide...${RC}"
  if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
    echo -e "${GREEN}  ✓ Zoxide installed successfully${RC}"
  else
    echo -e "${RED}  ✗ Something went wrong during Zoxide installation!${RC}"
    echo -e "${YELLOW}  Continuing without Zoxide...${RC}"
  fi
  echo ""
}

#=================================================================
# Shell selection dialog
#=================================================================
selectShell() {
  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${CYAN}║             Select your preferred shell:               ║${RC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${RC}"
  echo -e "  ${WHITE}1)${RC} ${GREEN}Bash${RC}      ${YELLOW}(default, most compatible)${RC}"
  echo -e "  ${WHITE}2)${RC} ${GREEN}Zsh${RC}       ${YELLOW}(enhanced features, popular alternative)${RC}"
  echo -e "  ${WHITE}3)${RC} ${GREEN}Fish${RC}      ${YELLOW}(modern, user-friendly, less POSIX-compatible)${RC}"
  echo ""

  # Default to bash if no selection is made
  SELECTED_SHELL="bash"

  read -p "  Enter your choice [1-3] (default: 1): " shell_choice

  case "$shell_choice" in
    2)
      SELECTED_SHELL="zsh"
      ;;
    3)
      SELECTED_SHELL="fish"
      ;;
    *)
      SELECTED_SHELL="bash"
      ;;
  esac

  echo -e "${GREEN}  ✓ Selected shell: ${WHITE}$SELECTED_SHELL${RC}"
  echo ""
}

#=================================================================
# Configuration setup
#=================================================================
create_fastfetch_config() {
  echo -e "${CYAN}▶ Setting up fastfetch configuration...${RC}"
  ## Get the correct user home directory.
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

  if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
    mkdir -p "$USER_HOME/.config/fastfetch"
  fi
  # Check if the fastfetch config file exists
  if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
    rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
  fi
  ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
    echo -e "${RED}  ✗ Failed to create symbolic link for fastfetch config${RC}"
    echo -e "${YELLOW}  Using direct copy instead...${RC}"
    cp -f "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc"
  }
  echo -e "${GREEN}  ✓ Fastfetch configuration set up successfully${RC}"
  echo ""
}

setupShellConfig() {
  echo -e "${CYAN}▶ Setting up shell configuration for ${WHITE}$SELECTED_SHELL${CYAN}...${RC}"

  ## Get the correct user home directory.
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

  # Make sure all required directories exist
  mkdir -p "$USER_HOME/.config/fish"
  mkdir -p "$USER_HOME/.zsh"

  # Backup existing config files and set up new ones based on selected shell
  if [ "$SELECTED_SHELL" = "bash" ]; then
    if [ -e "$USER_HOME/.bashrc" ]; then
      BACKUP_FILE="$USER_HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"
      echo -e "${YELLOW}  Backing up old bash config to ${WHITE}$BACKUP_FILE${RC}"
      cp -f "$USER_HOME/.bashrc" "$BACKUP_FILE"
    fi

    # Link Bash config
    echo -e "${YELLOW}  Creating bash configuration links...${RC}"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
      echo -e "${YELLOW}  Using direct copy for .bashrc...${RC}"
      cp -f "$GITPATH/.bashrc" "$USER_HOME/.bashrc"
    }
    ln -svf "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help" || {
      echo -e "${YELLOW}  Using direct copy for .bashrc_help...${RC}"
      cp -f "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help"
    }

    # Link Bash aliases file
    if [ -f "$GITPATH/.bash_aliases" ]; then
      ln -svf "$GITPATH/.bash_aliases" "$USER_HOME/.bash_aliases" || {
        echo -e "${YELLOW}  Using direct copy for .bash_aliases...${RC}"
        cp -f "$GITPATH/.bash_aliases" "$USER_HOME/.bash_aliases"
      }
      echo -e "${GREEN}  ✓ Added .bash_aliases file${RC}"
    else
      # Create a minimal .bash_aliases file if it doesn't exist in the repository
      echo "# Custom user aliases - Created by dxsbash setup" > "$USER_HOME/.bash_aliases"
      echo "# Add your personal aliases below" >> "$USER_HOME/.bash_aliases"
      echo "" >> "$USER_HOME/.bash_aliases"
      echo -e "${GREEN}  ✓ Created basic .bash_aliases file${RC}"
    fi

    echo -e "${GREEN}  ✓ Bash configuration completed${RC}"

  elif [ "$SELECTED_SHELL" = "zsh" ]; then
    # Check if .zshrc exists and handle accordingly
    if [ -e "$USER_HOME/.zshrc" ]; then
      # Backup existing .zshrc
      BACKUP_FILE="$USER_HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
      echo -e "${YELLOW}  Backing up old zsh config to ${WHITE}$BACKUP_FILE${RC}"
      cp -f "$USER_HOME/.zshrc" "$BACKUP_FILE"
    fi

    # Link Zsh config
    echo -e "${YELLOW}  Installing dxsbash Zsh configuration...${RC}"
    ln -svf "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
      echo -e "${YELLOW}  Using direct copy for .zshrc...${RC}"
      cp -f "$GITPATH/.zshrc" "$USER_HOME/.zshrc"
    }

    ln -svf "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
      echo -e "${YELLOW}  Using direct copy for .zshrc_help...${RC}"
      cp -f "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help"
    }

    # Install Oh My Zsh if not already installed
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
      echo -e "${YELLOW}  Installing Oh My Zsh...${RC}"
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      echo -e "${GREEN}  ✓ Oh My Zsh installed${RC}"
    else
      echo -e "${GREEN}  ✓ Oh My Zsh already installed${RC}"
    fi

    echo -e "${GREEN}  ✓ Zsh configuration completed${RC}"

  elif [ "$SELECTED_SHELL" = "fish" ]; then
    if [ -e "$USER_HOME/.config/fish/config.fish" ]; then
      BACKUP_DIR="$USER_HOME/.config/fish/backup"
      mkdir -p "$BACKUP_DIR"
      BACKUP_FILE="$BACKUP_DIR/config.fish.$(date +%Y%m%d%H%M%S)"
      echo -e "${YELLOW}  Backing up old fish config to ${WHITE}$BACKUP_FILE${RC}"
      cp -f "$USER_HOME/.config/fish/config.fish" "$BACKUP_FILE"
    fi

    # Link Fish config
    echo -e "${YELLOW}  Installing dxsbash Fish configuration...${RC}"
    ln -svf "$GITPATH/config.fish" "$USER_HOME/.config/fish/config.fish" || {
      echo -e "${YELLOW}  Using direct copy for config.fish...${RC}"
      cp -f "$GITPATH/config.fish" "$USER_HOME/.config/fish/config.fish"
    }

    # Create help file for fish
    ln -svf "$GITPATH/fish_help" "$USER_HOME/.config/fish/fish_help" || {
      echo -e "${YELLOW}  Using direct copy for fish_help...${RC}"
      cp -f "$GITPATH/fish_help" "$USER_HOME/.config/fish/fish_help"
    }

    # Setup Fisher plugin manager if not already installed
    if ! fish -c "type -q fisher" 2>/dev/null; then
      echo -e "${YELLOW}  Installing Fisher plugin manager for Fish...${RC}"
      fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" 2>/dev/null
      echo -e "${GREEN}  ✓ Fisher installed${RC}"

      # Install useful plugins
      echo -e "${YELLOW}  Installing Fish plugins...${RC}"
      fish -c "fisher install PatrickF1/fzf.fish" 2>/dev/null
      fish -c "fisher install jethrokuan/z" 2>/dev/null
      fish -c "fisher install IlanCosman/tide@v5" 2>/dev/null
      echo -e "${GREEN}  ✓ Fish plugins installed${RC}"
    else
      echo -e "${GREEN}  ✓ Fisher already installed${RC}"
    fi

    echo -e "${GREEN}  ✓ Fish configuration completed${RC}"
  fi

  # Link starship.toml for all shells
  echo -e "${YELLOW}  Setting up Starship prompt configuration...${RC}"
  ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
    echo -e "${YELLOW}  Using direct copy for starship.toml...${RC}"
    cp -f "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml"
  }
  echo -e "${GREEN}  ✓ Starship configuration completed${RC}"
  echo ""
}

#=================================================================
# Set default shell
#=================================================================
setDefaultShell() {
  echo -e "${CYAN}▶ Setting ${WHITE}$SELECTED_SHELL${CYAN} as your default shell...${RC}"

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
    echo -e "${RED}  ✗ Error: Could not find path to $SELECTED_SHELL.${RC}"
    echo -e "${YELLOW}  Please set it as your default shell manually after installation.${RC}"
    return 1
  fi

  # Check if the shell is in /etc/shells
  if ! grep -q "^$SHELL_PATH$" /etc/shells; then
    echo -e "${YELLOW}  Adding $SHELL_PATH to /etc/shells...${RC}"
    echo -e "$SHELL_PATH" | ${SUDO_CMD} tee -a /etc/shells > /dev/null
  fi

  # Change the default shell
  echo -e "${YELLOW}  Changing default shell to ${WHITE}$SHELL_PATH${RC}"
  ${SUDO_CMD} chsh -s "$SHELL_PATH" "$USER"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Successfully set $SELECTED_SHELL as your default shell${RC}"
  else
    echo -e "${RED}  ✗ Failed to set $SELECTED_SHELL as your default shell.${RC}"
    echo -e "${YELLOW}  Please do it manually with:${RC}"
    echo -e "${WHITE}  chsh -s $SHELL_PATH${RC}"
  fi
  echo ""
}

#=================================================================
# Install utility scripts
#=================================================================
installResetScript() {
  echo -e "${CYAN}▶ Installing reset-shell-profile script...${RC}"

  # Copy the reset script to the linuxtoolbox directory
  if [ -f "$GITPATH/reset-bash-profile.sh" ]; then
    cp "$GITPATH/reset-bash-profile.sh" "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
    chmod +x "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
    echo -e "${GREEN}  ✓ Installed bash reset script${RC}"

    # Copy for other shells if available
    if [ -f "$GITPATH/reset-zsh-profile.sh" ]; then
      cp "$GITPATH/reset-zsh-profile.sh" "$LINUXTOOLBOXDIR/reset-zsh-profile.sh"
      chmod +x "$LINUXTOOLBOXDIR/reset-zsh-profile.sh"
      echo -e "${GREEN}  ✓ Installed zsh reset script${RC}"
    fi

    if [ -f "$GITPATH/reset-fish-profile.sh" ]; then
      cp "$GITPATH/reset-fish-profile.sh" "$LINUXTOOLBOXDIR/reset-fish-profile.sh"
      chmod +x "$LINUXTOOLBOXDIR/reset-fish-profile.sh"
      echo -e "${GREEN}  ✓ Installed fish reset script${RC}"
    fi

    # Create a symbolic link for the appropriate reset script based on selected shell
    case "$SELECTED_SHELL" in
      bash)
        ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
        ;;
      zsh)
        if [ -f "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" ]; then
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" /usr/local/bin/reset-shell-profile
        else
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
        fi
        ;;
      fish)
        if [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ]; then
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-shell-profile
        else
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
        fi
        ;;
    esac

    echo -e "${GREEN}  ✓ Reset script installed successfully${RC}"
    echo -e "    You can run it with: ${WHITE}sudo reset-shell-profile [username]${RC}"
  else
    echo -e "${RED}  ✗ Reset script not found in $GITPATH${RC}"
    echo -e "${YELLOW}  You will need to manually copy it later${RC}"
  fi
  echo ""
}

installUpdaterCommand() {
  echo -e "${CYAN}▶ Installing dxsbash updater script...${RC}"

  # Copy the updater script to the linuxtoolbox directory
  if [ -f "$GITPATH/updater.sh" ]; then
    # Use cp -p to preserve permissions from source
    cp -p "$GITPATH/updater.sh" "$LINUXTOOLBOXDIR/"
    # Ensure it's executable regardless of source permissions
    chmod +x "$LINUXTOOLBOXDIR/updater.sh"

    # Create a symbolic link to make it available system-wide
    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/updater.sh" /usr/local/bin/upbashdxs

    # Create a symlink in home directory for easy access
    ln -sf "$LINUXTOOLBOXDIR/updater.sh" "$HOME/update-dxsbash.sh"
    chmod +x "$HOME/update-dxsbash.sh"

    echo -e "${GREEN}  ✓ Updater script installed successfully${RC}"
    echo -e "    You can update dxsbash anytime by running: ${WHITE}upbashdxs${RC}"
  else
    echo -e "${RED}  ✗ Updater script not found in $GITPATH${RC}"
    echo -e "${YELLOW}  You will need to update manually${RC}"
  fi
  echo ""
}

#=================================================================
# Configure terminal
#=================================================================
configure_terminal() {
  echo -e "${CYAN}▶ Configuring terminal emulators...${RC}"

  # Get user home directory
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

  # Configure Konsole if present
  if command_exists konsole; then
    echo -e "${YELLOW}  Configuring Konsole terminal...${RC}"

    # Create Konsole profile directory if it doesn't exist
    KONSOLE_DIR="$USER_HOME/.local/share/konsole"
    mkdir -p "$KONSOLE_DIR"

    # Create/update Konsole profile with FiraCode Nerd Font
    PROFILE_NAME="DXSBash.profile"
    PROFILE_PATH="$KONSOLE_DIR/$PROFILE_NAME"

    # Create profile file
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

    # Set correct permissions
    chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$PROFILE_PATH"

    # Update konsolerc to use this profile
    KONSOLERC="$USER_HOME/.config/konsolerc"
    if [ -f "$KONSOLERC" ]; then
      if grep -q "DefaultProfile=" "$KONSOLERC"; then
        sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$KONSOLERC"
      else
        echo "DefaultProfile=DXSBash.profile" >> "$KONSOLERC"
      fi
    fi

    echo -e "${GREEN}  ✓ Konsole configured${RC}"
  fi

  # Configure Yakuake if present
  if command_exists yakuake; then
    echo -e "${YELLOW}  Configuring Yakuake terminal...${RC}"

    YAKUAKERC="$USER_HOME/.config/yakuakerc"
    if [ -f "$YAKUAKERC" ]; then
      if grep -q "DefaultProfile=" "$YAKUAKERC"; then
        sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$YAKUAKERC"
      else
        echo "DefaultProfile=DXSBash.profile" >> "$YAKUAKERC"
      fi
    fi

    echo -e "${GREEN}  ✓ Yakuake configured${RC}"
  fi

  # No special configuration for generic terminals
  echo -e "${GREEN}  ✓ Terminal configuration completed${RC}"
  echo ""
}

#=================================================================
# Final setup and cleanup
#=================================================================
# Updated finalSetup() function that fixes the file copying issue

finalSetup() {
  echo -e "${CYAN}▶ Performing final setup tasks...${RC}"

  # Create logs directory
  echo -e "${YELLOW}  Creating log directory...${RC}"
  mkdir -p "$HOME/.dxsbash/logs"
  touch "$HOME/.dxsbash/logs/dxsbash.log"
  chmod 644 "$HOME/.dxsbash/logs/dxsbash.log"

  # Copy the utilities file only if source and destination are different
  if [ -f "$GITPATH/dxsbash-utils.sh" ]; then
    # Get the full path of both files to compare
    SOURCE="$(realpath "$GITPATH/dxsbash-utils.sh")"
    DEST="$(realpath "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh")"

    # Only copy if they are different files
    if [ "$SOURCE" != "$DEST" ]; then
      echo -e "${YELLOW}  Installing utility scripts...${RC}"
      cp -f "$SOURCE" "$DEST"
      chmod +x "$DEST"
    else
      echo -e "${YELLOW}  Utility script already in place, ensuring executable permission...${RC}"
      chmod +x "$DEST"
    fi
  fi

  echo -e "${GREEN}  ✓ Final setup completed${RC}"
  echo ""
}

#=================================================================
# Main installation flow
#=================================================================
main() {
  # Check environment
  checkEnv

  # Detect distribution
  detectDistro

  # Select shell
  selectShell

  # Install dependencies
  installDepend

  # Install additional tools
  installStarshipAndFzf
  installZoxide

  # Configure the system
  create_fastfetch_config
  setupShellConfig
  setDefaultShell
  installResetScript
  installUpdaterCommand
  configure_terminal

  # Final setup
  finalSetup

  # Display completion message
  echo -e "${BLUE}╔════════════════════════════════════════════════════════╗ ${RC}"
  echo -e "${BLUE}║                                                          ${RC}"
  echo -e "${BLUE}║  ${GREEN}Installation Complete!${BLUE}                   ${RC}"
  echo -e "${BLUE}║                                                          ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Shell:${YELLOW} $SELECTED_SHELL${BLUE}        ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Config:${YELLOW} ~/.${SELECTED_SHELL}rc${BLUE} ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Update:${YELLOW} upbashdxs${BLUE}             ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Reset:${YELLOW} sudo reset-shell-profile [username]${BLUE} ${RC}"
  echo -e "${BLUE}║                                                          ${RC}"
  echo -e "${BLUE}║  ${YELLOW}Please log out and log back in to use your new shell${BLUE} ${RC}"
  echo -e "${BLUE}║                                                          ${RC}"
  if [ "$IS_DEBIAN_BASED" != true ]; then
    echo -e "${BLUE}║  ${RED}Note: DXSBash is optimized for Debian/Ubuntu systems${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${RED}Some features may not work as expected on your system${BLUE} ${RC}"
    echo -e "${BLUE}║                                                        ${RC}"
  fi
  echo -e "${BLUE}║  ${RED}This Software is GNU/GPLv3${BLUE}                 ${RC}"
  echo -e "${BLUE}║                                                          ${RC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════╝ ${RC}"
  echo -e "  ${CYAN}Made by Luis Miguel P. Freitas - DigitalXS.ca${RC}"
  echo ""
}

# Run the main installation
main
