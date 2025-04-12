#!/bin/bash
#=================================================================
# DXSBash - Excessive Shell Environment for Debian 12
# Repository: https://github.com/digitalxs/dxsbash
# Version: 2.2.1
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
  echo -e "${BLUE}║  ${CYAN}Excessive Shell Environment for Debian${BLUE}                ║${RC}"
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
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""
SELECTED_SHELL=""

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
  REQUIREMENTS='curl groups sudo git'
  for req in $REQUIREMENTS; do
    if ! command_exists "$req"; then
      echo -e "${RED}  ✗ Required tool missing: ${WHITE}$req${RC}"
      echo -e "${YELLOW}  Please install the following requirements and try again: ${WHITE}$REQUIREMENTS${RC}"
      exit 1
    fi
  done
  echo -e "${GREEN}  ✓ All required tools are installed${RC}"

  ## Check Package Handler
  PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
  for pgm in $PACKAGEMANAGER; do
    if command_exists "$pgm"; then
      PACKAGER="$pgm"
      echo -e "${GREEN}  ✓ Using package manager: ${WHITE}$pgm${RC}"
      break
    fi
  done

  if [ -z "$PACKAGER" ]; then
    echo -e "${RED}  ✗ No supported package manager found${RC}"
    exit 1
  fi

  ## Check for privilege escalation tool
  if command_exists sudo; then
    SUDO_CMD="sudo"
  elif command_exists doas && [ -f "/etc/doas.conf" ]; then
    SUDO_CMD="doas"
  else
    SUDO_CMD="su -c"
  fi
  echo -e "${GREEN}  ✓ Using ${WHITE}$SUDO_CMD${GREEN} for privilege escalation${RC}"

  ## Check if the current directory is writable
  GITPATH=$(dirname "$(realpath "$0")")
  if [ ! -w "$GITPATH" ]; then
    echo -e "${RED}  ✗ Cannot write to directory: ${WHITE}$GITPATH${RC}"
    exit 1
  fi

  ## Check SuperUser Group
  SUPERUSERGROUP='wheel sudo root'
  for sug in $SUPERUSERGROUP; do
    if groups | grep -q "$sug"; then
      SUGROUP="$sug"
      echo -e "${GREEN}  ✓ Found super user group: ${WHITE}$SUGROUP${RC}"
      break
    fi
  done

  ## Ensure user has sudo privileges
  if ! groups | grep -q "$SUGROUP"; then
    echo -e "${RED}  ✗ You need to be a member of the ${WHITE}$SUGROUP${RED} group to run this script!${RC}"
    exit 1
  fi

  echo -e "${GREEN}▶ Environment check passed${RC}"
  echo ""
}

#=================================================================
# Dependency installation
#=================================================================
installDepend() {
  echo -e "${CYAN}▶ Installing dependencies...${RC}"

  ## Check for dependencies.
  COMMON_DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nano zoxide fzf pwgen'

  # Shell-specific dependencies
  BASH_DEPENDENCIES=""
  ZSH_DEPENDENCIES="zsh"
  FISH_DEPENDENCIES="fish"

  # Combine dependencies based on the selected shell and distribution
  DEPENDENCIES="$COMMON_DEPENDENCIES"

  # Add distribution-specific packages
  if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
    DEPENDENCIES="$DEPENDENCIES nala plocate trash-cli powerline"
  elif [ "$PACKAGER" = "dnf" ]; then
    DEPENDENCIES="$DEPENDENCIES dnf-plugins-core dnf-utils plocate trash-cli powerline"
  elif [ "$PACKAGER" = "pacman" ]; then
    DEPENDENCIES="$DEPENDENCIES plocate trash-cli powerline"
  fi

  # Add shell-specific dependencies
  if [ "$SELECTED_SHELL" = "zsh" ]; then
    DEPENDENCIES="$DEPENDENCIES $ZSH_DEPENDENCIES"

    # Add distribution-specific Zsh plugins
    if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
      DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
    elif [ "$PACKAGER" = "dnf" ]; then
      # Fedora/RHEL package names may differ
      if ${SUDO_CMD} dnf list zsh-autosuggestions &>/dev/null; then
        DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions"
      fi
      if ${SUDO_CMD} dnf list zsh-syntax-highlighting &>/dev/null; then
        DEPENDENCIES="$DEPENDENCIES zsh-syntax-highlighting"
      fi
    elif [ "$PACKAGER" = "pacman" ]; then
      DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
    fi
  elif [ "$SELECTED_SHELL" = "fish" ]; then
    DEPENDENCIES="$DEPENDENCIES $FISH_DEPENDENCIES"
  fi

  if ! command_exists nvim; then
    DEPENDENCIES="${DEPENDENCIES} neovim"
  fi

  echo -e "${YELLOW}  Installing required packages: ${WHITE}$DEPENDENCIES${RC}"
  if [ "$PACKAGER" = "pacman" ]; then
    if ! command_exists yay && ! command_exists paru; then
      echo -e "${YELLOW}  Installing yay as AUR helper...${RC}"
      ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
      cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
      cd yay-git && makepkg --noconfirm -si
    else
      echo -e "${GREEN}  ✓ AUR helper already installed${RC}"
    fi
    if command_exists yay; then
      AUR_HELPER="yay"
    elif command_exists paru; then
      AUR_HELPER="paru"
    else
      echo -e "${RED}  ✗ No AUR helper found. Please install yay or paru.${RC}"
      exit 1
    fi
    ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
  elif [ "$PACKAGER" = "nala" ]; then
    ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
  elif [ "$PACKAGER" = "emerge" ]; then
    ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
    if [ "$SELECTED_SHELL" = "zsh" ]; then
      ${SUDO_CMD} ${PACKAGER} -v app-shells/zsh app-shells/zsh-completions
    elif [ "$SELECTED_SHELL" = "fish" ]; then
      ${SUDO_CMD} ${PACKAGER} -v app-shells/fish
    fi
  elif [ "$PACKAGER" = "xbps-install" ]; then
    ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
  elif [ "$PACKAGER" = "nix-env" ]; then
    ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship
    if [ "$SELECTED_SHELL" = "zsh" ]; then
      ${SUDO_CMD} ${PACKAGER} -iA nixos.zsh nixos.zsh-completions nixos.zsh-autosuggestions nixos.zsh-syntax-highlighting
    elif [ "$SELECTED_SHELL" = "fish" ]; then
      ${SUDO_CMD} ${PACKAGER} -iA nixos.fish nixos.fishPlugins.done
    fi
  elif [ "$PACKAGER" = "dnf" ]; then
    # Fedora-specific handling
    echo -e "${YELLOW}  Detected Fedora or RHEL-based distribution${RC}"

    # Check for EPEL repository if on RHEL/CentOS
    if [ -f /etc/redhat-release ] && ! grep -q "Fedora" /etc/redhat-release; then
      if ! ${SUDO_CMD} ${PACKAGER} list installed epel-release >/dev/null 2>&1; then
        echo -e "${YELLOW}  Installing EPEL repository for additional packages...${RC}"
        ${SUDO_CMD} ${PACKAGER} install -y epel-release
      fi
    fi

    # Install RPM Fusion repositories for Fedora
    if grep -q "Fedora" /etc/redhat-release 2>/dev/null; then
      if ! ${SUDO_CMD} ${PACKAGER} list installed rpmfusion-free-release >/dev/null 2>&1; then
        echo -e "${YELLOW}  Installing RPM Fusion repositories...${RC}"
        ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      fi
    fi

    # Adjust package names for Fedora/RHEL
    FEDORA_DEPENDENCIES=$(echo "$DEPENDENCIES" | sed 's/batcat/bat/g' | sed 's/nala/dnf-utils/g')

    # Install Fedora/RHEL packages
    ${SUDO_CMD} ${PACKAGER} install -y $FEDORA_DEPENDENCIES
  else
    ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
  fi

  echo -e "${GREEN}  ✓ Dependencies installed successfully${RC}"

  # Check to see if the FiraCode Nerd Font is installed
  FONT_NAME="FiraCode Nerd Font"
  if fc-list :family | grep -iq "$FONT_NAME"; then
    echo -e "${GREEN}  ✓ Font '$FONT_NAME' is already installed${RC}"
  else
    echo -e "${YELLOW}  Installing font '$FONT_NAME'...${RC}"
    # Change this URL to correspond with the correct font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
    FONT_DIR="$HOME/.local/share/fonts"
    # check if the file is accessible
    if wget -q --spider "$FONT_URL"; then
      TEMP_DIR=$(mktemp -d)
      wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
      unzip -q "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
      mkdir -p "$FONT_DIR"/"$FONT_NAME"
      mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
      # Update the font cache
      fc-cache -fv >/dev/null
      # delete the files created from this
      rm -rf "${TEMP_DIR}"
      echo -e "${GREEN}  ✓ Font '$FONT_NAME' installed successfully${RC}"
    else
      echo -e "${YELLOW}  ✗ Font '$FONT_NAME' not installed. Font URL is not accessible.${RC}"
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
      exit 1
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
    exit 1
  fi
  echo ""
}

install_additional_dependencies() {
  echo -e "${CYAN}▶ Setting up Neovim...${RC}"
  # Check if Neovim needs to be installed or is already handled
  if command_exists nvim; then
    echo -e "${GREEN}  ✓ Neovim already installed${RC}"
    return
  fi

  echo -e "${YELLOW}  Installing Neovim...${RC}"
  case "$PACKAGER" in
    *apt)
      if [ ! -d "/opt/neovim" ]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod u+x nvim.appimage
        ./nvim.appimage --appimage-extract
        ${SUDO_CMD} mv squashfs-root /opt/neovim
        ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
        echo -e "${GREEN}  ✓ Neovim installed via AppImage${RC}"
      fi
      ;;
    *zypper)
      ${SUDO_CMD} zypper refresh
      ${SUDO_CMD} zypper -n install neovim
      echo -e "${GREEN}  ✓ Neovim installed via zypper${RC}"
      ;;
    *dnf)
      ${SUDO_CMD} dnf check-update

      # Check if Neovim is available in standard repositories
      if ${SUDO_CMD} dnf list neovim &>/dev/null; then
        ${SUDO_CMD} dnf install -y neovim
        echo -e "${GREEN}  ✓ Neovim installed via dnf${RC}"
      else
        # Try to install from COPR repository if not available
        echo -e "${YELLOW}  Installing Neovim from COPR repository...${RC}"
        ${SUDO_CMD} dnf copr enable -y agriffis/neovim-nightly
        ${SUDO_CMD} dnf install -y neovim
        echo -e "${GREEN}  ✓ Neovim installed via COPR repository${RC}"
      fi
      ;;
    *pacman)
      ${SUDO_CMD} pacman -Syu
      ${SUDO_CMD} pacman -S --noconfirm neovim
      echo -e "${GREEN}  ✓ Neovim installed via pacman${RC}"
      ;;
    *)
      echo -e "${YELLOW}  No supported package manager found for Neovim installation.${RC}"
      echo -e "${YELLOW}  Please install Neovim manually after setup completes.${RC}"
      return
      ;;
  esac
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
    exit 1
  }
  echo -e "${GREEN}  ✓ Fastfetch configuration set up successfully${RC}"
  echo ""
}

init_fedora_zsh_plugins() {
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

  # Handle Fedora/RHEL zsh plugins which might be in different locations
  if [ "$PACKAGER" = "dnf" ] && [ "$SELECTED_SHELL" = "zsh" ]; then
    echo -e "${YELLOW}  Setting up Zsh plugins for Fedora/RHEL...${RC}"

    # Add plugin sourcing to .zshrc if files exist
    ZSH_PLUGIN_DIR="/usr/share/zsh/plugins"

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

    # Try to install plugins manually if they're not found in standard locations
    if [ ! -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
      echo -e "${YELLOW}  Installing Zsh autosuggestions plugin manually...${RC}"
      PLUGIN_DIR="$USER_HOME/.zsh/plugins"
      mkdir -p "$PLUGIN_DIR"
      git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"

      # Add to .zsh_plugins
      echo "# Manual installation" >> "$USER_HOME/.zsh_plugins"
      echo "source $PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$USER_HOME/.zsh_plugins"
    fi

    if [ ! -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
      echo -e "${YELLOW}  Installing Zsh syntax highlighting plugin manually...${RC}"
      PLUGIN_DIR="$USER_HOME/.zsh/plugins"
      mkdir -p "$PLUGIN_DIR"
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"

      # Add to .zsh_plugins
      echo "source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$USER_HOME/.zsh_plugins"
    fi

    echo -e "${GREEN}  ✓ Zsh plugins configured for Fedora/RHEL${RC}"
  fi
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
      BACKUP_FILE="$USER_HOME/.bashrc.bak"
      if [ -e "$BACKUP_FILE" ]; then
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        BACKUP_FILE="$USER_HOME/.bashrc.bak.$TIMESTAMP"
      fi
      echo -e "${YELLOW}  Backing up old bash config to ${WHITE}$BACKUP_FILE${RC}"
      if ! mv "$USER_HOME/.bashrc" "$BACKUP_FILE"; then
        echo -e "${RED}  ✗ Warning: Can't move the old bash config file!${RC}"
        echo -e "${YELLOW}  Continuing with installation anyway...${RC}"
      fi
    fi

    # Link Bash config
    echo -e "${YELLOW}  Creating bash configuration links...${RC}"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for .bashrc${RC}"
      exit 1
    }
    ln -svf "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for .bashrc_help${RC}"
      exit 1
    }

    # Link Bash aliases file
    if [ -f "$GITPATH/.bash_aliases" ]; then
      ln -svf "$GITPATH/.bash_aliases" "$USER_HOME/.bash_aliases" || {
        echo -e "${RED}  ✗ Failed to create symbolic link for .bash_aliases${RC}"
        # If symlinking fails, try direct copy
        echo -e "${YELLOW}  Attempting direct copy of .bash_aliases...${RC}"
        cp -f "$GITPATH/.bash_aliases" "$USER_HOME/.bash_aliases" || {
          echo -e "${RED}  ✗ Failed to copy .bash_aliases file!${RC}"
        }
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
      BACKUP_FILE="$USER_HOME/.zshrc.bak"
      if [ -e "$BACKUP_FILE" ]; then
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        BACKUP_FILE="$USER_HOME/.zshrc.bak.$TIMESTAMP"
      fi
      echo -e "${YELLOW}  Backing up old zsh config to ${WHITE}$BACKUP_FILE${RC}"
      if ! mv "$USER_HOME/.zshrc" "$BACKUP_FILE"; then
        echo -e "${RED}  ✗ Warning: Can't move the old zsh config file!${RC}"
        echo -e "${YELLOW}  Continuing with installation anyway...${RC}"
      fi
    fi

# Link Zsh config - whether .zshrc existed or not, we'll use the one from dxsbash
    echo -e "${YELLOW}  Installing dxsbash Zsh configuration...${RC}"
    ln -svf "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for .zshrc${RC}"
      # If symlinking fails, try direct copy
      echo -e "${YELLOW}  Attempting direct copy of .zshrc...${RC}"
      cp -f "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
        echo -e "${RED}  ✗ Failed to copy .zshrc file!${RC}"
        exit 1
      }
    }

    ln -svf "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for .zshrc_help${RC}"
      # If symlinking fails, try direct copy
      echo -e "${YELLOW}  Attempting direct copy of .zshrc_help...${RC}"
      cp -f "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
        echo -e "${RED}  ✗ Failed to copy .zshrc_help file!${RC}"
        exit 1
      }
    }

    # Install Oh My Zsh if not already installed
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
      echo -e "${YELLOW}  Installing Oh My Zsh...${RC}"
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      echo -e "${GREEN}  ✓ Oh My Zsh installed${RC}"
    else
      echo -e "${GREEN}  ✓ Oh My Zsh already installed${RC}"
    fi

    # Setup Fedora/RHEL specific Zsh plugins
    init_fedora_zsh_plugins

    # Add plugin sourcing to .zshrc if it exists
    if [ -f "$USER_HOME/.zsh_plugins" ]; then
      # Add source line to .zshrc if not already present
      if ! grep -q "source ~/.zsh_plugins" "$USER_HOME/.zshrc"; then
        echo -e "${YELLOW}  Adding plugins to .zshrc...${RC}"
        echo "" >> "$USER_HOME/.zshrc"
        echo "# Source plugins" >> "$USER_HOME/.zshrc"
        echo "[ -f ~/.zsh_plugins ] && source ~/.zsh_plugins" >> "$USER_HOME/.zshrc"
      fi
    fi

    echo -e "${GREEN}  ✓ Zsh configuration completed${RC}"

  elif [ "$SELECTED_SHELL" = "fish" ]; then
    if [ -e "$USER_HOME/.config/fish/config.fish" ]; then
      BACKUP_DIR="$USER_HOME/.config/fish/backup"
      mkdir -p "$BACKUP_DIR"
      TIMESTAMP=$(date +%Y%m%d%H%M%S)
      BACKUP_FILE="$BACKUP_DIR/config.fish.$TIMESTAMP"
      echo -e "${YELLOW}  Backing up old fish config to ${WHITE}$BACKUP_FILE${RC}"
      if ! mv "$USER_HOME/.config/fish/config.fish" "$BACKUP_FILE"; then
        echo -e "${RED}  ✗ Warning: Can't move the old fish config file!${RC}"
        echo -e "${YELLOW}  Continuing with installation anyway...${RC}"
      fi
    fi

    # Link Fish config
    echo -e "${YELLOW}  Installing dxsbash Fish configuration...${RC}"
    ln -svf "$GITPATH/config.fish" "$USER_HOME/.config/fish/config.fish" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for config.fish${RC}"
      exit 1
    }

    # Create help file for fish
    ln -svf "$GITPATH/fish_help" "$USER_HOME/.config/fish/fish_help" || {
      echo -e "${RED}  ✗ Failed to create symbolic link for fish_help${RC}"
      exit 1
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
    echo -e "${RED}  ✗ Failed to create symbolic link for starship.toml${RC}"
    exit 1
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
          echo -e "${YELLOW}  Note: Using bash reset script as fallback for zsh${RC}"
        fi
        ;;
      fish)
        if [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ]; then
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-shell-profile
        else
          ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
          echo -e "${YELLOW}  Note: Using bash reset script as fallback for fish${RC}"
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

    echo -e "${GREEN}  ✓ Updater script installed successfully${RC}"
    echo -e "    You can update dxsbash anytime by running: ${WHITE}upbashdxs${RC}"
  else
    echo -e "${RED}  ✗ Updater script not found in $GITPATH${RC}"
    echo -e "${YELLOW}  You will need to update manually${RC}"
  fi
  echo ""
}

#=================================================================
# Distribution detection
#=================================================================
detectDistro() {
  echo -e "${CYAN}▶ Detecting Linux distribution...${RC}"
  # Detect the specific distribution for better handling
  DISTRO="unknown"

  if [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
    echo -e "${GREEN}  ✓ Detected ${WHITE}Fedora Linux${RC}"
  elif [ -f /etc/redhat-release ]; then
    if grep -q "CentOS" /etc/redhat-release; then
      DISTRO="centos"
      echo -e "${GREEN}  ✓ Detected ${WHITE}CentOS Linux${RC}"
    elif grep -q "Red Hat Enterprise Linux" /etc/redhat-release; then
      DISTRO="rhel"
      echo -e "${GREEN}  ✓ Detected ${WHITE}Red Hat Enterprise Linux${RC}"
    else
      DISTRO="redhat-based"
      echo -e "${GREEN}  ✓ Detected ${WHITE}Red Hat-based Linux${RC}"
    fi
  elif [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
    DISTRO="ubuntu"
    echo -e "${GREEN}  ✓ Detected ${WHITE}Ubuntu Linux${RC}"
  elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
    echo -e "${GREEN}  ✓ Detected ${WHITE}Debian Linux${RC}"
  elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
    echo -e "${GREEN}  ✓ Detected ${WHITE}Arch Linux${RC}"
  elif [ -f /etc/SuSE-release ] || [ -f /etc/opensuse-release ]; then
    DISTRO="suse"
    echo -e "${GREEN}  ✓ Detected ${WHITE}SUSE Linux${RC}"
  else
    # Generic detection
    if command_exists apt; then
      DISTRO="debian-based"
      echo -e "${GREEN}  ✓ Detected ${WHITE}Debian-based Linux${RC}"
    elif command_exists dnf; then
      DISTRO="fedora-based"
      echo -e "${GREEN}  ✓ Detected ${WHITE}Fedora-based Linux${RC}"
    elif command_exists pacman; then
      DISTRO="arch-based"
      echo -e "${GREEN}  ✓ Detected ${WHITE}Arch-based Linux${RC}"
    elif command_exists zypper; then
      DISTRO="suse-based"
      echo -e "${GREEN}  ✓ Detected ${WHITE}SUSE-based Linux${RC}"
    fi
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
      if command_exists zsh; then
        SELECTED_SHELL="zsh"
      else
        echo -e "${YELLOW}  Zsh is not installed yet. It will be installed during setup.${RC}"
        SELECTED_SHELL="zsh"
      fi
      ;;
    3)
      if command_exists fish; then
        SELECTED_SHELL="fish"
      else
        echo -e "${YELLOW}  Fish is not installed yet. It will be installed during setup.${RC}"
        SELECTED_SHELL="fish"
      fi
      ;;
    *)
      SELECTED_SHELL="bash"
      ;;
  esac

  echo -e "${GREEN}  ✓ Selected shell: ${WHITE}$SELECTED_SHELL${RC}"
  echo ""
}

#=================================================================
# Terminal configuration
#=================================================================
configure_konsole() {
  echo -e "${YELLOW}  Configuring Konsole to use FiraCode Nerd Font...${RC}"

  # Get user home directory
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

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

  # Make sure permissions are correct
  chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$PROFILE_PATH"

  # Create/update Konsole configuration to use the new profile by default
  KONSOLERC="$USER_HOME/.config/konsolerc"

  # Only create konsolerc if it doesn't exist
  if [ ! -f "$KONSOLERC" ]; then
    cat > "$KONSOLERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[MainWindow]
MenuBar=Disabled
ToolBarsMovable=Disabled

[TabBar]
NewTabButton=true
EOL
    chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$KONSOLERC"
  else
    # If konsolerc exists, just update the DefaultProfile line
    if grep -q "DefaultProfile=" "$KONSOLERC"; then
      # Replace existing DefaultProfile line
      sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$KONSOLERC"
    else
      # Add DefaultProfile line if it doesn't exist
      echo -e "DefaultProfile=DXSBash.profile" >> "$KONSOLERC"
    fi
  fi

  echo -e "${GREEN}  ✓ Konsole configured to use FiraCode Nerd Font${RC}"
}

configure_kde_terminal_emulators() {
  echo -e "${CYAN}▶ Configuring terminal emulators...${RC}"

  # Check if running in KDE environment
  if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || command_exists konsole; then
    echo -e "${YELLOW}  KDE environment detected${RC}"

    # Configure Konsole
    if command_exists konsole; then
      configure_konsole
    fi

    # Configure Yakuake if installed
    if command_exists yakuake; then
      echo -e "${YELLOW}  Configuring Yakuake to use FiraCode Nerd Font...${RC}"

      # Yakuake uses the same profiles as Konsole, so we just need to update yakuakerc
      USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
      YAKUAKERC="$USER_HOME/.config/yakuakerc"

      if [ -f "$YAKUAKERC" ]; then
        # Update existing DefaultProfile
        if grep -q "DefaultProfile=" "$YAKUAKERC"; then
          sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$YAKUAKERC"
        else
          echo -e "DefaultProfile=DXSBash.profile" >> "$YAKUAKERC"
        fi
      else
        # Create new yakuakerc
        mkdir -p "$USER_HOME/.config"
        cat > "$YAKUAKERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[Dialogs]
FirstRun=false

[Window]
KeepOpen=false
EOL
        chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$YAKUAKERC"
      fi

      echo -e "${GREEN}  ✓ Yakuake configured to use FiraCode Nerd Font${RC}"
    fi
  else
    echo -e "${YELLOW}  No KDE environment detected, skipping KDE terminal configuration${RC}"
  fi
  echo ""
}

#=================================================================
# Final setup and cleanup
#=================================================================
finalSetup() {
  echo -e "${CYAN}▶ Performing final setup tasks...${RC}"

  # Create logs directory
  echo -e "${YELLOW}  Creating log directory...${RC}"
  mkdir -p "$HOME/.dxsbash/logs"
  touch "$HOME/.dxsbash/logs/dxsbash.log"
  chmod 644 "$HOME/.dxsbash/logs/dxsbash.log"

  # Copy the utilities file
  echo -e "${YELLOW}  Installing utility scripts...${RC}"
  if [ "$GITPATH/dxsbash-utils.sh" != "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh" ]; then
    cp -f "$GITPATH/dxsbash-utils.sh" "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh"
  fi
  chmod +x "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh"

  # Create symlink to updater in home directory
  USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
  ln -svf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh" || {
    echo -e "${RED}  ✗ Failed to create symlink for updater in home directory${RC}"
    echo -e "${YELLOW}  Continuing with installation anyway...${RC}"
  }
  chmod +x "$USER_HOME/update-dxsbash.sh"

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
  install_additional_dependencies

  # Configure the system
  create_fastfetch_config
  setupShellConfig
  setDefaultShell
  installResetScript
  installUpdaterCommand
  configure_kde_terminal_emulators

  # Final setup
  finalSetup

  # Display completion message
  echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${BLUE}║                                                         ${RC}"
  echo -e "${BLUE}║  ${GREEN}Installation Complete!${BLUE}                  ${RC}"
  echo -e "${BLUE}║                                                         ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Shell:${YELLOW} $SELECTED_SHELL${BLUE}       ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Config:${YELLOW} ~/.${SELECTED_SHELL}rc${BLUE} ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Update:${YELLOW} upbashdxs${BLUE}            ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Reset:${YELLOW} sudo reset-shell-profile [username]${BLUE} ${RC}"
  echo -e "${BLUE}║                                                         ${RC}"
  echo -e "${BLUE}║  ${YELLOW}Please log out and log back in to start using or close terminal${BLUE} ${RC}"
  echo -e "${BLUE}║  ${YELLOW}your new $SELECTED_SHELL shell.${BLUE}        ${RC}"
  echo -e "${BLUE}║                                                         ${RC}"
  echo -e "${BLUE}║   ${RED}This Software is GNU/GPLv3${BLUE}               ${RC}"
  echo -e "${BLUE}║                                                         ${RC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
  echo -e "  ${CYAN}Made by Luis Miguel P. Freitas - DigitalXS.ca${RC}"
  echo ""
}

# Run the main installation
main
