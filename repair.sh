#!/bin/bash
#=================================================================
# DXSBash Repair
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Re-creates broken symlinks, missing helper binaries, and verifies
# dependencies without touching the user's shell history or
# ~/.dxsbash/user.conf. Use after an interrupted install or when a
# command like update-dxsbash stops working.
#
# Usage:
#   ./repair.sh                 interactive shell detection
#   ./repair.sh --shell bash    force target shell
#   ./repair.sh --dry-run       preview actions only
#   ./repair.sh --deps          also re-run dependency installation
#=================================================================

set -u

RC='\033[0m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

DRY_RUN=0
REINSTALL_DEPS=0
FORCED_SHELL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)   DRY_RUN=1 ;;
        --deps)      REINSTALL_DEPS=1 ;;
        --shell)     shift; FORCED_SHELL="$1" ;;
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

if [ ! -d "$DXSBASH_DIR" ]; then
    echo -e "${RED}DXSBash is not installed at $DXSBASH_DIR${RC}"
    echo -e "${YELLOW}Run setup.sh --install first.${RC}"
    exit 1
fi

SUDO_CMD=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
fi

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "  ${YELLOW}[dry-run]${RC} $*"
    else
        eval "$@"
    fi
}

relink() {
    local src="$1" dst="$2" label="$3"
    if [ ! -e "$src" ]; then
        echo -e "  ${RED}missing${RC}    $label ($src)"
        return 1
    fi

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && [ -e "$dst" ]; then
        echo -e "  ${GREEN}ok${RC}         $label"
        return 0
    fi

    run "mkdir -p \"$(dirname \"$dst\")\""
    if [ -L "$dst" ] || [ -e "$dst" ]; then
        run "rm -f \"$dst\""
    fi
    if run "ln -sf \"$src\" \"$dst\""; then
        echo -e "  ${GREEN}relinked${RC}   $label"
    else
        echo -e "  ${RED}failed${RC}     $label"
    fi
}

relink_system() {
    local src="$1" dst="$2" label="$3"
    if [ ! -e "$src" ]; then
        echo -e "  ${RED}missing${RC}    $label ($src)"
        return 1
    fi
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && [ -e "$dst" ]; then
        echo -e "  ${GREEN}ok${RC}         $label"
        return 0
    fi
    if [ -z "$SUDO_CMD" ] && [ "$(id -u)" -ne 0 ]; then
        echo -e "  ${YELLOW}skip${RC}       $label (needs root)"
        return 0
    fi
    run "$SUDO_CMD ln -sf \"$src\" \"$dst\""
    echo -e "  ${GREEN}relinked${RC}   $label"
}

#=================================================================
# Detect which shell dxsbash is meant to manage
#=================================================================
detect_shell() {
    if [ -n "$FORCED_SHELL" ]; then
        echo "$FORCED_SHELL"
        return
    fi
    if [ -L "$HOME/.bashrc" ] && readlink "$HOME/.bashrc" | grep -q dxsbash; then
        echo "bash"; return
    fi
    if [ -L "$HOME/.zshrc" ] && readlink "$HOME/.zshrc" | grep -q dxsbash; then
        echo "zsh"; return
    fi
    if [ -L "$HOME/.config/fish/config.fish" ] && \
       readlink "$HOME/.config/fish/config.fish" | grep -q dxsbash; then
        echo "fish"; return
    fi
    basename "${SHELL:-bash}"
}

SHELL_TARGET=$(detect_shell)

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
echo -e "${BLUE}║  ${WHITE}DXSBash Repair${BLUE}                                        ║${RC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
[ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}  DRY-RUN mode: no files will be changed${RC}"
echo -e "  ${CYAN}Repo:${RC}  $DXSBASH_DIR"
echo -e "  ${CYAN}Shell:${RC} $SHELL_TARGET"
echo ""

#=================================================================
# 1. Shell config links
#=================================================================
echo -e "${CYAN}▶ Checking shell configuration links...${RC}"
case "$SHELL_TARGET" in
    bash)
        relink "$DXSBASH_DIR/.bashrc"        "$HOME/.bashrc"        "bashrc"
        relink "$DXSBASH_DIR/.bashrc_help"   "$HOME/.bashrc_help"   "bashrc_help"
        relink "$DXSBASH_DIR/.bash_aliases"  "$HOME/.bash_aliases"  "bash_aliases"
        ;;
    zsh)
        relink "$DXSBASH_DIR/.zshrc"         "$HOME/.zshrc"         "zshrc"
        relink "$DXSBASH_DIR/.zshrc_help"    "$HOME/.zshrc_help"    "zshrc_help"
        ;;
    fish)
        relink "$DXSBASH_DIR/config.fish"    "$HOME/.config/fish/config.fish" "config.fish"
        relink "$DXSBASH_DIR/fish_help"      "$HOME/.config/fish/fish_help"   "fish_help"
        ;;
    *)
        echo -e "  ${RED}unsupported shell: $SHELL_TARGET${RC}"
        ;;
esac

relink "$DXSBASH_DIR/starship.toml" "$HOME/.config/starship.toml"              "starship.toml"
relink "$DXSBASH_DIR/config.jsonc"  "$HOME/.config/fastfetch/config.jsonc"     "fastfetch config"
echo ""

#=================================================================
# 2. Repo file permissions
#=================================================================
echo -e "${CYAN}▶ Fixing script permissions...${RC}"
for s in setup.sh updater.sh dxsbash-config.sh uninstall.sh repair.sh clean.sh \
         reset-bash-profile.sh reset-zsh-profile.sh reset-fish-profile.sh \
         check_dependencies.sh dxsbash-utils.sh; do
    if [ -f "$DXSBASH_DIR/$s" ]; then
        run "chmod +x \"$DXSBASH_DIR/$s\""
    fi
done
echo -e "${GREEN}  ✓ Scripts marked executable${RC}"
echo ""

#=================================================================
# 3. System-wide commands
#=================================================================
echo -e "${CYAN}▶ Checking system-wide commands...${RC}"
relink_system "$DXSBASH_DIR/updater.sh"          /usr/local/bin/update-dxsbash     "update-dxsbash"
relink_system "$DXSBASH_DIR/dxsbash-config.sh"   /usr/local/bin/dxsbash-config     "dxsbash-config"

case "$SHELL_TARGET" in
    bash) RESET_SRC="$DXSBASH_DIR/reset-bash-profile.sh" ;;
    zsh)  RESET_SRC="$DXSBASH_DIR/reset-zsh-profile.sh"  ;;
    fish) RESET_SRC="$DXSBASH_DIR/reset-fish-profile.sh" ;;
    *)    RESET_SRC="$DXSBASH_DIR/reset-bash-profile.sh" ;;
esac
[ -f "$RESET_SRC" ] || RESET_SRC="$DXSBASH_DIR/reset-bash-profile.sh"
relink_system "$RESET_SRC" /usr/local/bin/reset-shell-profile "reset-shell-profile"
echo ""

#=================================================================
# 4. Runtime directories
#=================================================================
echo -e "${CYAN}▶ Ensuring runtime directories exist...${RC}"
run "mkdir -p \"$HOME/.dxsbash/logs\""
run "touch \"$HOME/.dxsbash/logs/dxsbash.log\""
echo -e "${GREEN}  ✓ ~/.dxsbash/logs present${RC}"
echo ""

#=================================================================
# 5. Dependency verification
#=================================================================
echo -e "${CYAN}▶ Verifying dependencies...${RC}"
MISSING=""
for cmd in git curl wget unzip fzf zoxide fastfetch starship bat tree; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

case "$SHELL_TARGET" in
    bash) command -v bash >/dev/null 2>&1 || MISSING="$MISSING bash" ;;
    zsh)  command -v zsh  >/dev/null 2>&1 || MISSING="$MISSING zsh"  ;;
    fish) command -v fish >/dev/null 2>&1 || MISSING="$MISSING fish" ;;
esac

if [ -z "$MISSING" ]; then
    echo -e "${GREEN}  ✓ All expected commands found${RC}"
else
    echo -e "${YELLOW}  Missing:${WHITE}$MISSING${RC}"
    if [ "$REINSTALL_DEPS" -eq 1 ] || \
       { [ "$DRY_RUN" -eq 0 ] && [ -t 0 ] && \
         read -r -p "  Run setup.sh to reinstall dependencies now? (y/N): " r && \
         [[ "$r" =~ ^[Yy]$ ]]; }
    then
        if [ -x "$DXSBASH_DIR/setup.sh" ]; then
            echo -e "${CYAN}  Re-running installer...${RC}"
            run "DXSBASH_SHELL=$SHELL_TARGET \"$DXSBASH_DIR/setup.sh\" --install --yes"
        fi
    else
        echo -e "${YELLOW}  Re-run with --deps or: sudo apt install$MISSING${RC}"
    fi
fi
echo ""

#=================================================================
# Done
#=================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${RC}"
echo -e "${GREEN}║                  Repair finished                        ║${RC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${RC}"
echo -e "  ${YELLOW}Open a new shell or run: source ~/.${SHELL_TARGET}rc${RC}"
echo ""
