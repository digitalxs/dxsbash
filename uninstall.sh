#!/bin/bash
#=================================================================
# DXSBash Uninstaller
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Fully removes DXSBash and restores the Debian 13 (/etc/skel)
# defaults for bash, zsh and fish profiles.
#
# Usage:
#   ./uninstall.sh                 interactive
#   ./uninstall.sh --yes           non-interactive, assume yes
#   ./uninstall.sh --dry-run       show what would be done
#   ./uninstall.sh --keep-repo     do not delete ~/linuxtoolbox/dxsbash
#   ./uninstall.sh --no-restore    skip /etc/skel restoration
#=================================================================

set -u

RC='\033[0m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

ASSUME_YES=0
DRY_RUN=0
KEEP_REPO=0
RESTORE_SKEL=1

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)        ASSUME_YES=1 ;;
        --dry-run)       DRY_RUN=1 ;;
        --keep-repo)     KEEP_REPO=1 ;;
        --no-restore)    RESTORE_SKEL=0 ;;
        -h|--help)
            sed -n '2,18p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
    shift
done

LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"
STAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/dxsbash_uninstall_backup_$STAMP"

SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    fi
fi

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "  ${YELLOW}[dry-run]${RC} $*"
    else
        eval "$@"
    fi
}

confirm() {
    local prompt="$1"
    if [ "$ASSUME_YES" -eq 1 ]; then
        return 0
    fi
    read -r -p "  $prompt (y/N): " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

banner() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║  ${WHITE}DXSBash Uninstaller${BLUE}                                   ║${RC}"
    echo -e "${BLUE}║  ${CYAN}Restores Debian 13 /etc/skel defaults${BLUE}                  ║${RC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${YELLOW}  DRY-RUN mode: no files will be changed${RC}"
        echo ""
    fi
}

#=================================================================
# Backup a file or directory into BACKUP_DIR preserving relative
# path under $HOME.
#=================================================================
backup_path() {
    local src="$1"
    [ -e "$src" ] || [ -L "$src" ] || return 0

    local rel="${src#$HOME/}"
    local dest="$BACKUP_DIR/$rel"

    run "mkdir -p \"$(dirname \"$dest\")\""
    # Copy, following symlinks so we preserve the *contents* the user had
    run "cp -a --dereference \"$src\" \"$dest\" 2>/dev/null || cp -a \"$src\" \"$dest\""
}

#=================================================================
# Remove a path if it is a symlink or regular file/dir we own
#=================================================================
remove_path() {
    local path="$1"
    if [ -L "$path" ]; then
        echo -e "  ${YELLOW}rm symlink${RC} $path"
        run "rm -f \"$path\""
    elif [ -f "$path" ]; then
        echo -e "  ${YELLOW}rm file${RC}    $path"
        run "rm -f \"$path\""
    elif [ -d "$path" ]; then
        echo -e "  ${YELLOW}rm dir${RC}     $path"
        run "rm -rf \"$path\""
    fi
}

#=================================================================
# Remove a path that requires root
#=================================================================
remove_root_path() {
    local path="$1"
    if [ -L "$path" ] || [ -e "$path" ]; then
        if [ -z "$SUDO_CMD" ] && [ "$(id -u)" -ne 0 ]; then
            echo -e "  ${RED}skip (needs root)${RC} $path"
            return 0
        fi
        echo -e "  ${YELLOW}rm (root)${RC}  $path"
        run "$SUDO_CMD rm -f \"$path\""
    fi
}

#=================================================================
# Confirm before proceeding
#=================================================================
banner

echo -e "${CYAN}This will:${RC}"
echo -e "  • Back up your current shell configs to ${WHITE}$BACKUP_DIR${RC}"
echo -e "  • Remove DXSBash symlinks, helper files and commands"
[ "$RESTORE_SKEL" -eq 1 ] && \
echo -e "  • Restore default files from ${WHITE}/etc/skel/${RC} (Debian defaults)"
[ "$KEEP_REPO" -eq 0 ] && \
echo -e "  • Delete ${WHITE}$DXSBASH_DIR${RC}"
echo ""

if ! confirm "Continue?"; then
    echo -e "${YELLOW}Aborted.${RC}"
    exit 0
fi
echo ""

#=================================================================
# 1. Backup
#=================================================================
echo -e "${CYAN}▶ Backing up current configuration...${RC}"
run "mkdir -p \"$BACKUP_DIR\""

for f in \
    "$HOME/.bashrc" \
    "$HOME/.bashrc_help" \
    "$HOME/.bash_aliases" \
    "$HOME/.bash_logout" \
    "$HOME/.profile" \
    "$HOME/.zshrc" \
    "$HOME/.zshrc_help" \
    "$HOME/.zsh_plugins" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.config/fish/fish_help" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/fastfetch/config.jsonc" \
    "$HOME/.local/share/konsole/DXSBash.profile" \
    "$HOME/.dxsbash"
do
    backup_path "$f"
done
echo -e "${GREEN}  ✓ Backup written to $BACKUP_DIR${RC}"
echo ""

#=================================================================
# 2. Remove user-level symlinks and config
#=================================================================
echo -e "${CYAN}▶ Removing DXSBash configuration files...${RC}"

# Shell rc files — only remove if they are dxsbash symlinks or dxsbash-owned
for rc in \
    "$HOME/.bashrc" \
    "$HOME/.bashrc_help" \
    "$HOME/.bash_aliases" \
    "$HOME/.zshrc" \
    "$HOME/.zshrc_help" \
    "$HOME/.zsh_plugins" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.config/fish/fish_help"
do
    if [ -L "$rc" ] && readlink "$rc" | grep -q "dxsbash"; then
        remove_path "$rc"
    elif [ -L "$rc" ]; then
        # Orphan symlink to nowhere — clean anyway
        if [ ! -e "$rc" ]; then
            remove_path "$rc"
        fi
    fi
done

# These are always ours
remove_path "$HOME/.config/starship.toml"
remove_path "$HOME/.config/fastfetch/config.jsonc"
# Only remove fastfetch dir if empty
if [ -d "$HOME/.config/fastfetch" ] && [ -z "$(ls -A "$HOME/.config/fastfetch" 2>/dev/null)" ]; then
    remove_path "$HOME/.config/fastfetch"
fi

remove_path "$HOME/.local/share/konsole/DXSBash.profile"
remove_path "$HOME/update-dxsbash.sh"
remove_path "$HOME/.dxsbash"

# Clean Konsole / Yakuake references
for rcfile in "$HOME/.config/konsolerc" "$HOME/.config/yakuakerc"; do
    if [ -f "$rcfile" ] && grep -q "DefaultProfile=DXSBash.profile" "$rcfile"; then
        echo -e "  ${YELLOW}clean${RC}      $rcfile"
        run "sed -i '/DefaultProfile=DXSBash.profile/d' \"$rcfile\""
    fi
done
echo -e "${GREEN}  ✓ User-level files removed${RC}"
echo ""

#=================================================================
# 3. Remove system-wide symlinks (require root)
#=================================================================
echo -e "${CYAN}▶ Removing system-wide commands...${RC}"
for bin in \
    /usr/local/bin/update-dxsbash \
    /usr/local/bin/upbashdxs \
    /usr/local/bin/dxsbash-config \
    /usr/local/bin/reset-shell-profile \
    /usr/local/bin/reset-bash-profile \
    /usr/local/bin/reset-zsh-profile \
    /usr/local/bin/reset-fish-profile
do
    remove_root_path "$bin"
done
echo -e "${GREEN}  ✓ System commands removed${RC}"
echo ""

#=================================================================
# 4. Restore Debian /etc/skel defaults
#=================================================================
if [ "$RESTORE_SKEL" -eq 1 ]; then
    echo -e "${CYAN}▶ Restoring Debian defaults from /etc/skel/...${RC}"
    if [ ! -d /etc/skel ]; then
        echo -e "${RED}  ✗ /etc/skel not found; skipping restore${RC}"
    else
        for file in .bashrc .profile .bash_logout; do
            if [ -f "/etc/skel/$file" ]; then
                echo -e "  ${GREEN}restore${RC}    $HOME/$file"
                run "cp -f \"/etc/skel/$file\" \"$HOME/$file\""
                run "chmod 644 \"$HOME/$file\""
            else
                echo -e "  ${YELLOW}skip${RC}       /etc/skel/$file not present"
            fi
        done

        # zsh defaults — /etc/skel may ship .zshrc on some Debian configs
        if [ -f /etc/skel/.zshrc ]; then
            echo -e "  ${GREEN}restore${RC}    $HOME/.zshrc"
            run "cp -f /etc/skel/.zshrc \"$HOME/.zshrc\""
            run "chmod 644 \"$HOME/.zshrc\""
        fi

        # fish — Debian does not ship a skel config; leave directory clean
        if [ -d "$HOME/.config/fish" ]; then
            if [ -z "$(ls -A "$HOME/.config/fish" 2>/dev/null)" ]; then
                remove_path "$HOME/.config/fish"
            fi
        fi
    fi
    echo -e "${GREEN}  ✓ Debian defaults restored${RC}"
    echo ""
fi

#=================================================================
# 5. Remove repository
#=================================================================
if [ "$KEEP_REPO" -eq 0 ]; then
    echo -e "${CYAN}▶ Removing DXSBash repository...${RC}"
    remove_path "$DXSBASH_DIR"
    # Drop linuxtoolbox only if empty
    if [ -d "$LINUXTOOLBOXDIR" ] && [ -z "$(ls -A "$LINUXTOOLBOXDIR" 2>/dev/null)" ]; then
        remove_path "$LINUXTOOLBOXDIR"
    fi
    echo -e "${GREEN}  ✓ Repository removed${RC}"
    echo ""
fi

#=================================================================
# 6. Offer to revert default shell to bash
#=================================================================
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
BASH_PATH=$(command -v bash || echo /bin/bash)
if [ "$CURRENT_SHELL" != "$BASH_PATH" ]; then
    echo -e "${CYAN}▶ Default shell check...${RC}"
    echo -e "  Current login shell: ${WHITE}$CURRENT_SHELL${RC}"
    if confirm "Revert login shell to $BASH_PATH?"; then
        if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
            run "$SUDO_CMD chsh -s \"$BASH_PATH\" \"$USER\""
            echo -e "${GREEN}  ✓ Login shell reverted to bash${RC}"
        else
            echo -e "${YELLOW}  Run manually: chsh -s $BASH_PATH${RC}"
        fi
    fi
    echo ""
fi

#=================================================================
# Done
#=================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${RC}"
echo -e "${GREEN}║           DXSBash uninstalled successfully             ║${RC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${RC}"
echo -e "  ${CYAN}Backup:${RC} $BACKUP_DIR"
echo -e "  ${YELLOW}Log out and back in for shell changes to take effect.${RC}"
echo ""
