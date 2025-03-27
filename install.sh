#!/usr/bin/env bash
#
# DXSBash Installer Script
# https://github.com/digitalxs/dxsbash
#
# This script will download and install DXSBash, a professional shell environment
# for Linux power users with enhanced features for Bash, Zsh, and Fish shells.
#
# Usage: curl -fsSL https://digitalxs.ca/install.sh | bash
#        or
#        wget -qO- https://digitalxs.ca/install.sh | bash

# Enable strict error handling
set -eo pipefail

# Color codes
RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'

# Print banner
print_banner() {
  echo -e "${BLUE}██████╗ ██╗  ██╗███████╗██████╗  █████╗ ███████╗██╗  ██╗${RC}"
  echo -e "${BLUE}██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║  ██║${RC}"
  echo -e "${BLUE}██║  ██║ ╚███╔╝ ███████╗██████╔╝███████║███████╗███████║${RC}"
  echo -e "${BLUE}██║  ██║ ██╔██╗ ╚════██║██╔══██╗██╔══██║╚════██║██╔══██║${RC}"
  echo -e "${BLUE}██████╔╝██╔╝ ██╗███████║██████╔╝██║  ██║███████║██║  ██║${RC}"
  echo -e "${BLUE}╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${RC}"
  echo -e "${CYAN}Professional Shell Environment for Linux Power Users${RC}"
  echo -e "${YELLOW}v2.1.4${RC}\n"
}

# Print a step message
print_step() {
  echo -e "\n${GREEN}==>${RC} ${CYAN}$1${RC}"
}

# Print an error message and exit
print_error() {
  echo -e "\n${RED}Error:${RC} $1" >&2
  exit 1
}

# Print a warning message
print_warning() {
  echo -e "${YELLOW}Warning:${RC} $1" >&2
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install necessary prerequisites based on distribution
install_prerequisites() {
  print_step "Checking and installing prerequisites"

  # Detect package manager
  if command_exists apt-get; then
    PM="apt-get"
    PM_INSTALL="$PM install -y"
    PKGS="git curl wget unzip"
  elif command_exists apt; then
    PM="apt"
    PM_INSTALL="$PM install -y"
    PKGS="git curl wget unzip"
  elif command_exists dnf; then
    PM="dnf"
    PM_INSTALL="$PM install -y"
    PKGS="git curl wget unzip"
  elif command_exists yum; then
    PM="yum"
    PM_INSTALL="$PM install -y"
    PKGS="git curl wget unzip"
  elif command_exists pacman; then
    PM="pacman"
    PM_INSTALL="$PM -Sy --noconfirm"
    PKGS="git curl wget unzip"
  elif command_exists zypper; then
    PM="zypper"
    PM_INSTALL="$PM install -y"
    PKGS="git curl wget unzip"
  else
    print_warning "Could not detect package manager. Please install git, curl, wget, and unzip manually."
    return 1
  fi

  # Determine sudo command
  SUDO="sudo"
  if ! command_exists sudo; then
    if command_exists doas; then
      SUDO="doas"
    else
      if [ "$(id -u)" -ne 0 ]; then
        print_error "This script requires superuser privileges. Please run as root or install sudo."
      else
        SUDO=""
      fi
    fi
  fi

  # Check for required commands and install if missing
  INSTALL_PKGS=""
  for pkg in git curl wget unzip; do
    if ! command_exists "$pkg"; then
      INSTALL_PKGS="$INSTALL_PKGS $pkg"
    fi
  done

  if [ -n "$INSTALL_PKGS" ]; then
    echo "Installing required packages:$INSTALL_PKGS"
    if [ -n "$SUDO" ]; then
      $SUDO $PM_INSTALL $INSTALL_PKGS || print_error "Failed to install prerequisites"
    else
      $PM_INSTALL $INSTALL_PKGS || print_error "Failed to install prerequisites"
    fi
  else
    echo "All prerequisites are already installed"
  fi

  return 0
}

# Check system compatibility
check_compatibility() {
  print_step "Checking system compatibility"

  # Check OS
  if [ "$(uname -s)" != "Linux" ]; then
    print_error "This installer only supports Linux systems"
  fi

  # Check if home directory exists and is writable
  if [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
    print_error "Home directory does not exist or is not writable"
  fi

  # Check if bash exists
  if ! command_exists bash; then
    print_error "Bash is required but not installed"
  fi

  echo "System compatibility check passed"
  return 0
}

# Download DXSBash repository
download_dxsbash() {
  print_step "Downloading DXSBash repository"

  # Set up directories
  LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
  DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"

  # Create linuxtoolbox directory if it doesn't exist
  if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo "Creating directory: $LINUXTOOLBOXDIR"
    mkdir -p "$LINUXTOOLBOXDIR"
  fi

  # Remove existing dxsbash directory if it exists
  if [ -d "$DXSBASH_DIR" ]; then
    echo "Removing existing DXSBash installation"
    rm -rf "$DXSBASH_DIR"
  fi

  # Clone the repository
  echo "Cloning DXSBash repository from GitHub"
  git clone https://github.com/digitalxs/dxsbash.git "$DXSBASH_DIR" || print_error "Failed to clone DXSBash repository"

  # Verify successful download
  if [ ! -f "$DXSBASH_DIR/setup.sh" ]; then
    print_error "Repository download seems incomplete. setup.sh not found."
  fi

  # Make setup.sh executable
  chmod +x "$DXSBASH_DIR/setup.sh"

  echo "DXSBash repository successfully downloaded to $DXSBASH_DIR"
  return 0
}

# Run the setup script
run_setup() {
  print_step "Running DXSBash setup script"

  DXSBASH_DIR="$HOME/linuxtoolbox/dxsbash"
  
  # Change to the dxsbash directory
  cd "$DXSBASH_DIR" || print_error "Could not change to DXSBash directory"
  
  # Run the setup script
  ./setup.sh || print_error "DXSBash setup script failed"
  
  echo "DXSBash setup completed successfully"
  return 0
}

# Main function
main() {
  # Clear screen and print banner
  clear
  print_banner
  
  # Check if running interactively
  if [ ! -t 0 ]; then
    echo "Running in non-interactive mode. Some features may be limited."
  fi
  
  # Check system compatibility
  check_compatibility
  
  # Install prerequisites
  install_prerequisites
  
  # Download DXSBash repository
  download_dxsbash
  
  # Run the setup script
  run_setup
  
  # Success message
  echo -e "\n${GREEN}DXSBash has been successfully installed!${RC}"
  echo -e "You may need to restart your terminal or run 'source ~/.bashrc' (or equivalent) to start using DXSBash."
  echo -e "\nTo update DXSBash in the future, simply run: ${CYAN}upbashdxs${RC}"
  echo -e "For help and documentation, run: ${CYAN}help${RC}"
  echo -e "\nThank you for installing DXSBash!\n"
}

# Run the main function
main "$@"
