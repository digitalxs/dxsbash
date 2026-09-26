#!/bin/bash
#=================================================================
# DXSBash Updater - Cross-Distribution Compatible
# Compatible with: Debian 13, Fedora 42, Arch Linux (latest)
# Version: 3.5.0
# Author: Luis Miguel P. Freitas
# License: GPL-3.0
#
# Usage:
#   update-dxsbash             perform the update
#   update-dxsbash --check     only check whether an update exists
#                              (exit 0: up to date, 10: update available,
#                               1: could not check)
#   update-dxsbash --channel stable|main   use this channel once
#   update-dxsbash --help      show help
#
# Channels (DXSBASH_UPDATE_CHANNEL in ~/.dxsbash/user.conf):
#   stable (default)  the newest release tag vX.Y.Z (pre-releases skipped)
#   main              the tip of the main branch — every change, untested
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
readonly WHITE='\033[1;37m'

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
# DXSBASH_REPO_URL: forks, mirrors and tests
REPO_URL="${DXSBASH_REPO_URL:-https://github.com/digitalxs/dxsbash.git}"
UPDATE_CHANNEL=""   # stable | main — see resolve_channel
POST_ARGS=()        # --post-update: previous version, backup path

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
            (( ++ERRORS ))
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

# Channel precedence: --channel flag, then ~/.dxsbash/user.conf (the
# live setting), then the environment, then "stable".
resolve_channel() {
    local conf="${HOME}/.dxsbash/user.conf"
    if [[ -z "${UPDATE_CHANNEL}" && -f "${conf}" ]]; then
        UPDATE_CHANNEL=$(sed -n 's/^export DXSBASH_UPDATE_CHANNEL="\{0,1\}\([a-z]*\)"\{0,1\}$/\1/p' "${conf}" | head -1)
    fi
    [[ -n "${UPDATE_CHANNEL}" ]] || UPDATE_CHANNEL="${DXSBASH_UPDATE_CHANNEL:-stable}"
    case "${UPDATE_CHANNEL}" in
        stable|main) ;;
        *) UPDATE_CHANNEL="stable" ;;
    esac
}

# Newest release tag (vX.Y.Z; -beta/-rc pre-releases skipped), or empty
latest_stable_tag() {
    { timeout 30 git ls-remote --tags --refs "${REPO_URL}" 'v*' 2>/dev/null || true; } \
        | awk '{ sub("refs/tags/", "", $2); print $2 }' \
        | { grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true; } \
        | sort -V | tail -n 1
}

get_remote_version() {
    local remote_version="" tag
    if [[ "${UPDATE_CHANNEL}" == "main" ]]; then
        # -f: an HTTP error page must not be read as a version number
        remote_version=$(curl -fsSL --max-time 20 \
            https://raw.githubusercontent.com/digitalxs/dxsbash/main/version.txt 2>/dev/null \
            | tr -d '[:space:]' || true)
    else
        tag=$(latest_stable_tag)
        remote_version="${tag#v}"
    fi

    if [[ "${remote_version}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        echo "${remote_version}"
    else
        echo "unknown"
    fi
}

# Commit the channel points at: the newest release tag (peeled to its
# commit) for stable, the tip of main for main. Empty if unreachable.
target_commit() {
    local ref tag
    if [[ "${UPDATE_CHANNEL}" == "main" ]]; then
        ref="refs/heads/main"
    else
        tag=$(latest_stable_tag)
        [[ -n "${tag}" ]] || return 0
        ref="refs/tags/${tag}^{}"
    fi
    { timeout 30 git ls-remote "${REPO_URL}" "${ref}" 2>/dev/null || true; } | awk 'NR==1 { print $1 }'
}

# Decide by commits, not version strings: an update exists when the
# channel's target commit is not already contained in the checkout.
# This never offers a downgrade (a main snapshot ahead of the newest
# tag is up to date), sees unbumped commits on main, and cannot loop
# if a tag's version.txt was not bumped. Returns 0 = update available,
# 1 = up to date, 2 = cannot tell (caller falls back to versions).
commit_update_available() {
    local target="$1"
    [[ -n "${target}" ]] || return 2
    git -C "${DXSBASH_DIR}" rev-parse --git-dir >/dev/null 2>&1 || return 2
    # In a shallow clone missing history looks like "not an ancestor"
    if [[ "$(git -C "${DXSBASH_DIR}" rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]]; then
        return 2
    fi
    if [[ "$(git -C "${DXSBASH_DIR}" rev-parse HEAD 2>/dev/null)" == "${target}" ]]; then
        return 1
    fi
    if git -C "${DXSBASH_DIR}" merge-base --is-ancestor "${target}" HEAD >/dev/null 2>&1; then
        return 1
    fi
    return 0   # not in our history (or not fetched yet): new
}

# Combined decision used by --check and the update itself.
# Prints the status line; returns 10 update / 0 up to date / 1 unknown.
update_status() {
    local current remote target rc=0
    current=$(get_current_version)
    remote=$(get_remote_version)
    target=$(target_commit)

    commit_update_available "${target}" || rc=$?
    case "${rc}" in
        0)
            if [[ "${UPDATE_CHANNEL}" == "main" ]]; then
                echo "Update available: ${current} -> ${remote} (main @ ${target:0:7})"
            else
                echo "Update available: ${current} -> ${remote} (stable channel)"
            fi
            return 10 ;;
        1)
            echo "DXSBash is up to date (version ${current}, ${UPDATE_CHANNEL} channel)."
            return 0 ;;
    esac

    # Fallback (no git history to compare): version numbers
    if [[ "${remote}" == "unknown" ]]; then
        echo "Could not determine the remote version (network problem?)."
        return 1
    fi
    local cmp=0
    version_compare "${remote}" "${current}" || cmp=$?
    if [[ ${cmp} -eq 0 || "${current}" == "unknown" ]]; then
        echo "Update available: ${current} -> ${remote} (${UPDATE_CHANNEL} channel)"
        return 10
    fi
    echo "DXSBash is up to date (version ${current}, ${UPDATE_CHANNEL} channel)."
    return 0
}

version_compare() {
    # Returns 0 if $1 > $2, 1 if $1 < $2, 2 if equal
    if [[ "$1" == "$2" ]]; then
        return 2
    fi
    
    local i seg1 seg2
    local -a ver1 ver2
    IFS=. read -r -a ver1 <<< "$1"
    IFS=. read -r -a ver2 <<< "$2"

    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        # Strip non-digits so values like "unknown" compare as 0
        # instead of raising an arithmetic error.
        seg1="${ver1[i]:-0}"; seg1="${seg1//[^0-9]/}"; seg1="${seg1:-0}"
        seg2="${ver2[i]:-0}"; seg2="${seg2//[^0-9]/}"; seg2="${seg2:-0}"
        if ((10#$seg1 > 10#$seg2)); then
            return 0
        elif ((10#$seg1 < 10#$seg2)); then
            return 1
        fi
    done

    return 2
}

#=================================================================
# Backup Functions
#=================================================================
# Prints the backup path on stdout — callers capture it with $(...),
# so console log output inside this function must go to stderr.
create_backup() {
    local backup_name
    backup_name="dxsbash-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"

    mkdir -p "${BACKUP_DIR}"

    log INFO "Creating backup at ${backup_path}" >&2

    if cp -r "${DXSBASH_DIR}" "${backup_path}" 2>/dev/null; then
        # Verify backup
        if [ -d "${backup_path}" ] && [ -f "${backup_path}/version.txt" ]; then
            log SUCCESS "Backup created and verified successfully" >&2
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

        # Collect backup dirs sorted newest-first, then remove the oldest ones
        local dirs_to_remove
        mapfile -t dirs_to_remove < <(
            find "${BACKUP_DIR}" -maxdepth 1 -name "dxsbash-backup-*" -type d -printf '%T@ %p\n' 2>/dev/null \
                | sort -rn \
                | tail -n +$((max_backups + 1)) \
                | cut -d' ' -f2-
        )
        if [[ ${#dirs_to_remove[@]} -gt 0 ]]; then
            rm -rf "${dirs_to_remove[@]}"
        fi
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
    
    if [[ "${UPDATE_CHANNEL}" == "main" ]]; then
        if git fetch origin >/dev/null 2>&1 && git pull origin main >/dev/null 2>&1; then
            log SUCCESS "Repository updated to the tip of main"
            return 0
        fi
        log ERROR "Failed to update repository"
        return 1
    fi

    # A shallow clone (older install.sh used --depth=1) cannot compute
    # the fast-forward reliably: fetch the full history once
    if [[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]]; then
        log INFO "Fetching full history (one-time, shallow clone)..."
        git fetch --unshallow origin >/dev/null 2>&1 || log WARN "Could not unshallow the clone"
    fi

    # stable: fast-forward the local main branch to the newest release tag
    local tag
    tag=$(latest_stable_tag)
    if [[ -z "${tag}" ]]; then
        log ERROR "No release tag found on ${REPO_URL}"
        return 1
    fi
    if git fetch --force origin "refs/tags/${tag}:refs/tags/${tag}" >/dev/null 2>&1 && \
       git checkout -q -B main >/dev/null 2>&1 && \
       git merge --ff-only -q "${tag}" >/dev/null 2>&1; then
        log SUCCESS "Repository updated to release ${tag}"
        return 0
    fi
    log ERROR "Could not fast-forward to ${tag} (local changes or history?). Try: update-dxsbash --channel main"
    return 1
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
    update_starship_link
    
    mkdir -p "${HOME}/.config/fastfetch"
    update_file_link "${DXSBASH_DIR}/config.jsonc" "${HOME}/.config/fastfetch/config.jsonc" "Fastfetch config"
}

# ~/.config/starship.toml is user state (the theme picked in
# dxsbash-gui / dxsbash-config, or a hand-written config). Presets are
# updated in place by the git pull, so a working link needs nothing;
# only a missing or dangling link is re-pointed at the default, and a
# regular file is never touched.
update_starship_link() {
    local link="${HOME}/.config/starship.toml"
    mkdir -p "${HOME}/.config"
    if [[ -L "${link}" && -e "${link}" ]]; then
        log INFO "Keeping your Starship theme ($(basename "$(readlink "${link}")"))"
    elif [[ -f "${link}" && ! -L "${link}" ]]; then
        log INFO "Keeping your custom starship.toml"
    else
        update_file_link "${DXSBASH_DIR}/starship.toml" "${link}" "Starship config"
    fi
}

update_system_scripts() {
    log INFO "Updating system scripts..."

    local scripts=(
        "updater.sh"
        "dxsbash.sh"
        "dxsbash-config.sh"
        "doctor.sh"
        "secaudit.sh"
        "secsummary.sh"
        "repair.sh"
        "uninstall.sh"
        "reset-bash-profile.sh"
        "reset-zsh-profile.sh"
        "reset-fish-profile.sh"
        "clean.sh"
        "dxsbash-gui.sh"
        "gui-askpass.sh"
        "export-import.sh"
        "bench.sh"
        "update-notify.sh"
    )

    for script in "${scripts[@]}"; do
        if [[ -f "${DXSBASH_DIR}/${script}" ]]; then
            chmod +x "${DXSBASH_DIR}/${script}"
            log SUCCESS "Updated ${script}"
        fi
    done

    # Update system-wide commands if possible
    if [[ -n "${SUDO_CMD}" ]]; then
        ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/updater.sh" /usr/local/bin/update-dxsbash 2>/dev/null || {
            log WARN "Could not update system-wide update-dxsbash command"
        }
        ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/dxsbash-config.sh" /usr/local/bin/dxsbash-config 2>/dev/null || {
            log WARN "Could not update system-wide dxsbash-config command"
        }
        if [[ -f "${DXSBASH_DIR}/dxsbash.sh" ]]; then
            ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/dxsbash.sh" /usr/local/bin/dxsbash 2>/dev/null || {
                log WARN "Could not update system-wide dxsbash command"
            }
        fi
        if [[ -f "${DXSBASH_DIR}/secaudit.sh" ]]; then
            ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/secaudit.sh" /usr/local/bin/dxsbash-audit 2>/dev/null || {
                log WARN "Could not update system-wide dxsbash-audit command"
            }
        fi
        if [[ -f "${DXSBASH_DIR}/dxsbash-gui.sh" ]]; then
            ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/dxsbash-gui.sh" /usr/local/bin/dxsbash-gui 2>/dev/null || {
                log WARN "Could not update system-wide dxsbash-gui command"
            }
        fi
    fi

    # Refresh the "DXSBash Settings" menu entry if the user has one, so
    # new desktop actions/icons from this release show up
    local entry="${XDG_DATA_HOME:-${HOME}/.local/share}/applications/dxsbash-settings.desktop"
    # -O: never rewrite it as another user (e.g. sudo -E update-dxsbash)
    if [[ -f "${entry}" && -O "${entry}" && -f "${DXSBASH_DIR}/dxsbash-gui.sh" ]]; then
        bash "${DXSBASH_DIR}/dxsbash-gui.sh" --install-desktop >/dev/null 2>&1 && \
            log SUCCESS "Refreshed DXSBash Settings menu entry"
    fi
}

#=================================================================
# After the pull (run by the NEW updater, see perform_update)
#=================================================================
post_update() {
    local current_version="$1" backup_path="$2" new_version

    update_shell_configs
    update_system_scripts
    ensure_desktop_integration
    cleanup_old_backups

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
    if [[ "${DETECTED_SHELL}" == "fish" ]]; then
        echo -e "  ${WHITE}source ~/.config/fish/config.fish${RC}"
    else
        echo -e "  ${WHITE}source ~/.${DETECTED_SHELL}rc${RC}"
    fi
    echo ""
    return 0
}

# Link DXSBash commands that are missing from /usr/local/bin (only the
# missing ones, so an up-to-date run does not ask for sudo needlessly),
# then the desktop integration. Covers installs updated by an updater
# that predates a command.
ensure_install_complete() {
    local pair name src want have missing=0
    for pair in dxsbash:dxsbash.sh dxsbash-gui:dxsbash-gui.sh dxsbash-config:dxsbash-config.sh \
                update-dxsbash:updater.sh dxsbash-repair:repair.sh dxsbash-doctor:doctor.sh \
                dxsbash-audit:secaudit.sh dxsbash-uninstall:uninstall.sh; do
        name="${pair%%:*}"; src="${pair#*:}"
        [[ -f "${DXSBASH_DIR}/${src}" ]] || continue
        # Missing, or stale: a copy / link into another checkout (3.1-era
        # installs linked update-dxsbash to a frozen copy in ~/linuxtoolbox)
        want="$(readlink -f "${DXSBASH_DIR}/${src}")"
        have="$(readlink -f "/usr/local/bin/${name}" 2>/dev/null || true)"
        [[ -e "/usr/local/bin/${name}" && "${have}" == "${want}" ]] && continue
        missing=1
        if [[ -n "${SUDO_CMD}" ]] && ${SUDO_CMD} ln -sf "${DXSBASH_DIR}/${src}" "/usr/local/bin/${name}" 2>/dev/null; then
            if [[ -e "/usr/local/bin/${name}" && -n "${have}" && "${have}" != "${want}" ]]; then
                log SUCCESS "Re-pointed ${name} (was ${have})"
            else
                log SUCCESS "Installed missing command ${name}"
            fi
        fi
    done
    cleanup_legacy_copies
    if [[ ${missing} -eq 1 && -z "${SUDO_CMD}" ]]; then
        log WARN "Some DXSBash commands are not linked; run dxsbash-repair with sudo rights"
    fi
    ensure_desktop_integration
}

# 3.1-era installs copied updater.sh into ~/linuxtoolbox and pointed
# ~/update-dxsbash.sh at that copy, which then never updated. Point the
# shortcut at the repo and drop the frozen copy (only a regular file).
cleanup_legacy_copies() {
    local lt="${HOME}/linuxtoolbox"
    if [[ -L "${HOME}/update-dxsbash.sh" && "$(readlink -f "${HOME}/update-dxsbash.sh")" != "$(readlink -f "${DXSBASH_DIR}/updater.sh")" ]]; then
        ln -sf "${DXSBASH_DIR}/updater.sh" "${HOME}/update-dxsbash.sh" && log SUCCESS "Re-pointed ~/update-dxsbash.sh"
    fi
    if [[ -f "${lt}/updater.sh" && ! -L "${lt}/updater.sh" && -f "${DXSBASH_DIR}/updater.sh" ]]; then
        rm -f "${lt}/updater.sh" && log SUCCESS "Removed stale updater copy ${lt}/updater.sh"
    fi
}

# Desktop users who installed before the settings GUI existed: add the
# menu entry, icon and daily update check (all per-user, no sudo), and
# say if zenity — which the GUI needs — is missing.
ensure_desktop_integration() {
    local entry="${XDG_DATA_HOME:-${HOME}/.local/share}/applications/dxsbash-settings.desktop"
    [[ -f "${DXSBASH_DIR}/dxsbash-gui.sh" ]] || return 0
    # Same rule as setup.sh (KDE/XFCE installed, other desktops, or
    # DXSBASH_DESKTOP) — in a subshell to keep the library's globals out
    bash -c 'source "$1" && wants_desktop_gui' _ "${DXSBASH_DIR}/settings-lib.sh" 2>/dev/null || return 0
    if [[ ! -f "${entry}" ]]; then
        if bash "${DXSBASH_DIR}/dxsbash-gui.sh" --install-desktop >/dev/null 2>&1; then
            log SUCCESS "Added DXSBash Settings to the application menu (System)"
        fi
    fi
    if ! command_exists zenity; then
        log WARN "The settings window needs zenity: install it with your package manager (e.g. sudo apt install zenity)"
    fi
    return 0
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
    
    log INFO "Update channel: ${UPDATE_CHANNEL}"
    log INFO "Current version: ${current_version}"
    log INFO "Remote version: ${remote_version}"
    
    local status_line status_rc=0
    status_line=$(update_status) || status_rc=$?
    log INFO "${status_line}"
    if [[ ${status_rc} -eq 0 ]]; then
        echo -e "${GREEN}${status_line}${RC}"
        # Nothing to pull — but the last update may have been done by an
        # older updater that did not know this release's new pieces
        ensure_install_complete
        return 0
    elif [[ ${status_rc} -eq 1 ]]; then
        log WARN "Could not determine the remote state, proceeding with update anyway"
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
    
    # Hand over to the freshly pulled updater for everything after the
    # pull. bash runs the script it loaded before the update, so without
    # this a release's new install steps (new commands, links, menu
    # entries) would only take effect one update later.
    if [[ -f "${DXSBASH_DIR}/updater.sh" ]] && grep -q -- '--post-update' "${DXSBASH_DIR}/updater.sh"; then
        exec bash "${DXSBASH_DIR}/updater.sh" --post-update "${current_version}" "${backup_path}"
    fi
    post_update "${current_version}" "${backup_path}"
    return 0
}

#=================================================================
# Check-only mode (for scripts, cron jobs and prompt integrations)
#=================================================================
usage() {
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
}

check_for_update() {
    local out rc=0
    out=$(update_status) || rc=$?
    if [[ ${rc} -eq 1 ]]; then
        echo "${out}" >&2
    else
        echo "${out}"
    fi
    exit "${rc}"
}

#=================================================================
# Main Entry Point
#=================================================================
main() {
    local mode="update"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)     mode="check" ;;
            --post-update)
                # internal: continue an update after the pull (see perform_update)
                mode="post"; POST_ARGS=("${2:-unknown}" "${3:-}"); shift 2 || true ;;
            --channel)   UPDATE_CHANNEL="${2:-}"; shift ;;
            --channel=*) UPDATE_CHANNEL="${1#--channel=}" ;;
            -h|--help)   usage; exit 0 ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
    if [[ -n "${UPDATE_CHANNEL}" && "${UPDATE_CHANNEL}" != "stable" && "${UPDATE_CHANNEL}" != "main" ]]; then
        echo "Unknown channel: ${UPDATE_CHANNEL} (use stable or main)" >&2
        exit 2
    fi
    resolve_channel
    [[ "${mode}" == "check" ]] && check_for_update
    if [[ "${mode}" == "post" ]]; then
        setup_logging
        SUDO_CMD=$(get_sudo_command)
        detect_current_shell
        log INFO "Continuing update with the new updater"
        post_update "${POST_ARGS[@]}"
        exit $?
    fi

    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║              DXSBash Updater $(date +%Y)                      ║${RC}"
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