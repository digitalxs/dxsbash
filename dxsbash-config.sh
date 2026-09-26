#!/bin/bash
#=================================================================
# DXSBash Interactive Configuration
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Manages user preferences stored in ~/.dxsbash/user.conf
# Settings take effect in new shell sessions (or after: source ~/.bashrc)
#=================================================================

RC='\033[0m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
DIM='\033[2m'

# Settings model (paths, theme registry, defaults, read/write) is
# shared with the graphical dxsbash-gui — see settings-lib.sh. Resolve
# it next to this script's real location (it is normally symlinked
# from /usr/local/bin), falling back to the standard install path.
_DXS_SELF_DIR="$(dirname "$(readlink -f "$0")")"
if [ -f "$_DXS_SELF_DIR/settings-lib.sh" ]; then
    DXSBASH_DIR="${DXSBASH_DIR:-$_DXS_SELF_DIR}"
fi
DXSBASH_DIR="${DXSBASH_DIR:-$HOME/linuxtoolbox/dxsbash}"
if [ ! -f "$DXSBASH_DIR/settings-lib.sh" ]; then
    echo "dxsbash-config: $DXSBASH_DIR/settings-lib.sh not found." >&2
    echo "Run dxsbash-repair or update-dxsbash to fix your installation." >&2
    exit 1
fi
# shellcheck source=settings-lib.sh
source "$DXSBASH_DIR/settings-lib.sh"

#=================================================================
# Banner
#=================================================================
display_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RC}"
    echo -e "${BLUE}║  ${WHITE}DXSBash Configuration${BLUE}                                  ║${RC}"
    echo -e "${BLUE}║  ${DIM}~/.dxsbash/user.conf${RC}${BLUE}                                  ║${RC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RC}"
    echo ""
}

#=================================================================
# Load config into CUR_* variables (see settings-lib.sh)
#=================================================================
load_config() {
    load_settings
}

#=================================================================
# Write current CUR_* values to the conf file
#=================================================================
save_config() {
    if ! write_settings "dxsbash-config"; then
        echo -e "${RED}  ✗ Not saved: a value contains \", \$, \` or a backslash.${RC}"
        sleep 2
        return 1
    fi
    echo ""
    echo -e "${GREEN}  ✓ Saved to ${WHITE}$CONF_FILE${RC}"
    echo -e "${GREEN}  ✓ Fish settings written to ${WHITE}$CONF_FISH_FILE${RC}"
    echo -e "${YELLOW}  Run ${WHITE}source ~/.bashrc${YELLOW} (or open a new terminal) to apply.${RC}"
    echo ""
}

#=================================================================
# Detect available text editors
#=================================================================
detect_editors() {
    AVAILABLE_EDITORS=()
    local candidates=(nano vim neovim nvim joe micro emacs gedit kate mousepad xed)
    for ed in "${candidates[@]}"; do
        if command -v "$ed" &>/dev/null; then
            # Normalise: prefer the canonical name users type
            AVAILABLE_EDITORS+=("$ed")
        fi
    done
}

#=================================================================
# Show a summary table of current settings
#=================================================================
show_current_settings() {
    local fastfetch_label
    [ "$CUR_FASTFETCH" = "true" ] && fastfetch_label="${GREEN}enabled${RC}" || fastfetch_label="${RED}disabled${RC}"

    local prompt_label
    if [ "$CUR_PROMPT_STYLE" = "custom" ]; then
        prompt_label="${CYAN}built-in custom${RC}"
    else
        prompt_label="${CYAN}Starship${RC}${DIM} (falls back to custom if not installed)${RC}"
    fi

    local theme_label
    theme_label="${CYAN}$(starship_theme_display_name "$CUR_STARSHIP_THEME")${RC}"

    local secsummary_label
    [ "$CUR_SECSUMMARY" = "true" ] && secsummary_label="${GREEN}enabled${RC}" || secsummary_label="${RED}disabled${RC}"

    local sshlite_label
    [ "$CUR_SSH_LITE" = "true" ] && sshlite_label="${GREEN}enabled${RC}" || sshlite_label="${RED}disabled${RC}"

    echo -e "${BLUE}┌─────────────────────────────────────────────────────────┐${RC}"
    echo -e "${BLUE}│  Current Configuration                                  │${RC}"
    echo -e "${BLUE}├──────────────────────┬──────────────────────────────────┤${RC}"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "Editor"          "${WHITE}$CUR_EDITOR${RC}"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32s${BLUE}│${RC}\n" "History size"    "$CUR_HISTSIZE entries"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32s${BLUE}│${RC}\n" "History file"    "$CUR_HISTFILESIZE entries"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "Fastfetch"       "$fastfetch_label"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "Prompt style"    "$prompt_label"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "Starship theme"  "$theme_label"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "Security summary" "$secsummary_label"
    printf "${BLUE}│${RC}  %-20s${BLUE}│${RC}  %-32b${BLUE}│${RC}\n" "SSH-lite prompt"  "$sshlite_label"
    echo -e "${BLUE}└──────────────────────┴──────────────────────────────────┘${RC}"
    echo ""
}

#=================================================================
# Starship theme helpers
#=================================================================
# Switch ~/.config/starship.toml to point at the selected preset
# (starship_theme_display_name and link_starship_theme live in
# settings-lib.sh).
apply_starship_theme() {
    if ! link_starship_theme "$1"; then
        echo -e "${RED}  ✗ Theme file not found: $STARSHIP_THEMES_DIR/$1${RC}"
        return 1
    fi
    echo -e "${GREEN}  ✓ Linked $STARSHIP_LINK → $STARSHIP_THEMES_DIR/$1${RC}"
    [ -n "$STARSHIP_BACKUP" ] && \
        echo -e "${YELLOW}  Your own starship.toml was kept as ${WHITE}$STARSHIP_BACKUP${RC}"
    return 0
}

#=================================================================
# Submenu — Editor
#=================================================================
configure_editor() {
    display_banner
    echo -e "${CYAN}▶ Text Editor${RC}"
    echo -e "  Current: ${WHITE}$CUR_EDITOR${RC}"
    echo ""

    detect_editors

    if [ ${#AVAILABLE_EDITORS[@]} -eq 0 ]; then
        echo -e "${RED}  No supported editors found on this system.${RC}"
        echo -e "${YELLOW}  Install one with: sudo apt install nano${RC}"
        echo ""
        read -rp "  Press Enter to return..."
        return
    fi

    echo -e "  Available editors on this system:"
    echo ""
    local i=1
    for ed in "${AVAILABLE_EDITORS[@]}"; do
        local marker=""
        [ "$ed" = "$CUR_EDITOR" ] && marker=" ${GREEN}← current${RC}"
        printf "  ${WHITE}%d)${RC} %s%b\n" "$i" "$ed" "$marker"
        (( i++ ))
    done
    echo ""
    echo -e "  ${WHITE}c)${RC} Enter a custom path"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        0|"") return ;;
        c|C)
            read -rp "  Enter full path to editor: " custom_ed
            if [ -z "$custom_ed" ]; then
                echo -e "${YELLOW}  No input — keeping $CUR_EDITOR${RC}"
            elif ! command -v "$custom_ed" &>/dev/null && [ ! -x "$custom_ed" ]; then
                echo -e "${RED}  '$custom_ed' not found or not executable.${RC}"
            elif ! setting_value_safe "$custom_ed"; then
                echo -e "${RED}  Paths containing \", \$, \` or a backslash are not supported.${RC}"
            else
                CUR_EDITOR="$custom_ed"
                save_config
            fi
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_EDITORS[@]}" ]; then
                CUR_EDITOR="${AVAILABLE_EDITORS[$((choice-1))]}"
                save_config
            else
                echo -e "${RED}  Invalid choice.${RC}"
                sleep 1
            fi
            ;;
    esac
}

#=================================================================
# Submenu — History
#=================================================================
configure_history() {
    display_banner
    echo -e "${CYAN}▶ Shell History${RC}"
    echo ""
    echo -e "  ${WHITE}HISTSIZE${RC}      — lines kept in memory during a session"
    echo -e "  ${WHITE}HISTFILESIZE${RC}  — lines persisted to the history file"
    echo ""
    echo -e "  Current: ${WHITE}HISTSIZE=${CUR_HISTSIZE}${RC}  ${WHITE}HISTFILESIZE=${CUR_HISTFILESIZE}${RC}"
    echo ""
    echo -e "  ${WHITE}1)${RC} Small    (500 / 5 000)"
    echo -e "  ${WHITE}2)${RC} Medium   (1 000 / 10 000)  ${DIM}← default${RC}"
    echo -e "  ${WHITE}3)${RC} Large    (5 000 / 50 000)"
    echo -e "  ${WHITE}4)${RC} Unlimited (no pruning)"
    echo -e "  ${WHITE}5)${RC} Custom values"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        1) CUR_HISTSIZE=500;     CUR_HISTFILESIZE=5000;     save_config ;;
        2) CUR_HISTSIZE=1000;    CUR_HISTFILESIZE=10000;    save_config ;;
        3) CUR_HISTSIZE=5000;    CUR_HISTFILESIZE=50000;    save_config ;;
        4) CUR_HISTSIZE=-1;      CUR_HISTFILESIZE=-1;       save_config ;;
        5)
            read -rp "  HISTSIZE (entries in memory): " hs
            read -rp "  HISTFILESIZE (entries on disk): " hf
            if [[ "$hs" =~ ^-?[0-9]+$ ]] && [[ "$hf" =~ ^-?[0-9]+$ ]]; then
                CUR_HISTSIZE="$hs"
                CUR_HISTFILESIZE="$hf"
                save_config
            else
                echo -e "${RED}  Invalid input — must be integers.${RC}"
                sleep 1
            fi
            ;;
        0|"") return ;;
        *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
    esac
}

#=================================================================
# Submenu — Prompt style
#=================================================================
configure_prompt() {
    display_banner
    echo -e "${CYAN}▶ Prompt Style${RC}"
    echo ""
    echo -e "  ${WHITE}starship${RC}  — Starship cross-shell prompt (recommended)"
    echo -e "              Falls back to built-in if Starship is not installed."
    echo ""
    echo -e "  ${WHITE}custom${RC}    — DXSBash built-in prompt"
    echo -e "              Colour-coded: username, path, git branch, exit code."
    echo ""

    local starship_status
    if command -v starship &>/dev/null; then
        starship_status="${GREEN}installed${RC}"
    else
        starship_status="${RED}not installed${RC}"
    fi
    echo -e "  Starship: $starship_status"
    echo -e "  Current:  ${WHITE}$CUR_PROMPT_STYLE${RC}"
    echo ""
    echo -e "  ${WHITE}1)${RC} Starship prompt"
    echo -e "  ${WHITE}2)${RC} Built-in custom prompt"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        1) CUR_PROMPT_STYLE="starship"; save_config ;;
        2) CUR_PROMPT_STYLE="custom";   save_config ;;
        0|"") return ;;
        *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
    esac
}

#=================================================================
# Submenu — Starship theme
#=================================================================
configure_starship_theme() {
    display_banner
    echo -e "${CYAN}▶ Starship Theme${RC}"
    echo ""

    if [ ! -d "$STARSHIP_THEMES_DIR" ]; then
        echo -e "${RED}  Themes directory not found: $STARSHIP_THEMES_DIR${RC}"
        echo -e "${YELLOW}  Run dxsbash-repair or re-install DXSBash.${RC}"
        echo ""
        read -rp "  Press Enter to return..."
        return
    fi

    local starship_status
    if command -v starship &>/dev/null; then
        starship_status="${GREEN}installed${RC}"
    else
        starship_status="${RED}not installed${RC}${DIM} (themes will apply once starship is installed)${RC}"
    fi
    echo -e "  Starship: $starship_status"
    echo -e "  Current:  ${WHITE}$(starship_theme_display_name "$CUR_STARSHIP_THEME")${RC}"
    echo ""
    echo -e "  Pick a preset:"
    echo ""

    local i=1
    local entry name fname marker
    for entry in "${STARSHIP_THEMES[@]}"; do
        name="$(theme_field "$entry" 1)"
        fname="$(theme_field "$entry" 2)"
        marker=""
        [ "$fname" = "$CUR_STARSHIP_THEME" ] && marker=" ${GREEN}← current${RC}"
        printf "  ${WHITE}%d)${RC} %s%b\n" "$i" "$name" "$marker"
        (( i++ ))
    done
    echo ""
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        return
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || \
       [ "$choice" -lt 1 ] || [ "$choice" -gt "${#STARSHIP_THEMES[@]}" ]; then
        echo -e "${RED}  Invalid choice.${RC}"
        sleep 1
        return
    fi

    entry="${STARSHIP_THEMES[$((choice-1))]}"
    name="$(theme_field "$entry" 1)"
    fname="$(theme_field "$entry" 2)"

    echo ""
    if apply_starship_theme "$fname"; then
        CUR_STARSHIP_THEME="$fname"
        # Switching to a Starship preset implies the user wants the
        # Starship prompt active, not the built-in one.
        if [ "$CUR_PROMPT_STYLE" != "starship" ]; then
            CUR_PROMPT_STYLE="starship"
            echo -e "${YELLOW}  Prompt style switched to 'starship'.${RC}"
        fi
        save_config
        echo -e "${GREEN}  Theme set to: ${WHITE}$name${RC}"
        sleep 1
    else
        sleep 2
    fi
}

#=================================================================
# Submenu — Startup display (fastfetch)
#=================================================================
configure_fastfetch() {
    display_banner
    echo -e "${CYAN}▶ Startup Display (Fastfetch)${RC}"
    echo ""
    echo -e "  Fastfetch shows system information when a new terminal opens."
    echo -e "  It is suppressed automatically in SSH sessions."
    echo ""

    local ff_status
    if command -v fastfetch &>/dev/null; then
        ff_status="${GREEN}installed${RC}"
    else
        ff_status="${RED}not installed${RC}"
    fi
    local ff_setting
    [ "$CUR_FASTFETCH" = "true" ] && ff_setting="${GREEN}enabled${RC}" || ff_setting="${RED}disabled${RC}"

    echo -e "  Fastfetch: $ff_status"
    echo -e "  Current:   $ff_setting"
    echo ""
    echo -e "  ${WHITE}1)${RC} Enable  fastfetch on startup"
    echo -e "  ${WHITE}2)${RC} Disable fastfetch on startup"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        1) CUR_FASTFETCH="true";  save_config ;;
        2) CUR_FASTFETCH="false"; save_config ;;
        0|"") return ;;
        *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
    esac
}

#=================================================================
# Submenu — Security summary at login
#=================================================================
configure_secsummary() {
    display_banner
    echo -e "${CYAN}▶ Security Summary at Login${RC}"
    echo ""
    echo -e "  Shows a one-line security status when a new shell opens"
    echo -e "  (pending security updates, failed SSH logins, firewall"
    echo -e "  state, reboot-required). Unlike fastfetch it is ${WHITE}also"
    echo -e "  shown over SSH${RC}, where it is most useful."
    echo ""
    echo -e "  It reads from a cache and refreshes in the background, so"
    echo -e "  it does not slow down opening a terminal. For the full"
    echo -e "  report run ${WHITE}dxsbash audit${RC}."
    echo ""

    local ss_setting
    [ "$CUR_SECSUMMARY" = "true" ] && ss_setting="${GREEN}enabled${RC}" || ss_setting="${RED}disabled${RC}"
    echo -e "  Current:   $ss_setting"
    echo ""
    echo -e "  ${WHITE}1)${RC} Enable  security summary at login"
    echo -e "  ${WHITE}2)${RC} Disable security summary at login"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        1)
            CUR_SECSUMMARY="true"
            save_config
            # Prime the cache now so the first login shows real data.
            prime_secsummary_cache
            ;;
        2) CUR_SECSUMMARY="false"; save_config ;;
        0|"") return ;;
        *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
    esac
}

#=================================================================
# Submenu — Lightweight prompt over SSH
#=================================================================
configure_ssh_lite() {
    display_banner
    echo -e "${CYAN}▶ Lightweight Prompt over SSH${RC}"
    echo ""
    echo -e "  Inside SSH sessions, switch Starship to a minimal preset"
    echo -e "  (no git status scan, no language versions) so the prompt"
    echo -e "  stays instant on slow links and busy servers."
    echo ""
    local sl_setting
    [ "$CUR_SSH_LITE" = "true" ] && sl_setting="${GREEN}enabled${RC}" || sl_setting="${RED}disabled${RC}"
    echo -e "  Current:   $sl_setting"
    echo ""
    echo -e "  ${WHITE}1)${RC} Enable  lightweight prompt over SSH"
    echo -e "  ${WHITE}2)${RC} Disable (use your normal theme over SSH too)"
    echo -e "  ${WHITE}0)${RC} Back"
    echo ""

    read -rp "  Choice: " choice
    case "$choice" in
        1) CUR_SSH_LITE="true";  save_config ;;
        2) CUR_SSH_LITE="false"; save_config ;;
        0|"") return ;;
        *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
    esac
}

#=================================================================
# Reset to defaults
#=================================================================
reset_to_defaults() {
    display_banner
    echo -e "${YELLOW}  This will reset all DXSBash settings to their defaults:${RC}"
    echo ""
    echo -e "    Editor         → ${WHITE}$DEF_EDITOR${RC}"
    echo -e "    HISTSIZE       → ${WHITE}$DEF_HISTSIZE${RC}"
    echo -e "    HISTFILESIZE   → ${WHITE}$DEF_HISTFILESIZE${RC}"
    echo -e "    Fastfetch        → ${WHITE}$DEF_FASTFETCH${RC}"
    echo -e "    Prompt style     → ${WHITE}$DEF_PROMPT_STYLE${RC}"
    echo -e "    Starship theme   → ${WHITE}$(starship_theme_display_name "$DEF_STARSHIP_THEME")${RC}"
    echo -e "    Security summary → ${WHITE}$DEF_SECSUMMARY${RC}"
    echo -e "    SSH-lite prompt  → ${WHITE}$DEF_SSH_LITE${RC}"
    echo ""
    read -rp "  Continue? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        reset_settings_to_defaults
        apply_starship_theme "$DEF_STARSHIP_THEME" >/dev/null 2>&1 || true
        save_config
    else
        echo -e "${YELLOW}  Reset cancelled.${RC}"
        sleep 1
    fi
}

#=================================================================
# Main menu loop
#=================================================================
main_menu() {
    while true; do
        display_banner
        load_config
        show_current_settings

        echo -e "  ${WHITE}1)${RC} Editor preference       ${DIM}(${CUR_EDITOR})${RC}"
        echo -e "  ${WHITE}2)${RC} Shell history           ${DIM}(HISTSIZE=${CUR_HISTSIZE})${RC}"
        echo -e "  ${WHITE}3)${RC} Prompt style            ${DIM}(${CUR_PROMPT_STYLE})${RC}"
        echo -e "  ${WHITE}4)${RC} Starship theme          ${DIM}($(starship_theme_display_name "$CUR_STARSHIP_THEME"))${RC}"
        echo -e "  ${WHITE}5)${RC} Startup display         ${DIM}(fastfetch=${CUR_FASTFETCH})${RC}"
        echo -e "  ${WHITE}6)${RC} Security summary        ${DIM}(secsummary=${CUR_SECSUMMARY})${RC}"
        echo -e "  ${WHITE}7)${RC} SSH-lite prompt         ${DIM}(ssh-lite=${CUR_SSH_LITE})${RC}"
        echo -e "  ${WHITE}8)${RC} Reset to defaults"
        echo -e "  ${WHITE}0)${RC} Exit"
        echo ""

        read -rp "  Choice: " choice
        case "$choice" in
            1) configure_editor ;;
            2) configure_history ;;
            3) configure_prompt ;;
            4) configure_starship_theme ;;
            5) configure_fastfetch ;;
            6) configure_secsummary ;;
            7) configure_ssh_lite ;;
            8) reset_to_defaults ;;
            0|"q"|"Q"|"exit") break ;;
            *) echo -e "${RED}  Invalid choice.${RC}"; sleep 1 ;;
        esac
    done
}

#=================================================================
# Entry point
#=================================================================
main() {
    # Must be run interactively
    if [ ! -t 0 ]; then
        echo "dxsbash-config must be run in an interactive terminal." >&2
        exit 1
    fi

    mkdir -p "$CONF_DIR"
    load_config
    main_menu

    echo ""
    echo -e "${CYAN}  Configuration complete. Open a new terminal or run:${RC}"
    echo -e "  ${WHITE}source ~/.bashrc${RC}  (bash)"
    echo -e "  ${WHITE}source ~/.zshrc${RC}   (zsh)"
    echo ""
}

main
