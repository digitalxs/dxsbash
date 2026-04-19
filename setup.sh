#!/bin/bash
#=================================================================
# DXSBash - Enhanced Shell Environment for Debian and Ubuntu
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#=================================================================

# Strict mode + pipefail so piped failures surface
set -Eeuo pipefail

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
# Error trap — log the failing line and command
#=================================================================
on_error() {
  local ec=$?
  echo -e "${RED}✗ setup.sh failed (exit $ec) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}${RC}" >&2
  [ -n "${LOG_FILE:-}" ] && echo -e "${YELLOW}  See log: $LOG_FILE${RC}" >&2
  exit "$ec"
}
trap on_error ERR

#=================================================================
# Who are we running as, and whose HOME should we touch?
#
# If invoked via sudo, SUDO_USER is set to the invoking user and
# $HOME points to /root. We always want the *real* user's home.
#=================================================================
REAL_USER="${SUDO_USER:-${USER:-$(id -un)}}"
USER_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[ -n "$USER_HOME" ] || USER_HOME="${HOME:-/tmp}"
REAL_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"

# Helper: run a command as the real user (strips root if we were sudo'd)
as_user() {
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    sudo -u "$REAL_USER" -H "$@"
  else
    "$@"
  fi
}

#=================================================================
# Operation mode (install | repair | uninstall)
#
# Can be selected via CLI flag, env var DXSBASH_MODE, or an
# interactive menu when no choice is provided.
#=================================================================
MODE=""
ASSUME_YES=0
NONINTERACTIVE=0
DRY_RUN=0

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --install)    MODE="install" ;;
      --repair)     MODE="repair" ;;
      --uninstall)  MODE="uninstall" ;;
      -y|--yes)     ASSUME_YES=1; NONINTERACTIVE=1 ;;
      --dry-run)    DRY_RUN=1 ;;
      --shell)
        shift
        case "${1:-}" in
          bash|zsh|fish) SELECTED_SHELL="$1" ;;
          *) echo "Invalid --shell value: ${1:-}" >&2; exit 2 ;;
        esac
        ;;
      -h|--help)
        cat <<'USAGE'
DXSBash setup

Usage: setup.sh [MODE] [options]

Modes:
  --install     Install DXSBash (default when interactive)
  --repair      Re-link configs, re-install helper commands
  --uninstall   Remove DXSBash and restore /etc/skel defaults

Options:
  --shell X     Choose shell (bash|zsh|fish); overrides menu
  -y, --yes     Do not prompt; assume yes (non-interactive)
  --dry-run     Print actions without making changes (install only)
  -h, --help    Show this help

Environment:
  DXSBASH_MODE   Same as a mode flag
  DXSBASH_SHELL  Same as --shell
USAGE
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 2
        ;;
    esac
    shift
  done
  if [ -z "$MODE" ] && [ -n "${DXSBASH_MODE:-}" ]; then
    MODE="$DXSBASH_MODE"
  fi
  if [ -z "${SELECTED_SHELL:-}" ] && [ -n "${DXSBASH_SHELL:-}" ]; then
    case "$DXSBASH_SHELL" in
      bash|zsh|fish) SELECTED_SHELL="$DXSBASH_SHELL" ;;
      *) echo "Invalid DXSBASH_SHELL: $DXSBASH_SHELL" >&2; exit 2 ;;
    esac
  fi
}

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
#
# Safe when re-run in place: if setup.sh is running *from* the
# target directory, we `git pull` instead of `rm -rf` + clone, which
# would otherwise delete the running script.
#=================================================================
initialize() {
  echo -e "${CYAN}▶ Initializing setup...${RC}"

  # Ensure .config exists in the *real* user's home
  CONFIGDIR="$USER_HOME/.config"
  if [ ! -d "$CONFIGDIR" ]; then
    echo -e "${YELLOW}  Creating .config directory: ${WHITE}$CONFIGDIR${RC}"
    as_user mkdir -p "$CONFIGDIR"
    echo -e "${GREEN}  ✓ .config directory created${RC}"
  fi

  LINUXTOOLBOXDIR="$USER_HOME/linuxtoolbox"
  if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo -e "${YELLOW}  Creating linuxtoolbox directory: ${WHITE}$LINUXTOOLBOXDIR${RC}"
    as_user mkdir -p "$LINUXTOOLBOXDIR"
  fi

  local target="$LINUXTOOLBOXDIR/dxsbash"
  local script_dir
  script_dir="$(dirname "$(realpath "$0")")"

  # Self-wipe guard: don't delete the directory we're running from.
  if [ -d "$target" ] && [ "$script_dir" = "$(realpath "$target" 2>/dev/null || echo /nonexistent)" ]; then
    echo -e "${YELLOW}  Running from $target — pulling updates in place${RC}"
    if [ "$DRY_RUN" -eq 0 ]; then
      if ( cd "$target" && as_user git pull --ff-only origin main ); then
        echo -e "${GREEN}  ✓ Repository updated${RC}"
      else
        echo -e "${YELLOW}  ⚠ git pull failed; continuing with current checkout${RC}"
      fi
    fi
  elif [ -d "$target" ]; then
    echo -e "${YELLOW}  Cleaning existing installation at $target${RC}"
    [ "$DRY_RUN" -eq 0 ] && rm -rf "$target"
    if [ "$DRY_RUN" -eq 0 ]; then
      if ! as_user git clone https://github.com/digitalxs/dxsbash "$target"; then
        echo -e "${RED}  ✗ Failed to clone repository${RC}"
        exit 1
      fi
    fi
    echo -e "${GREEN}  ✓ Repository ready${RC}"
  else
    echo -e "${YELLOW}  Cloning DXSBash repository...${RC}"
    if [ "$DRY_RUN" -eq 0 ]; then
      if ! as_user git clone https://github.com/digitalxs/dxsbash "$target"; then
        echo -e "${RED}  ✗ Failed to clone repository. Check your internet connection.${RC}"
        exit 1
      fi
    fi
    echo -e "${GREEN}  ✓ Repository cloned successfully${RC}"
  fi

  cd "$target" 2>/dev/null || true
  echo -e "${GREEN}▶ Initialization complete${RC}"
  echo ""
}

# Main variables that will be used across functions
SUDO_CMD=""
GITPATH=""
SELECTED_SHELL="${SELECTED_SHELL:-}"
IS_DEBIAN_BASED=false
LOG_FILE=""

# Parse CLI arguments up front
parse_args "$@"

#=================================================================
# Install logging — mirror stdout/stderr to a dated log file under
# ~/.dxsbash/logs/ so post-mortems are possible.
#=================================================================
setup_logging() {
  local log_dir="$USER_HOME/.dxsbash/logs"
  as_user mkdir -p "$log_dir"
  LOG_FILE="$log_dir/install-$(date +%Y%m%d-%H%M%S).log"
  as_user touch "$LOG_FILE"
  # Tee both streams; keep stderr distinguishable in the log
  exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
  echo "=== DXSBash setup started $(date) ===" >> "$LOG_FILE"
  echo "    args: $*"                          >> "$LOG_FILE"
  echo "    user: $REAL_USER ($USER_HOME)"     >> "$LOG_FILE"
}
setup_logging "$@"

# Display welcome banner
display_banner

#=================================================================
# Interactive mode selection
#=================================================================
select_mode() {
  if [ -n "$MODE" ]; then
    return
  fi
  if [ "$NONINTERACTIVE" -eq 1 ] || [ ! -t 0 ]; then
    MODE="install"
    return
  fi

  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${CYAN}║             What would you like to do?                 ║${RC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${RC}"
  echo -e "  ${WHITE}1)${RC} ${GREEN}Install${RC}     ${YELLOW}(default — fresh install of DXSBash)${RC}"
  echo -e "  ${WHITE}2)${RC} ${GREEN}Repair${RC}      ${YELLOW}(fix broken symlinks/commands)${RC}"
  echo -e "  ${WHITE}3)${RC} ${GREEN}Uninstall${RC}   ${YELLOW}(remove and restore Debian defaults)${RC}"
  echo -e "  ${WHITE}4)${RC} Cancel"
  echo ""
  read -p "  Enter your choice [1-4] (default: 1): " mode_choice
  case "$mode_choice" in
    2) MODE="repair" ;;
    3) MODE="uninstall" ;;
    4) echo -e "${YELLOW}Cancelled.${RC}"; exit 0 ;;
    *) MODE="install" ;;
  esac
  echo ""
}

select_mode

#=================================================================
# Dispatch: repair / uninstall delegate to their dedicated scripts
# living next to this file so setup.sh stays a single entry point.
#=================================================================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ "$MODE" = "repair" ]; then
  REPAIR_ARGS=()
  [ "$ASSUME_YES" -eq 1 ] && REPAIR_ARGS+=(--deps)
  if [ -x "$SCRIPT_DIR/repair.sh" ]; then
    exec "$SCRIPT_DIR/repair.sh" "${REPAIR_ARGS[@]}"
  elif [ -x "$USER_HOME/linuxtoolbox/dxsbash/repair.sh" ]; then
    exec "$USER_HOME/linuxtoolbox/dxsbash/repair.sh" "${REPAIR_ARGS[@]}"
  else
    echo -e "${RED}repair.sh not found. Is DXSBash installed?${RC}"
    exit 1
  fi
fi

if [ "$MODE" = "uninstall" ]; then
  UNINSTALL_ARGS=()
  [ "$ASSUME_YES" -eq 1 ] && UNINSTALL_ARGS+=(--yes)
  if [ -x "$SCRIPT_DIR/uninstall.sh" ]; then
    exec "$SCRIPT_DIR/uninstall.sh" "${UNINSTALL_ARGS[@]}"
  elif [ -x "$USER_HOME/linuxtoolbox/dxsbash/uninstall.sh" ]; then
    exec "$USER_HOME/linuxtoolbox/dxsbash/uninstall.sh" "${UNINSTALL_ARGS[@]}"
  else
    echo -e "${RED}uninstall.sh not found. Is DXSBash installed?${RC}"
    exit 1
  fi
fi

# Default: install — pre-checks, pre-flight and initialize happen
# inside main() at the bottom so all helper functions are defined.

#=================================================================
# Already-installed detection
#
# If all expected symlinks/commands look healthy, suggest repair
# instead of a fresh install — avoids accidental reclone + rechsh.
#=================================================================
is_installed() {
  local shell_rc=""
  case "$SELECTED_SHELL" in
    bash) shell_rc="$USER_HOME/.bashrc" ;;
    zsh)  shell_rc="$USER_HOME/.zshrc" ;;
    fish) shell_rc="$USER_HOME/.config/fish/config.fish" ;;
    *)    shell_rc="$USER_HOME/.bashrc" ;;
  esac

  [ -d "$USER_HOME/linuxtoolbox/dxsbash" ] || return 1
  [ -L "$shell_rc" ] && readlink "$shell_rc" | grep -q dxsbash || return 1
  [ -x /usr/local/bin/update-dxsbash ] || return 1
  return 0
}

if [ -z "${SELECTED_SHELL:-}" ] && [ -L "$USER_HOME/.bashrc" ] && \
   readlink "$USER_HOME/.bashrc" | grep -q dxsbash; then
  DETECTED_INSTALLED_SHELL="bash"
elif [ -L "$USER_HOME/.zshrc" ] && \
     readlink "$USER_HOME/.zshrc" | grep -q dxsbash; then
  DETECTED_INSTALLED_SHELL="zsh"
elif [ -L "$USER_HOME/.config/fish/config.fish" ] && \
     readlink "$USER_HOME/.config/fish/config.fish" | grep -q dxsbash; then
  DETECTED_INSTALLED_SHELL="fish"
else
  DETECTED_INSTALLED_SHELL=""
fi

if [ -n "$DETECTED_INSTALLED_SHELL" ]; then
  echo -e "${YELLOW}  DXSBash is already installed (${DETECTED_INSTALLED_SHELL}).${RC}"
  if [ "$NONINTERACTIVE" -eq 1 ]; then
    echo -e "${YELLOW}  --yes set: proceeding with reinstall anyway.${RC}"
    echo ""
  else
    echo -e "  ${WHITE}1)${RC} Reinstall (reclones, overwrites)"
    echo -e "  ${WHITE}2)${RC} Repair    ${YELLOW}(recommended)${RC}"
    echo -e "  ${WHITE}3)${RC} Cancel"
    read -p "  Choice [1-3] (default: 2): " _existing_choice
    case "$_existing_choice" in
      1) ;;                                    # fall through to install
      3) echo -e "${YELLOW}Cancelled.${RC}"; exit 0 ;;
      *)
        REPAIR_ARGS=()
        if [ -x "$SCRIPT_DIR/repair.sh" ]; then
          exec "$SCRIPT_DIR/repair.sh" "${REPAIR_ARGS[@]}"
        else
          exec "$USER_HOME/linuxtoolbox/dxsbash/repair.sh" "${REPAIR_ARGS[@]}"
        fi
        ;;
    esac
    echo ""
  fi
fi

#=================================================================
# Pre-flight summary (called from main() after shell is chosen)
#=================================================================
show_preflight() {
  local shell_label="${SELECTED_SHELL:-bash}"
  echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${BLUE}║  ${WHITE}Install plan${BLUE}                                          ║${RC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
  echo -e "  ${CYAN}User:${RC}          $REAL_USER"
  echo -e "  ${CYAN}Home:${RC}          $USER_HOME"
  echo -e "  ${CYAN}Shell target:${RC}  $shell_label"
  echo -e "  ${CYAN}Repo dir:${RC}      $USER_HOME/linuxtoolbox/dxsbash"
  echo -e "  ${CYAN}Log file:${RC}      $LOG_FILE"
  [ "$DRY_RUN" -eq 1 ] && echo -e "  ${YELLOW}DRY-RUN: no changes will be made${RC}"
  echo ""
  echo -e "${CYAN}Will install/link:${RC}"
  echo -e "  • ~/.${shell_label}rc (or equivalent) → dxsbash repo"
  echo -e "  • ~/.config/starship.toml, ~/.config/fastfetch/config.jsonc"
  echo -e "  • /usr/local/bin/{update-dxsbash,dxsbash-config,"
  echo -e "                    dxsbash-repair,dxsbash-uninstall,reset-shell-profile}"
  echo -e "  • System packages via apt/nala (requires sudo)"
  echo -e "  • FiraCode Nerd Font, starship, zoxide, fzf"
  echo ""

  if [ "$NONINTERACTIVE" -eq 0 ] && [ -t 0 ]; then
    read -p "  Proceed? (Y/n): " _ok
    if [[ "$_ok" =~ ^[Nn]$ ]]; then
      echo -e "${YELLOW}Aborted.${RC}"
      exit 0
    fi
    echo ""
  fi
}

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
    else
      DEBIAN_VERSION=$(cat /etc/debian_version)
      echo -e "${GREEN}  ✓ Detected ${WHITE}Debian Linux ${CYAN}(${DEBIAN_VERSION})${RC}"
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
  COMMON_DEPENDENCIES='bash tar bat tree multitail curl wget unzip fontconfig joe git nano zoxide fzf pwgen ripgrep fastfetch'

  # Shell-specific dependencies
  BASH_DEPENDENCIES="bash bash-completion btop"
  ZSH_DEPENDENCIES="zsh zsh-autosuggestions zsh-syntax-highlighting"
  FISH_DEPENDENCIES="fish"

  # Combine dependencies based on the selected shell
  DEPENDENCIES="$COMMON_DEPENDENCIES nala plocate trash-cli powerline"

  # Add shell-specific dependencies
  if [ "$SELECTED_SHELL" = "bash" ]; then
    DEPENDENCIES="$DEPENDENCIES $BASH_DEPENDENCIES"
  elif [ "$SELECTED_SHELL" = "zsh" ]; then
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

  # Install FiraCode Nerd Font if missing
  FONT_NAME="FiraCode Nerd Font"
  if fc-list | grep -q "FiraCode"; then
    echo -e "${GREEN}  ✓ Font '$FONT_NAME' is already installed${RC}"
  else
    echo -e "${YELLOW}  Installing font '$FONT_NAME'...${RC}"
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
    local FONT_DIR="$USER_HOME/.local/share/fonts"

    if wget -q --spider "$FONT_URL"; then
      local TEMP_DIR
      TEMP_DIR=$(mktemp -d)
      if wget -q --show-progress "$FONT_URL" -O "$TEMP_DIR/FiraCode.zip"; then
        if unzip -q "$TEMP_DIR/FiraCode.zip" -d "$TEMP_DIR"; then
          as_user mkdir -p "$FONT_DIR/FiraCode"
          # Support both flat-zip (v3.x) and nested layouts
          find "$TEMP_DIR" -type f -name '*.ttf' -exec mv {} "$FONT_DIR/FiraCode/" \; 2>/dev/null || true
          if [ "$(id -u)" -eq 0 ]; then
            chown -R "$REAL_USER:$REAL_GROUP" "$FONT_DIR/FiraCode" 2>/dev/null || true
          fi
          as_user fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
          echo -e "${GREEN}  ✓ Font '$FONT_NAME' installed successfully${RC}"
        else
          echo -e "${YELLOW}  ⚠ Failed to unzip font; continuing without it${RC}"
        fi
      else
        echo -e "${YELLOW}  ⚠ Font download failed; continuing without it${RC}"
      fi
      rm -rf "$TEMP_DIR"
    else
      echo -e "${YELLOW}  ⚠ Font URL not accessible; continuing without font${RC}"
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
    if [ -d "$USER_HOME/.fzf" ]; then
      echo -e "${YELLOW}  ~/.fzf already exists; skipping clone${RC}"
    else
      as_user git clone --depth 1 https://github.com/junegunn/fzf.git "$USER_HOME/.fzf"
    fi
    as_user "$USER_HOME/.fzf/install" --all --no-update-rc >/dev/null || \
      echo -e "${YELLOW}  ⚠ fzf installer returned non-zero; continuing${RC}"
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
# Shell selection
#
# Honours (in order): --shell flag, DXSBASH_SHELL env var, interactive
# prompt. Non-interactive runs without a shell choice default to bash.
#=================================================================
selectShell() {
  # Already chosen via --shell or DXSBASH_SHELL
  if [ -n "$SELECTED_SHELL" ]; then
    echo -e "${GREEN}  ✓ Using shell: ${WHITE}$SELECTED_SHELL${RC}"
    echo ""
    return
  fi

  if [ "$NONINTERACTIVE" -eq 1 ] || [ ! -t 0 ]; then
    SELECTED_SHELL="bash"
    echo -e "${GREEN}  ✓ Non-interactive: defaulting to ${WHITE}bash${RC}"
    echo ""
    return
  fi

  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${RC}"
  echo -e "${CYAN}║             Select your preferred shell:               ║${RC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${RC}"
  echo -e "  ${WHITE}1)${RC} ${GREEN}Bash${RC}      ${YELLOW}(default, most compatible)${RC}"
  echo -e "  ${WHITE}2)${RC} ${GREEN}Zsh${RC}       ${YELLOW}(enhanced features, popular alternative)${RC}"
  echo -e "  ${WHITE}3)${RC} ${GREEN}Fish${RC}      ${YELLOW}(modern, user-friendly, less POSIX-compatible)${RC}"
  echo ""

  read -p "  Enter your choice [1-3] (default: 1): " shell_choice

  case "$shell_choice" in
    2) SELECTED_SHELL="zsh"  ;;
    3) SELECTED_SHELL="fish" ;;
    *) SELECTED_SHELL="bash" ;;
  esac

  echo -e "${GREEN}  ✓ Selected shell: ${WHITE}$SELECTED_SHELL${RC}"
  echo ""
}

#=================================================================
# Configuration setup
#=================================================================
create_fastfetch_config() {
  echo -e "${CYAN}▶ Setting up fastfetch configuration...${RC}"

  if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
    as_user mkdir -p "$USER_HOME/.config/fastfetch"
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

  # Make sure all required directories exist (owned by the real user)
  as_user mkdir -p "$USER_HOME/.config/fish"
  as_user mkdir -p "$USER_HOME/.zsh"

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

    # Setup Fisher plugin manager if not already installed.
    # NOTE: the old https://git.io/fisher redirect was shut down by
    # GitHub in 2022; install directly from the canonical location.
    if ! fish -c "type -q fisher" 2>/dev/null; then
      echo -e "${YELLOW}  Installing Fisher plugin manager for Fish...${RC}"
      local FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish"
      if fish -c "curl -sSfL $FISHER_URL | source && fisher install jorgebucaran/fisher"; then
        echo -e "${GREEN}  ✓ Fisher installed${RC}"

        echo -e "${YELLOW}  Installing Fish plugins...${RC}"
        fish -c "fisher install PatrickF1/fzf.fish" || \
          echo -e "${YELLOW}  ⚠ Could not install fzf.fish${RC}"
        fish -c "fisher install jethrokuan/z"      || \
          echo -e "${YELLOW}  ⚠ Could not install jethrokuan/z${RC}"
        fish -c "fisher install IlanCosman/tide@v5" || \
          echo -e "${YELLOW}  ⚠ Could not install tide${RC}"
        echo -e "${GREEN}  ✓ Fish plugins installed${RC}"
      else
        echo -e "${YELLOW}  ⚠ Fisher install failed; continuing without plugins${RC}"
      fi
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

  # Change the default shell. Disable errexit locally so a chsh
  # failure (PAM, shell not yet in /etc/shells on some distros, etc.)
  # does not abort the rest of the install.
  echo -e "${YELLOW}  Changing default shell to ${WHITE}$SHELL_PATH${RC}"
  local chsh_rc=0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${YELLOW}[dry-run]${RC} ${SUDO_CMD} chsh -s $SHELL_PATH $REAL_USER"
  else
    set +e
    ${SUDO_CMD} chsh -s "$SHELL_PATH" "$REAL_USER"
    chsh_rc=$?
    set -e
  fi

  if [ "$chsh_rc" -eq 0 ]; then
    echo -e "${GREEN}  ✓ Successfully set $SELECTED_SHELL as your default shell${RC}"
  else
    echo -e "${RED}  ✗ Failed to set $SELECTED_SHELL as your default shell (chsh rc=$chsh_rc).${RC}"
    echo -e "${YELLOW}  You can set it manually with:${RC}"
    echo -e "${WHITE}    chsh -s $SHELL_PATH${RC}"
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

  if [ -f "$GITPATH/updater.sh" ]; then
    chmod +x "$GITPATH/updater.sh"

    # System-wide: /usr/local/bin/update-dxsbash points at the repo copy
    # so updates self-propagate.
    ${SUDO_CMD} ln -sf "$GITPATH/updater.sh" /usr/local/bin/update-dxsbash

    # Convenience symlink in the real user's home
    as_user ln -sf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh"

    echo -e "${GREEN}  ✓ Updater script installed successfully${RC}"
    echo -e "    Run ${WHITE}update-dxsbash${RC} to pull the latest version."
  else
    echo -e "${RED}  ✗ Updater script not found in $GITPATH${RC}"
    echo -e "${YELLOW}  You will need to update manually${RC}"
  fi
  echo ""
}

installConfigCommand() {
  echo -e "${CYAN}▶ Installing dxsbash-config command...${RC}"

  if [ -f "$GITPATH/dxsbash-config.sh" ]; then
    cp -p "$GITPATH/dxsbash-config.sh" "$LINUXTOOLBOXDIR/"
    chmod +x "$LINUXTOOLBOXDIR/dxsbash-config.sh"

    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/dxsbash-config.sh" /usr/local/bin/dxsbash-config

    echo -e "${GREEN}  ✓ Configuration tool installed${RC}"
    echo -e "    Run ${WHITE}dxsbash-config${RC} to customise your environment."
  else
    echo -e "${RED}  ✗ dxsbash-config.sh not found in $GITPATH${RC}"
  fi
  echo ""
}

installLifecycleCommands() {
  echo -e "${CYAN}▶ Installing repair/uninstall commands...${RC}"
  for src in repair.sh uninstall.sh; do
    if [ -f "$GITPATH/$src" ]; then
      chmod +x "$GITPATH/$src"
      case "$src" in
        repair.sh)    link_name="dxsbash-repair" ;;
        uninstall.sh) link_name="dxsbash-uninstall" ;;
      esac
      ${SUDO_CMD} ln -sf "$GITPATH/$src" "/usr/local/bin/$link_name"
      echo -e "${GREEN}  ✓ /usr/local/bin/$link_name${RC}"
    else
      echo -e "${YELLOW}  ⚠ $src missing in repo${RC}"
    fi
  done
  echo ""
}

#=================================================================
# Configure terminal
#=================================================================
configure_terminal() {
  echo -e "${CYAN}▶ Configuring terminal emulators...${RC}"

  # Resolve the command to run inside Konsole/Yakuake profiles so that
  # the selected shell (bash|zsh|fish) is actually launched instead of
  # the system default /usr/bin/bash.
  case "${SELECTED_SHELL:-bash}" in
    zsh)  PROFILE_SHELL_CMD="$(command -v zsh  2>/dev/null || echo /usr/bin/zsh)"  ;;
    fish) PROFILE_SHELL_CMD="$(command -v fish 2>/dev/null || echo /usr/bin/fish)" ;;
    *)    PROFILE_SHELL_CMD="$(command -v bash 2>/dev/null || echo /bin/bash)"     ;;
  esac

  # Helper: ensure DefaultProfile=DXSBash.profile lives under [Desktop Entry]
  # in the given rc file (konsolerc / yakuakerc), creating the file or
  # section as needed.
  set_default_profile() {
    local rcfile="$1"
    mkdir -p "$(dirname "$rcfile")"
    if [ ! -f "$rcfile" ]; then
      cat > "$rcfile" <<EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile
EOL
    elif grep -q "^\[Desktop Entry\]" "$rcfile"; then
      if grep -q "^DefaultProfile=" "$rcfile"; then
        sed -i "s|^DefaultProfile=.*|DefaultProfile=DXSBash.profile|" "$rcfile"
      else
        sed -i "/^\[Desktop Entry\]/a DefaultProfile=DXSBash.profile" "$rcfile"
      fi
    else
      printf '\n[Desktop Entry]\nDefaultProfile=DXSBash.profile\n' >> "$rcfile"
    fi
    if [ "$(id -u)" -eq 0 ]; then
      chown "$REAL_USER:$REAL_GROUP" "$rcfile"
    fi
  }

  # Configure Konsole if present
  if command_exists konsole; then
    echo -e "${YELLOW}  Configuring Konsole terminal...${RC}"

    # Create Konsole profile directory if it doesn't exist
    KONSOLE_DIR="$USER_HOME/.local/share/konsole"
    mkdir -p "$KONSOLE_DIR"

    # Create/update Konsole profile with FiraCode Nerd Font
    PROFILE_NAME="DXSBash.profile"
    PROFILE_PATH="$KONSOLE_DIR/$PROFILE_NAME"

    # Create profile file. Command= pins the shell to the one selected
    # during setup so new Konsole tabs launch zsh/fish when chosen.
    cat > "$PROFILE_PATH" << EOL
[Appearance]
ColorScheme=Breeze
Font=FiraCode Nerd Font,12,-1,5,50,0,0,0,0,0

[General]
Command=$PROFILE_SHELL_CMD
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

    # Set correct permissions (only relevant when running under sudo)
    if [ "$(id -u)" -eq 0 ]; then
      chown "$REAL_USER:$REAL_GROUP" "$PROFILE_PATH"
    fi

    # Update konsolerc to use this profile as the default
    set_default_profile "$USER_HOME/.config/konsolerc"

    echo -e "${GREEN}  ✓ Konsole configured${RC}"
  fi

  # Configure Yakuake if present (shares Konsole profiles)
  if command_exists yakuake; then
    echo -e "${YELLOW}  Configuring Yakuake terminal...${RC}"

    set_default_profile "$USER_HOME/.config/yakuakerc"

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

  # Create runtime logs dir in the real user's home
  echo -e "${YELLOW}  Creating log directory...${RC}"
  as_user mkdir -p "$USER_HOME/.dxsbash/logs"
  as_user touch   "$USER_HOME/.dxsbash/logs/dxsbash.log"
  as_user chmod 644 "$USER_HOME/.dxsbash/logs/dxsbash.log"

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

  # Select shell (honours --shell / DXSBASH_SHELL / prompt)
  selectShell

  # Show plan and ask for confirmation
  show_preflight

  # Clone or pull repo (safe when re-run from inside)
  initialize

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
  installConfigCommand
  installLifecycleCommands
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
  echo -e "${BLUE}║  ${WHITE}• Update:${YELLOW} update-dxsbash${BLUE}             ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Repair:${YELLOW} dxsbash-repair${BLUE}             ${RC}"
  echo -e "${BLUE}║  ${WHITE}• Uninstall:${YELLOW} dxsbash-uninstall${BLUE}          ${RC}"
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
  echo -e "  ${CYAN}Made by Luis Miguel P. Freitas - DigitalXS.ca - 2025${RC}"
  echo ""
}

# Run the main installation
main
