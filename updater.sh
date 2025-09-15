#!/bin/bash
#=================================================================
# DXSBash Updater - Cross-Distribution Compatible
# Compatible with: Debian 13, Fedora 42, Arch Linux (latest)
# Version: 3.0.3
# Author: Luis Miguel P. Freitas
# License: GPL-3.0
#=================================================================

set -euo pipefail
IFS=$'\n\t'

#=================================================================
# Color Definitions
#=================================================================
readonly RC='\033[0m'
readonly RED='\033[1;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[1;32m'
readonly BLUE='\033[1;34m'
readonly CYAN='\033[1;36m'

#=================================================================
# Global Variables
#=================================================================
DXSBASH_DIR="${HOME}/linuxtoolbox/dxsbash"
BACKUP_DIR="${HOME}/linuxtoolbox/backups"
LOG_DIR="${HOME}/.dxsbash/logs"
LOG_FILE="${LOG_DIR}/updater-$(date +%Y%m%d).log"
DETECTED_SHELL=""
ERRORS=0
SUDO_CMD=""

#=================================================================
# Logging Functions
#=================================================================
setup_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
}

log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_FILE}"
    
    case "${level}" in
        ERROR)
            echo -e "${RED}[ERROR]${RC} ${message}" >&2
            ((ERRORS++))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${RC} ${message}"
            ;;
        INFO)
            echo -e "${CYAN}[INFO]${RC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${RC} ${message}"
            ;;
    esac
}

#=================================================================
# Utility Functions
#=================================================================
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_sudo_command() {
    if command_exists sudo; then
        if sudo -n true 2>/dev/null || groups | grep -qE "(sudo|wheel|admin)"; then
            echo "sudo"
        else
            echo ""
        fi
    elif command_exists doas; then
        echo "doas"
    else
        echo ""
    fi
}

detect_current_shell() {
    if [[ -L "${HOME}/.bashrc" ]] && readlink "${HOME}/.bashrc" | grep -q dxsbash; then
        DETECTED_SHELL="bash"
    elif [[ -L "${HOME}/.zshrc" ]] && readlink "${HOME}/.zshrc" | grep -q dxsbash; then
        DETECTED_SHELL="zsh"
    elif [[ -L "${HOME}/.config/fish/config.fish" ]] && readlink "${HOME}/.config/fish/config.fish" | grep -q dxsbash; then
        DETECTED_SHELL="fish"
    else
        DETECTED_SHELL=$(basename "${SHELL:-bash}")
    fi
    
    log INFO "Detected shell: ${DETECTED_SHELL}"
}

#=================================================================
# Version Management
#=================================================================
get_current_version() {
    if [[ -f "${DXSBASH_DIR}/version.txt" ]]; then
        cat "${DXSBASH_DIR}/version.txt"
    else
        echo "unknown"
    fi
}

get_remote_version() {
    local remote_version
    remote_version=$(curl -sL https://raw.githubusercontent.com/digitalxs/dxsbash/main/version.txt 2>/dev/null || echo "")
    
    if [[ -n "${remote_version}" ]]; then
        echo "${remote_version}"
    else
        echo "unknown"
    fi
}

version_compare() {
    # Returns 0 if $1 > $2, 1 if $1 < $2, 2 if equal
    if [[ "$1" == "$2" ]]; then
        return 2
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        if ((10#${ver1[i]:-0} > 10#${ver2[i]:-0})); then
            return 0
        elif ((10#${ver1[i]:-0} < 10#${ver2[i]:-0})); then
            return 1
        fi
    done
    
    return 2
}

#=================================================================
# Backup Functions
#=================================================================
create_backup() {
    local backup_name="dxsbash-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    mkdir -p "${BACKUP_DIR}"
    
    log INFO "Creating backup at ${backup_path}"
    
    if cp -r "${DXSBASH_DIR}" "${backup_path}" 2>/dev/null; then
        # Verify backup
        if [ -d "${backup_path}" ] && [ -f "${backup_path}/version.txt" ]; then
            log SUCCESS "Backup created and verified successfully"
            echo "${backup_path}"
        else
            log ERROR "Backup verification failed"
            rm -rf "${backup_path}"
            return 1
        fi
    else
        log ERROR "Failed to create backup"
        return 1
    fi
}

restore_backup() {
    local backup_path="$1"
    
    if [[ -d "${backup_path}" ]]; then
        log INFO "Restoring from backup: ${backup_path}"
        
        rm -rf "${DXSBASH_DIR}"
        if cp -r "${backup_path}" "${DXSBASH_DIR}"; then
            log SUCCESS "Backup restored successfully"
            return 0
        else
            log ERROR "Failed to restore backup"
            return 1
        fi
    else
        log ERROR "Backup path not found: ${backup_path}"
        return 1
    fi
}

cleanup_old_backups() {
    local max_backups=5
    local backup_count
    
    backup_count=$(find "${BACKUP_DIR}" -maxdepth 1 -name "dxsbash-backup-*" -type d 2>/dev/null | wc -l)
    
    if [[ ${backup_count} -gt ${max_backups} ]]; then
        log INFO "Cleaning up old backups (keeping last ${max_backups})"
        
        find "${BACKUP_DIR}" -maxdepth 1 -name "dxsbash-backup-*" -type d -print0 2>/dev/null | \
            xargs -0 ls -dt | \
            tail -n +$((max_backups + 1)) | \
            xargs rm -rf
    fi
}

#=================================================================
# Update Functions
#=================================================================
check_prerequisites() {
    local missing_deps=()
    
    for cmd in git curl; do
        if ! command_exists "${cmd}"; then
            missing_deps+=("${cmd}")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log ERROR "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

check_network() {
    log INFO "Checking network connectivity..."
    
    if curl -sI --connect-timeout 5 https://github.com >/dev/null 2>&1; then
        log SUCCESS "Network connectivity OK"
        return 0
    else
        log ERROR "Cannot connect to GitHub"
        return 1
    fi
}

update_repository() {
    log INFO "Updating repository..."
    
    cd "${DXSBASH_DIR}" || {
        log ERROR "Cannot access dxsbash directory"
        return 1
    }
    
    # Stash any local changes
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        log INFO "Stashing local changes..."
        git stash push -m "dxsbash-updater-$(date +%Y%m%d-%H%M%S)" >/dev/null 2>&1
    fi
    
    # Fetch and pull updates
    if git fetch origin >/dev/null 2>&1 && git pull origin main >/dev/null 2>&1; then
        log SUCCESS "Repository updated successfully"
        return 0
    else
        log ERROR "Failed to update repository"
        return 1
    fi
}

update_file_link() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [[ ! -f "${source}" ]]; then
        log WARN "Source file not found: ${source}"
        return 1
    fi
    
    # Remove existing link/file
    if [[ -L "${target}" ]] || [[ -f "${target}" ]]; then
        rm -f "${target}"
    fi
    
    # Create new link
    if ln -sf "${source}" "${target}" 2>/dev/null; then
        log SUCCESS "Updated ${description}"
        return 0
    else
        # Fallback to copy
        if cp "${source}" "${target}" 2>/dev/null; then
            log SUCCESS "Copied ${description}"
            return 0
        else
            log ERROR "Failed to update ${description}"
            return 1
        fi
    fi
}

update_shell_configs() {
    log INFO "Updating shell configurations..."
    
    case "${DETECTED_SHELL}" in
        bash)
            update_file_link "${DXSBASH_DIR}/.bashrc" "${HOME}/.bashrc" "Bash config"
            update_file_link "${DXSBASH_DIR}/.bashrc_help" "${HOME}/.bashrc_help" "Bash help"
            update_file_link "${DXSBASH_DIR}/.bash_aliases" "${HOME}/.bash_aliases" "Bash aliases"
            ;;
        zsh)
            update_file_link "${DXSBASH_DIR}/.zshrc" "${HOME}/.zshrc" "Zsh config"
            update_file_link "${DXSBASH_DIR}/.zshrc_help" "${HOME}/.zshrc_help" "Zsh help"
            ;;
        fish)
            mkdir -p "${HOME}/.config/fish"
            update_file_link "${DXSBASH_DIR}/config.fish" "${HOME}/.config/fish/config.fish" "Fish config"
            update_file_link "${DXSBASH_DIR}/fish_help" "${HOME}/.config/fish/fish_help" "Fish help"
            ;;
    esac
    
    # Update common configs
    update_file_link "${DXSBASH_DIR}/starship.toml" "${HOME}/.config/starship.toml" "Starship config"
    
    mkdir -p "${HOME}/.config/fastfetch"
    update_file_link "${DXSBASH_DIR}/config.jsonc" "${HOME}/.config/fastfetch/config.jsonc" "Fastfetch config"
}

update_system_scripts() {
    log INFO "Updating system scripts..."
    
    local scripts=(
        "updater.sh"
        "reset-bash-profile.sh"
        "reset-zsh-profile.sh"
        "reset-fish-profile.sh"
        "clean.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "${DXSBASH_DIR}/${script}" ]]; then
            chmod +x "${DXSBASH_DIR}/${script}"
            log SUCCESS "Updated ${script}"
        fi
    done
    
    # Update system-wide command if possible
    if [[ -n "${SUDO_CMD}" ]]; then
        ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/updater.sh" /usr/local/bin/update-dxsbash 2>/dev/null || {
            log WARN "Could not update system-wide command"
        }
    fi
}

#=================================================================
# Main Update Process
#=================================================================
perform_update() {
    local current_version
    local remote_version
    local backup_path
    
    current_version=$(get_current_version)
    remote_version=$(get_remote_version)
    
    log INFO "Current version: ${current_version}"
    log INFO "Remote version: ${remote_version}"
    
    if [[ "${remote_version}" == "unknown" ]]; then
        log WARN "Could not determine remote version, proceeding with update anyway"
    elif version_compare "${remote_version}" "${current_version}"; then
        log INFO "Update available: ${current_version} -> ${remote_version}"
    else
        log INFO "Already up to date"
        echo -e "${GREEN}DXSBash is already up to date (version ${current_version})${RC}"
        return 0
    fi
    
    # Create backup
    backup_path=$(create_backup)
    if [[ -z "${backup_path}" ]]; then
        log ERROR "Failed to create backup, aborting update"
        return 1
    fi
    
    # Update repository
    if ! update_repository; then
        log ERROR "Repository update failed, restoring backup"
        restore_backup "${backup_path}"
        return 1
    fi
    
    # Update configurations
    update_shell_configs
    update_system_scripts
    
    # Clean up old backups
    cleanup_old_backups
    
    # Show summary
    local new_version
    new_version=$(get_current_version)
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${GREEN}║           DXSBash Update Completed Successfully        ║${RC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
    echo -e "  ${CYAN}Previous version:${RC} ${current_version}"
    echo -e "  ${CYAN}New version:${RC} ${new_version}"
    echo -e "  ${CYAN}Backup location:${RC} ${backup_path}"
    echo ""
    echo -e "  ${YELLOW}Please restart your terminal or run:${RC}"
    echo -e "  ${WHITE}source ~/.${DETECTED_SHELL}rc${RC}"
    echo ""
    
    return 0
}

#=================================================================
# Main Entry Point
#=================================================================
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║              DXSBash Updater 2025                      ║${RC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
    
    # Setup environment
    setup_logging
    SUDO_CMD=$(get_sudo_command)
    detect_current_shell
    
    # Check prerequisites
    if ! check_prerequisites; then
        echo -e "${RED}Missing required dependencies. Please install git and curl.${RC}"
        exit 1
    fi
    
    # Check network
    if ! check_network; then
        echo -e "${RED}Network connectivity check failed. Please check your internet connection.${RC}"
        exit 1
    fi
    
    # Check if dxsbash is installed
    if [[ ! -d "${DXSBASH_DIR}" ]]; then
        echo -e "${RED}DXSBash not found at ${DXSBASH_DIR}${RC}"
        echo -e "${YELLOW}Please run the installer first.${RC}"
        exit 1
    fi
    
    # Perform update
    if perform_update; then
        log SUCCESS "Update completed successfully"
        exit 0
    else
        log ERROR "Update failed with ${ERRORS} errors"
        echo -e "${RED}Update failed. Check ${LOG_FILE} for details.${RC}"
        exit 1
    fi
}

# Run main function
main "$@"