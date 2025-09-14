#!/bin/bash
#=================================================================
# DXSBash - Excessive Shell Environment for Linux
# Compatible with: Debian 13, Fedora 42, Arch Linux (latest)
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Version: 3.0.2
# License: GPL-3.0
#=================================================================

# Set error handling - continue on non-critical errors
set -euo pipefail
IFS=$'\n\t'

#=================================================================
# Color definitions for rich terminal output
#=================================================================
readonly RC='\033[0m'          # Reset Color
readonly RED='\033[1;31m'      # Bold Red
readonly YELLOW='\033[1;33m'   # Bold Yellow
readonly GREEN='\033[1;32m'    # Bold Green
readonly BLUE='\033[1;34m'     # Bold Blue
readonly CYAN='\033[1;36m'     # Bold Cyan
readonly WHITE='\033[1;37m'    # Bold White
readonly PURPLE='\033[1;35m'   # Bold Purple

#=================================================================
# Global Variables
#=================================================================
DISTRO_ID=""
DISTRO_VERSION=""
DISTRO_FAMILY=""
PKG_MANAGER=""
PKG_INSTALL_CMD=""
PKG_UPDATE_CMD=""
SUDO_CMD=""
SELECTED_SHELL=""
USER_HOME=""
SCRIPT_DIR=""
ERRORS_OCCURRED=0
WARNINGS_OCCURRED=0

#=================================================================
# Utility Functions
#=================================================================
log_error() {
    echo -e "${RED}[ERROR]${RC} $1" >&2
    ((ERRORS_OCCURRED++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RC} $1"
    ((WARNINGS_OCCURRED++))
}

log_info() {
    echo -e "${CYAN}[INFO]${RC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a normal user."
        exit 1
    fi
}

get_sudo_command() {
    if command_exists sudo; then
        # Check if user can use sudo
        if sudo -n true 2>/dev/null; then
            echo "sudo"
        elif groups | grep -qE "(sudo|wheel|admin)"; then
            echo "sudo"
        else
            log_warning "User is not in sudoers. Some operations may fail."
            echo ""
        fi
    elif command_exists doas; then
        echo "doas"
    else
        log_warning "No privilege escalation tool found (sudo/doas)."
        echo ""
    fi
}

#=================================================================
# Distribution Detection
#=================================================================
detect_distribution() {
    log_info "Detecting Linux distribution..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        
        # Determine distribution family
        case "${DISTRO_ID}" in
            debian|ubuntu|linuxmint|pop|elementary|kali|parrot|raspbian)
                DISTRO_FAMILY="debian"
                ;;
            fedora|rhel|centos|rocky|almalinux|oracle|scientific)
                DISTRO_FAMILY="redhat"
                ;;
            arch|manjaro|endeavouros|artix|arcolinux|garuda)
                DISTRO_FAMILY="arch"
                ;;
            opensuse*|sles|suse)
                DISTRO_FAMILY="suse"
                ;;
            gentoo|funtoo)
                DISTRO_FAMILY="gentoo"
                ;;
            void)
                DISTRO_FAMILY="void"
                ;;
            alpine)
                DISTRO_FAMILY="alpine"
                ;;
            *)
                # Check ID_LIKE for derivatives
                if [[ -n "${ID_LIKE:-}" ]]; then
                    case "${ID_LIKE}" in
                        *debian*|*ubuntu*)
                            DISTRO_FAMILY="debian"
                            ;;
                        *fedora*|*rhel*|*centos*)
                            DISTRO_FAMILY="redhat"
                            ;;
                        *arch*)
                            DISTRO_FAMILY="arch"
                            ;;
                        *suse*)
                            DISTRO_FAMILY="suse"
                            ;;
                        *)
                            DISTRO_FAMILY="unknown"
                            ;;
                    esac
                else
                    DISTRO_FAMILY="unknown"
                fi
                ;;
        esac
    else
        log_error "Cannot detect distribution. /etc/os-release not found."
        DISTRO_FAMILY="unknown"
    fi
    
    log_success "Detected: ${DISTRO_ID^} (${DISTRO_FAMILY} family)"
}

#=================================================================
# Package Manager Setup
#=================================================================
setup_package_manager() {
    log_info "Setting up package manager..."
    
    case "${DISTRO_FAMILY}" in
        debian)
            PKG_MANAGER="apt"
            PKG_UPDATE_CMD="${SUDO_CMD} apt update"
            PKG_INSTALL_CMD="${SUDO_CMD} apt install -y"
            ;;
        redhat)
            if command_exists dnf; then
                PKG_MANAGER="dnf"
                PKG_UPDATE_CMD="${SUDO_CMD} dnf check-update || true"
                PKG_INSTALL_CMD="${SUDO_CMD} dnf install -y"
            elif command_exists yum; then
                PKG_MANAGER="yum"
                PKG_UPDATE_CMD="${SUDO_CMD} yum check-update || true"
                PKG_INSTALL_CMD="${SUDO_CMD} yum install -y"
            else
                log_error "No package manager found for RedHat-based system"
                return 1
            fi
            ;;
        arch)
            PKG_MANAGER="pacman"
            PKG_UPDATE_CMD="${SUDO_CMD} pacman -Sy"
            PKG_INSTALL_CMD="${SUDO_CMD} pacman -S --noconfirm --needed"
            ;;
        suse)
            PKG_MANAGER="zypper"
            PKG_UPDATE_CMD="${SUDO_CMD} zypper refresh"
            PKG_INSTALL_CMD="${SUDO_CMD} zypper install -y"
            ;;
        gentoo)
            PKG_MANAGER="emerge"
            PKG_UPDATE_CMD="${SUDO_CMD} emerge --sync"
            PKG_INSTALL_CMD="${SUDO_CMD} emerge"
            ;;
        void)
            PKG_MANAGER="xbps"
            PKG_UPDATE_CMD="${SUDO_CMD} xbps-install -S"
            PKG_INSTALL_CMD="${SUDO_CMD} xbps-install -y"
            ;;
        alpine)
            PKG_MANAGER="apk"
            PKG_UPDATE_CMD="${SUDO_CMD} apk update"
            PKG_INSTALL_CMD="${SUDO_CMD} apk add"
            ;;
        *)
            log_error "Unsupported distribution family: ${DISTRO_FAMILY}"
            return 1
            ;;
    esac
    
    log_success "Package manager configured: ${PKG_MANAGER}"
}

#=================================================================
# Display Welcome Banner
#=================================================================
display_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║                                                        ║${RC}"
    echo -e "${BLUE}║  ${WHITE}██████╗ ██╗  ██╗███████╗██████╗  █████╗ ███████╗██╗  ██╗${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${WHITE}██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║  ██║${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${WHITE}██║  ██║ ╚███╔╝ ███████╗██████╔╝███████║███████╗███████║${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${WHITE}██║  ██║ ██╔██╗ ╚════██║██╔══██╗██╔══██║╚════██║██╔══██║${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${WHITE}██████╔╝██╔╝ ██╗███████║██████╔╝██║  ██║███████║██║  ██║${BLUE}  ${RC}"
    echo -e "${BLUE}║  ${WHITE}╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${BLUE}  ${RC}"
    echo -e "${BLUE}║                                                        ║${RC}"
    echo -e "${BLUE}║  ${CYAN}An Excessive Shell Environment v3.0.2${BLUE}                    ║${RC}"
    echo -e "${BLUE}║  ${YELLOW}Compatible with: Debian, Fedora, Arch${BLUE}                 ║${RC}"
    echo -e "${BLUE}║                                                        ║${RC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
}

#=================================================================
# Package Name Mapping
#=================================================================
get_package_name() {
    local generic_name="$1"
    
    case "${DISTRO_FAMILY}" in
        debian)
            case "${generic_name}" in
                "bat") echo "bat" ;;
                "fd") echo "fd-find" ;;
                "ripgrep") echo "ripgrep" ;;
                "neovim") echo "neovim" ;;
                "starship") echo "" ;; # Not in repos, install manually
                "zoxide") echo "" ;; # Not in repos, install manually
                "fzf") echo "fzf" ;;
                "trash-cli") echo "trash-cli" ;;
                "exa") echo "" ;; # Not in repos
                "eza") echo "" ;; # Not in repos
                *) echo "${generic_name}" ;;
            esac
            ;;
        redhat)
            case "${generic_name}" in
                "bat") echo "bat" ;;
                "fd") echo "fd-find" ;;
                "ripgrep") echo "ripgrep" ;;
                "neovim") echo "neovim" ;;
                "build-essential") echo "@development-tools" ;;
                "starship") echo "" ;; # Not in repos, install manually
                "zoxide") echo "" ;; # Not in repos, install manually
                "fzf") echo "fzf" ;;
                "trash-cli") echo "trash-cli" ;;
                *) echo "${generic_name}" ;;
            esac
            ;;
        arch)
            case "${generic_name}" in
                "bat") echo "bat" ;;
                "fd") echo "fd" ;;
                "ripgrep") echo "ripgrep" ;;
                "neovim") echo "neovim" ;;
                "build-essential") echo "base-devel" ;;
                "starship") echo "starship" ;;
                "zoxide") echo "zoxide" ;;
                "fzf") echo "fzf" ;;
                "trash-cli") echo "trash-cli" ;;
                "exa") echo "exa" ;;
                "eza") echo "eza" ;;
                *) echo "${generic_name}" ;;
            esac
            ;;
        *)
            echo "${generic_name}"
            ;;
    esac
}

#=================================================================
# Install Package
#=================================================================
install_package() {
    local package="$1"
    local mapped_package
    mapped_package=$(get_package_name "${package}")
    
    if [[ -z "${mapped_package}" ]]; then
        log_warning "Package '${package}' not available in repositories, will install manually"
        return 1
    fi
    
    log_info "Installing ${package} (${mapped_package})..."
    
    if ${PKG_INSTALL_CMD} "${mapped_package}" >/dev/null 2>&1; then
        log_success "Installed ${package}"
        return 0
    else
        log_warning "Failed to install ${package}"
        return 1
    fi
}

#=================================================================
# Install Dependencies
#=================================================================
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update package database
    log_info "Updating package database..."
    ${PKG_UPDATE_CMD} >/dev/null 2>&1 || log_warning "Package database update had warnings"
    
    # Core dependencies by category
    local core_deps=(
        "curl"
        "wget"
        "git"
        "tar"
        "unzip"
        "fontconfig"
    )
    
    local shell_deps=(
        "bash"
        "bash-completion"
    )
    
    local tools_deps=(
        "tree"
        "nano"
        "neovim"
        "fzf"
        "ripgrep"
        "bat"
        "fd"
        "trash-cli"
    )
    
    # Install core dependencies
    for dep in "${core_deps[@]}"; do
        if ! command_exists "${dep}"; then
            install_package "${dep}"
        else
            log_success "${dep} already installed"
        fi
    done
    
    # Install shell dependencies
    for dep in "${shell_deps[@]}"; do
        install_package "${dep}" || true
    done
    
    # Install tool dependencies
    for dep in "${tools_deps[@]}"; do
        install_package "${dep}" || true
    done
    
    # Shell-specific dependencies
    case "${SELECTED_SHELL}" in
        zsh)
            install_package "zsh" || log_error "Failed to install zsh"
            install_package "zsh-completions" || true
            install_package "zsh-autosuggestions" || true
            install_package "zsh-syntax-highlighting" || true
            ;;
        fish)
            install_package "fish" || log_error "Failed to install fish"
            ;;
    esac
    
    # Install tools that need manual installation
    install_starship
    install_zoxide
    install_fastfetch
    install_fonts
}

#=================================================================
# Install Starship Prompt
#=================================================================
install_starship() {
    if command_exists starship; then
        log_success "Starship already installed"
        return 0
    fi
    
    log_info "Installing Starship prompt..."
    
    if [[ "${DISTRO_FAMILY}" == "arch" ]]; then
        install_package "starship"
    else
        # Manual installation for other distros
        if curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1; then
            log_success "Starship installed"
        else
            log_warning "Failed to install Starship"
        fi
    fi
}

#=================================================================
# Install Zoxide
#=================================================================
install_zoxide() {
    if command_exists zoxide; then
        log_success "Zoxide already installed"
        return 0
    fi
    
    log_info "Installing Zoxide..."
    
    if [[ "${DISTRO_FAMILY}" == "arch" ]]; then
        install_package "zoxide"
    else
        # Manual installation for other distros
        if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >/dev/null 2>&1; then
            log_success "Zoxide installed"
        else
            log_warning "Failed to install Zoxide"
        fi
    fi
}

#=================================================================
# Install Fastfetch
#=================================================================
install_fastfetch() {
    if command_exists fastfetch; then
        log_success "Fastfetch already installed"
        return 0
    fi
    
    log_info "Installing Fastfetch..."
    
    case "${DISTRO_FAMILY}" in
        debian)
            # Try to install from GitHub releases
            local version="2.8.0"
            local arch=$(dpkg --print-architecture)
            local url="https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-linux-${arch}.deb"
            
            if wget -q "${url}" -O /tmp/fastfetch.deb; then
                ${SUDO_CMD} dpkg -i /tmp/fastfetch.deb >/dev/null 2>&1
                rm /tmp/fastfetch.deb
                log_success "Fastfetch installed"
            else
                log_warning "Failed to install Fastfetch"
            fi
            ;;
        redhat)
            # Try to install from GitHub releases
            local version="2.8.0"
            local arch=$(uname -m)
            local url="https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-linux-${arch}.rpm"
            
            if wget -q "${url}" -O /tmp/fastfetch.rpm; then
                ${SUDO_CMD} rpm -i /tmp/fastfetch.rpm >/dev/null 2>&1
                rm /tmp/fastfetch.rpm
                log_success "Fastfetch installed"
            else
                log_warning "Failed to install Fastfetch"
            fi
            ;;
        arch)
            install_package "fastfetch"
            ;;
        *)
            log_warning "Fastfetch installation not supported for ${DISTRO_FAMILY}"
            ;;
    esac
}

#=================================================================
# Install Fonts
#=================================================================
install_fonts() {
    log_info "Installing FiraCode Nerd Font..."
    
    local font_dir="${USER_HOME}/.local/share/fonts"
    mkdir -p "${font_dir}"
    
    # Check if font already installed
    if fc-list | grep -q "FiraCode"; then
        log_success "FiraCode Nerd Font already installed"
        return 0
    fi
    
    # Download and install font
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if wget -q "${font_url}" -O "${temp_dir}/FiraCode.zip"; then
        unzip -q "${temp_dir}/FiraCode.zip" -d "${temp_dir}"
        cp "${temp_dir}"/*.ttf "${font_dir}/" 2>/dev/null || true
        fc-cache -fv >/dev/null 2>&1
        rm -rf "${temp_dir}"
        log_success "FiraCode Nerd Font installed"
    else
        rm -rf "${temp_dir}"
        log_warning "Failed to install FiraCode Nerd Font"
    fi
}

#=================================================================
# Shell Selection
#=================================================================
select_shell() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${CYAN}║              Select Your Preferred Shell                ║${RC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${RC}"
    echo -e "  ${WHITE}1)${RC} ${GREEN}Bash${RC}      ${YELLOW}(default, most compatible)${RC}"
    echo -e "  ${WHITE}2)${RC} ${GREEN}Zsh${RC}       ${YELLOW}(enhanced features, Oh-My-Zsh)${RC}"
    echo -e "  ${WHITE}3)${RC} ${GREEN}Fish${RC}      ${YELLOW}(modern, user-friendly)${RC}"
    echo ""
    
    read -p "  Enter your choice [1-3] (default: 1): " shell_choice
    
    case "${shell_choice}" in
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
    
    log_success "Selected shell: ${SELECTED_SHELL}"
    echo ""
}

#=================================================================
# Setup Shell Configuration
#=================================================================
setup_shell_config() {
    log_info "Setting up ${SELECTED_SHELL} configuration..."
    
    # Create config directories
    mkdir -p "${USER_HOME}/.config"
    
    # Link or copy configuration files
    case "${SELECTED_SHELL}" in
        bash)
            backup_and_link ".bashrc" "${USER_HOME}/.bashrc"
            backup_and_link ".bashrc_help" "${USER_HOME}/.bashrc_help"
            backup_and_link ".bash_aliases" "${USER_HOME}/.bash_aliases"
            ;;
        zsh)
            backup_and_link ".zshrc" "${USER_HOME}/.zshrc"
            backup_and_link ".zshrc_help" "${USER_HOME}/.zshrc_help"
            install_oh_my_zsh
            ;;
        fish)
            mkdir -p "${USER_HOME}/.config/fish"
            backup_and_link "config.fish" "${USER_HOME}/.config/fish/config.fish"
            backup_and_link "fish_help" "${USER_HOME}/.config/fish/fish_help"
            install_fisher
            ;;
    esac
    
    # Setup common configurations
    backup_and_link "starship.toml" "${USER_HOME}/.config/starship.toml"
    
    # Setup fastfetch config
    mkdir -p "${USER_HOME}/.config/fastfetch"
    backup_and_link "config.jsonc" "${USER_HOME}/.config/fastfetch/config.jsonc"
    
    log_success "Shell configuration completed"
}

#=================================================================
# Backup and Link Files
#=================================================================
backup_and_link() {
    local source_file="$1"
    local target_file="$2"
    
    # Check if source file exists
    if [[ ! -f "${SCRIPT_DIR}/${source_file}" ]]; then
        log_warning "Source file ${source_file} not found"
        return 1
    fi
    
    # Backup existing file
    if [[ -f "${target_file}" ]] && [[ ! -L "${target_file}" ]]; then
        local backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"
        mv "${target_file}" "${backup_file}"
        log_info "Backed up existing file to ${backup_file}"
    fi
    
    # Remove existing symlink
    if [[ -L "${target_file}" ]]; then
        rm "${target_file}"
    fi
    
    # Create symlink or copy
    if ln -sf "${SCRIPT_DIR}/${source_file}" "${target_file}" 2>/dev/null; then
        log_success "Linked ${source_file}"
    else
        # Fallback to copy if symlink fails
        cp "${SCRIPT_DIR}/${source_file}" "${target_file}"
        log_success "Copied ${source_file}"
    fi
}

#=================================================================
# Install Oh-My-Zsh
#=================================================================
install_oh_my_zsh() {
    if [[ -d "${USER_HOME}/.oh-my-zsh" ]]; then
        log_success "Oh-My-Zsh already installed"
        return 0
    fi
    
    log_info "Installing Oh-My-Zsh..."
    
    export RUNZSH=no
    export CHSH=no
    
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1; then
        log_success "Oh-My-Zsh installed"
    else
        log_warning "Failed to install Oh-My-Zsh"
    fi
}

#=================================================================
# Install Fisher (Fish Plugin Manager)
#=================================================================
install_fisher() {
    log_info "Installing Fisher plugin manager..."
    
    if fish -c "type -q fisher" 2>/dev/null; then
        log_success "Fisher already installed"
        return 0
    fi
    
    fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" 2>/dev/null || {
        log_warning "Failed to install Fisher"
        return 1
    }
    
    # Install useful Fish plugins
    log_info "Installing Fish plugins..."
    fish -c "fisher install PatrickF1/fzf.fish" 2>/dev/null || true
    fish -c "fisher install jethrokuan/z" 2>/dev/null || true
    
    log_success "Fisher and plugins installed"
}

#=================================================================
# Set Default Shell
#=================================================================
set_default_shell() {
    log_info "Setting ${SELECTED_SHELL} as default shell..."
    
    local shell_path
    shell_path=$(command -v "${SELECTED_SHELL}")
    
    if [[ -z "${shell_path}" ]]; then
        log_error "Selected shell ${SELECTED_SHELL} not found"
        return 1
    fi
    
    # Add shell to /etc/shells if not present
    if ! grep -q "^${shell_path}$" /etc/shells; then
        echo "${shell_path}" | ${SUDO_CMD} tee -a /etc/shells >/dev/null
    fi
    
    # Change default shell
    if ${SUDO_CMD} chsh -s "${shell_path}" "${USER}" 2>/dev/null; then
        log_success "Default shell changed to ${SELECTED_SHELL}"
    else
        log_warning "Failed to change default shell. You can do this manually with: chsh -s ${shell_path}"
    fi
}

#=================================================================
# Install System Scripts
#=================================================================
install_system_scripts() {
    log_info "Installing system scripts..."
    
    local scripts=(
        "updater.sh"
        "reset-bash-profile.sh"
        "reset-zsh-profile.sh"
        "reset-fish-profile.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${script}" ]]; then
            chmod +x "${SCRIPT_DIR}/${script}"
            log_success "Made ${script} executable"
        fi
    done
    
    # Create update command alias
    if [[ -n "${SUDO_CMD}" ]]; then
        ${SUDO_CMD} ln -sf "${SCRIPT_DIR}/updater.sh" /usr/local/bin/update-dxsbash 2>/dev/null || {
            log_warning "Could not create system-wide update command"
        }
    fi
}

#=================================================================
# Final Summary
#=================================================================
show_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║              Installation Summary                       ║${RC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
    echo -e "  ${GREEN}Distribution:${RC} ${DISTRO_ID^} (${DISTRO_FAMILY})"
    echo -e "  ${GREEN}Shell:${RC} ${SELECTED_SHELL}"
    echo -e "  ${GREEN}Errors:${RC} ${ERRORS_OCCURRED}"
    echo -e "  ${GREEN}Warnings:${RC} ${WARNINGS_OCCURRED}"
    echo ""
    
    if [[ ${ERRORS_OCCURRED} -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Installation completed successfully!${RC}"
    else
        echo -e "  ${YELLOW}⚠ Installation completed with errors${RC}"
        echo -e "  ${YELLOW}  Some features may not work properly${RC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}Next steps:${RC}"
    echo -e "  1. Restart your terminal or run: ${WHITE}source ~/.${SELECTED_SHELL}rc${RC}"
    echo -e "  2. Type ${WHITE}help${RC} to see available commands"
    echo -e "  3. Run ${WHITE}update-dxsbash${RC} to update in the future"
    echo ""
}

#=================================================================
# Main Installation Flow
#=================================================================
main() {
    # Initial setup
    display_banner
    check_root
    
    # Set up environment
    USER_HOME="${HOME}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SUDO_CMD=$(get_sudo_command)
    
    # Detect system
    detect_distribution
    
    if [[ "${DISTRO_FAMILY}" == "unknown" ]]; then
        log_error "Unsupported distribution. Installation may not work correctly."
        read -p "Continue anyway? (y/N): " continue_install
        if [[ ! "${continue_install}" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Set up package manager
    setup_package_manager
    
    # Select shell
    select_shell
    
    # Install dependencies
    install_dependencies
    
    # Setup shell configuration
    setup_shell_config
    
    # Set default shell
    set_default_shell
    
    # Install system scripts
    install_system_scripts
    
    # Show summary
    show_summary
}

# Run main function
main "$@"