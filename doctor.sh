#!/bin/bash
#=================================================================
# DXSBash Doctor — Health check for an installed DXSBash environment.
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Reports the state of every piece setup.sh is supposed to wire up:
# repo checkout, shell rc symlinks, starship/fastfetch configs,
# helper binaries under /usr/local/bin, Konsole/Yakuake profile and
# default-profile pointer, FiraCode Nerd Font, and core deps.
#
# Exit status:
#   0  no FAIL checks (WARN allowed)
#   1  at least one FAIL
#   2  bad usage
#
# Usage:
#   doctor.sh                  run all checks
#   doctor.sh -v | --verbose   include PASS details
#   doctor.sh --no-color       disable ANSI colours
#   doctor.sh -h | --help      show help
#=================================================================

set -u

VERBOSE=0
USE_COLOR=1

while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=1 ;;
        --no-color)   USE_COLOR=0 ;;
        -h|--help)
            sed -n '2,23p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
    shift
done

if [ "$USE_COLOR" -eq 1 ] && [ -t 1 ]; then
    RC='\033[0m'
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[1;32m'
    BLUE='\033[1;34m'
    CYAN='\033[1;36m'
    WHITE='\033[1;37m'
    DIM='\033[2m'
else
    RC='' RED='' YELLOW='' GREEN='' BLUE='' CYAN='' WHITE='' DIM=''
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    if [ "$VERBOSE" -eq 1 ]; then
        printf "  ${GREEN}[PASS]${RC} %s\n" "$1"
        [ $# -ge 2 ] && printf "         ${DIM}%s${RC}\n" "$2"
    fi
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    printf "  ${YELLOW}[WARN]${RC} %s\n" "$1"
    [ $# -ge 2 ] && printf "         ${DIM}%s${RC}\n" "$2"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "  ${RED}[FAIL]${RC} %s\n" "$1"
    [ $# -ge 2 ] && printf "         ${DIM}%s${RC}\n" "$2"
}

section() {
    printf "\n${CYAN}▶ %s${RC}\n" "$1"
}

#=================================================================
# Detect the installed shell by inspecting which dxsbash rc-symlink
# actually points at the repo — mirrors setup.sh's is_installed
# logic so the doctor works even when run under a different login
# shell than the one that was configured.
#=================================================================
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
DXSBASH_DIR="$LINUXTOOLBOXDIR/dxsbash"

detect_installed_shell() {
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
    echo ""
}

INSTALLED_SHELL="$(detect_installed_shell)"

printf "${BLUE}╔════════════════════════════════════════════════════════╗${RC}\n"
printf "${BLUE}║  ${WHITE}DXSBash Doctor — installation health check${BLUE}            ║${RC}\n"
printf "${BLUE}╚════════════════════════════════════════════════════════╝${RC}\n"
printf "  ${CYAN}User:${RC}    %s\n" "${USER:-$(id -un)}"
printf "  ${CYAN}Home:${RC}    %s\n" "$HOME"
if [ -n "$INSTALLED_SHELL" ]; then
    printf "  ${CYAN}Shell:${RC}   %s (detected from symlinks)\n" "$INSTALLED_SHELL"
else
    printf "  ${CYAN}Shell:${RC}   ${YELLOW}unknown${RC}\n"
fi

#=================================================================
# 1. Repository checkout
#=================================================================
section "Repository"

if [ -d "$DXSBASH_DIR" ]; then
    pass "Repo directory present" "$DXSBASH_DIR"
    if [ -d "$DXSBASH_DIR/.git" ]; then
        pass "Repo is a git checkout"
        if git -C "$DXSBASH_DIR" rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
            branch="$(git -C "$DXSBASH_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)"
            if git -C "$DXSBASH_DIR" diff --quiet 2>/dev/null && \
               git -C "$DXSBASH_DIR" diff --cached --quiet 2>/dev/null; then
                pass "Working tree clean" "branch: $branch"
            else
                warn "Local modifications in repo" "branch: $branch — run 'git -C $DXSBASH_DIR status'"
            fi
        fi
    else
        warn "Repo dir is not a git checkout" "update-dxsbash will not work"
    fi
else
    fail "Repo directory missing" "expected $DXSBASH_DIR — run setup.sh --install"
fi

#=================================================================
# 2. Shell configuration symlinks
#=================================================================
section "Shell configuration"

check_symlink() {
    local path="$1" label="$2"
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        fail "$label missing" "$path"
        return
    fi
    if [ -L "$path" ]; then
        local target
        target="$(readlink "$path")"
        if printf '%s' "$target" | grep -q dxsbash; then
            pass "$label linked to repo" "$path → $target"
        else
            warn "$label is a symlink but not to dxsbash" "$path → $target"
        fi
    else
        warn "$label exists but is not a symlink" "$path (setup.sh normally symlinks this)"
    fi
}

case "$INSTALLED_SHELL" in
    bash)
        check_symlink "$HOME/.bashrc"       ".bashrc"
        check_symlink "$HOME/.bashrc_help"  ".bashrc_help"
        check_symlink "$HOME/.bash_aliases" ".bash_aliases"
        ;;
    zsh)
        check_symlink "$HOME/.zshrc"      ".zshrc"
        check_symlink "$HOME/.zshrc_help" ".zshrc_help"
        if [ -d "$HOME/.oh-my-zsh" ]; then
            pass "Oh My Zsh present" "$HOME/.oh-my-zsh"
        else
            warn "Oh My Zsh not installed" "expected at $HOME/.oh-my-zsh"
        fi
        ;;
    fish)
        check_symlink "$HOME/.config/fish/config.fish" "config.fish"
        check_symlink "$HOME/.config/fish/fish_help"   "fish_help"
        if command -v fish >/dev/null 2>&1; then
            if fish -c "type -q fisher" 2>/dev/null; then
                pass "Fisher plugin manager installed"
            else
                warn "Fisher plugin manager missing" "run: fish -c 'fisher install jorgebucaran/fisher'"
            fi
        fi
        ;;
    *)
        fail "No DXSBash shell rc symlink detected" \
             "none of ~/.bashrc, ~/.zshrc, ~/.config/fish/config.fish point at dxsbash"
        ;;
esac

# User's login shell in /etc/passwd — informational
LOGIN_SHELL="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7)"
if [ -n "$INSTALLED_SHELL" ] && [ -n "$LOGIN_SHELL" ]; then
    case "$LOGIN_SHELL" in
        */"$INSTALLED_SHELL")
            pass "Login shell matches installed shell" "$LOGIN_SHELL"
            ;;
        *)
            warn "Login shell does not match installed shell" \
                 "login=$LOGIN_SHELL installed=$INSTALLED_SHELL — run: chsh -s \$(command -v $INSTALLED_SHELL)"
            ;;
    esac
fi

#=================================================================
# 3. Starship + Fastfetch configs
#=================================================================
section "Prompt and fetch configs"

check_symlink "$HOME/.config/starship.toml"          "starship.toml"
check_symlink "$HOME/.config/fastfetch/config.jsonc" "fastfetch config.jsonc"

for bin in starship fastfetch; do
    if command -v "$bin" >/dev/null 2>&1; then
        pass "$bin binary present" "$(command -v "$bin")"
    else
        warn "$bin not on PATH" "prompt/fetch features will degrade"
    fi
done

#=================================================================
# 4. Helper commands in /usr/local/bin
#=================================================================
section "Helper commands"

for cmd in update-dxsbash dxsbash-config dxsbash-repair dxsbash-uninstall \
           dxsbash-doctor reset-shell-profile; do
    path="/usr/local/bin/$cmd"
    if [ -x "$path" ] || [ -L "$path" ]; then
        if [ -L "$path" ] && [ ! -e "$path" ]; then
            fail "$cmd symlink is broken" "$path → $(readlink "$path")"
        else
            pass "$cmd installed" "$path"
        fi
    else
        fail "$cmd missing" "$path — run setup.sh --repair"
    fi
done

#=================================================================
# 5. Konsole profile (only if konsole is present)
#=================================================================
if command -v konsole >/dev/null 2>&1; then
    section "Konsole"

    PROFILE_PATH="$HOME/.local/share/konsole/DXSBash.profile"
    if [ -f "$PROFILE_PATH" ]; then
        pass "DXSBash.profile present" "$PROFILE_PATH"

        CMD_LINE="$(grep '^Command=' "$PROFILE_PATH" 2>/dev/null | head -n1)"
        if [ -z "$CMD_LINE" ]; then
            fail "Profile has no Command= line" \
                 "Konsole will launch the system default shell (usually /usr/bin/bash)"
        else
            CMD_VAL="${CMD_LINE#Command=}"
            if [ -n "$INSTALLED_SHELL" ]; then
                case "$CMD_VAL" in
                    */"$INSTALLED_SHELL")
                        pass "Profile Command= matches installed shell" "$CMD_VAL"
                        ;;
                    *)
                        fail "Profile Command= does not match installed shell" \
                             "profile=$CMD_VAL installed=$INSTALLED_SHELL — run setup.sh --repair"
                        ;;
                esac
            fi
            if [ ! -x "$CMD_VAL" ] && ! command -v "$CMD_VAL" >/dev/null 2>&1; then
                warn "Profile Command= is not executable" "$CMD_VAL"
            fi
        fi
    else
        fail "DXSBash.profile missing" "$PROFILE_PATH"
    fi

    KONSOLERC="$HOME/.config/konsolerc"
    if [ -f "$KONSOLERC" ]; then
        DEFAULT_LINE="$(grep '^DefaultProfile=' "$KONSOLERC" 2>/dev/null | head -n1)"
        if [ "$DEFAULT_LINE" = "DefaultProfile=DXSBash.profile" ]; then
            # Confirm it's actually under [Desktop Entry]
            if awk '
                /^\[.*\]/ { section=$0 }
                /^DefaultProfile=DXSBash\.profile[[:space:]]*$/ {
                    if (section == "[Desktop Entry]") { found=1; exit }
                }
                END { exit(found ? 0 : 1) }
            ' "$KONSOLERC"; then
                pass "DefaultProfile set under [Desktop Entry]"
            else
                fail "DefaultProfile is set but not under [Desktop Entry]" \
                     "Konsole will ignore it — run setup.sh --repair"
            fi
        elif [ -n "$DEFAULT_LINE" ]; then
            warn "DefaultProfile points elsewhere" "$DEFAULT_LINE"
        else
            fail "konsolerc has no DefaultProfile=" "$KONSOLERC"
        fi
    else
        warn "konsolerc not created yet" \
             "$KONSOLERC — open Konsole once, or run setup.sh --repair"
    fi
fi

#=================================================================
# 6. Yakuake profile (only if yakuake is present)
#=================================================================
if command -v yakuake >/dev/null 2>&1; then
    section "Yakuake"

    YAKUAKERC="$HOME/.config/yakuakerc"
    if [ -f "$YAKUAKERC" ]; then
        DEFAULT_LINE="$(grep '^DefaultProfile=' "$YAKUAKERC" 2>/dev/null | head -n1)"
        if [ "$DEFAULT_LINE" = "DefaultProfile=DXSBash.profile" ]; then
            if awk '
                /^\[.*\]/ { section=$0 }
                /^DefaultProfile=DXSBash\.profile[[:space:]]*$/ {
                    if (section == "[Desktop Entry]") { found=1; exit }
                }
                END { exit(found ? 0 : 1) }
            ' "$YAKUAKERC"; then
                pass "DefaultProfile set under [Desktop Entry]"
            else
                fail "DefaultProfile is set but not under [Desktop Entry]" \
                     "Yakuake will ignore it — run setup.sh --repair"
            fi
        elif [ -n "$DEFAULT_LINE" ]; then
            warn "DefaultProfile points elsewhere" "$DEFAULT_LINE"
        else
            fail "yakuakerc has no DefaultProfile=" "$YAKUAKERC"
        fi
    else
        warn "yakuakerc not created yet" \
             "$YAKUAKERC — start Yakuake once, or run setup.sh --repair"
    fi
fi

#=================================================================
# 7. FiraCode Nerd Font
#=================================================================
section "Fonts"

if command -v fc-list >/dev/null 2>&1; then
    if fc-list 2>/dev/null | grep -qi "FiraCode"; then
        pass "FiraCode Nerd Font installed"
    else
        warn "FiraCode Nerd Font not found" "glyphs in the prompt may render as boxes"
    fi
else
    warn "fc-list not available" "cannot verify fonts"
fi

#=================================================================
# 8. Core dependencies
#=================================================================
section "Core dependencies"

for dep in git curl wget tree bat fzf zoxide ripgrep fastfetch; do
    if command -v "$dep" >/dev/null 2>&1; then
        pass "$dep" "$(command -v "$dep")"
    else
        warn "$dep not found" "run setup.sh --repair --deps to reinstall"
    fi
done

#=================================================================
# Summary
#=================================================================
printf "\n${BLUE}╔════════════════════════════════════════════════════════╗${RC}\n"
printf "${BLUE}║  ${WHITE}Summary${BLUE}                                               ║${RC}\n"
printf "${BLUE}╚════════════════════════════════════════════════════════╝${RC}\n"
printf "  ${GREEN}pass:${RC} %d   ${YELLOW}warn:${RC} %d   ${RED}fail:${RC} %d\n" \
    "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\n  ${RED}✗ DXSBash has problems.${RC} Try: ${WHITE}setup.sh --repair${RC} or ${WHITE}dxsbash-repair${RC}\n"
    exit 1
fi
if [ "$WARN_COUNT" -gt 0 ]; then
    printf "\n  ${YELLOW}⚠ DXSBash is usable but some items need attention.${RC}\n"
fi
printf "\n  ${GREEN}✓ DXSBash looks healthy.${RC}\n"
exit 0
