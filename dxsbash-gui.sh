#!/bin/bash
#=================================================================
# DXSBash Settings — graphical configuration (zenity)
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# Author: Luis Miguel P. Freitas
# License: GPL-3.0
#
# Launched from the desktop menu (System → DXSBash Settings), with
# 'dxsbash gui', or directly as dxsbash-gui.
#
# Usage:
#   dxsbash-gui                    open the settings window
#   dxsbash-gui --update           jump straight to the update check
#   dxsbash-gui --themes           jump straight to the theme picker
#   dxsbash-gui --aliases          jump straight to the alias editor
#   dxsbash-gui --install-desktop  install menu entry, icon and daily update check
#   dxsbash-gui --remove-desktop   remove them again
#   dxsbash-gui --apply-colors     re-apply terminal colors for the current theme
#   dxsbash-gui --sync-aliases     regenerate the fish alias twin
#   dxsbash-gui --selftest         non-GUI self test (used by CI)
#
# All settings go through settings-lib.sh, shared with the terminal
# tool dxsbash-config, so both always read/write identical files.
#
# No 'set -e': every Cancel/Close in zenity exits non-zero and the
# menu loop must survive that — results are checked explicitly.
#=================================================================

set -u

SELF="$(readlink -f "$0")"
DXSBASH_DIR="${DXSBASH_DIR:-$(dirname "$SELF")}"

if [ ! -f "$DXSBASH_DIR/settings-lib.sh" ]; then
    echo "dxsbash-gui: settings-lib.sh not found in $DXSBASH_DIR" >&2
    exit 1
fi
# shellcheck source=settings-lib.sh
source "$DXSBASH_DIR/settings-lib.sh"

APP_NAME="DXSBash Settings"
# $USER is not guaranteed (minimal launchers, env -i); ask the system
ME="$(id -un)"
ICON_SRC_DIR="$DXSBASH_DIR/assets/icons/hicolor"
ICON_PNG="$ICON_SRC_DIR/256x256/apps/dxsbash.png"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_FILE="$DATA_HOME/applications/dxsbash-settings.desktop"
ICON_HICOLOR="$DATA_HOME/icons/hicolor"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UPDATE_TIMER="dxsbash-update-check.timer"
UPDATE_SERVICE="dxsbash-update-check.service"
# zenity/GTK diagnostics for troubleshooting (overwritten each session)
GUI_LOG="$CONF_DIR/logs/gui.log"

#=================================================================
# Desktop integration (menu entry + icon) — also used by setup.sh,
# repair.sh and uninstall.sh so the logic lives in one place
#=================================================================

# Escape a path for a double-quoted desktop-entry Exec argument. The
# spec applies two levels: Exec quoting (\ " ` $ get a backslash), then
# the key's string escaping (every backslash doubled again); % starts a
# field code, so a literal one is %%.
_desktop_exec_escape() {
    local s="$1"
    s="${s//\\/"\\\\"}"; s="${s//\"/"\\\""}"; s="${s//\`/"\\\`"}"; s="${s//\$/"\\\$"}"
    s="${s//\\/"\\\\"}"
    s="${s//%/"%%"}"
    printf '%s' "$s"
}

# Desktop-entry string escaping only (TryExec is a path, not a command line)
_desktop_string_escape() {
    local s="$1"
    s="${s//\\/"\\\\"}"
    printf '%s' "$s"
}

# Icon files shipped in assets/icons/hicolor, relative to hicolor/
_icon_files() {
    ( cd "$ICON_SRC_DIR" 2>/dev/null && find . -type f -name 'dxsbash.*' | sed 's|^\./||' )
}

install_desktop() {
    local tpl="$DXSBASH_DIR/desktop/dxsbash-settings.desktop.in"
    [ -f "$tpl" ] || { echo "template missing: $tpl" >&2; return 1; }
    [ -d "$ICON_SRC_DIR" ] || { echo "icons missing: $ICON_SRC_DIR" >&2; return 1; }

    # Full icon set: the SVG for KDE/HiDPI plus PNG sizes, because some
    # toolkits (GTK4) only resolve themed icons from the sized PNG dirs
    local f
    while IFS= read -r f; do
        mkdir -p "$ICON_HICOLOR/$(dirname "$f")"
        cp "$ICON_SRC_DIR/$f" "$ICON_HICOLOR/$f"
    done < <(_icon_files)
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    chmod +x "$SELF" 2>/dev/null || true

    local exec_path try_path line
    exec_path="$(_desktop_exec_escape "$SELF")"
    try_path="$(_desktop_string_escape "$SELF")"
    # Build line by line with bash substitution — no sed, so paths
    # containing sed metacharacters (& | /) need no special handling
    while IFS= read -r line || [ -n "$line" ]; do
        # Quoted replacements: see esc() about & in bash >= 5.2
        line="${line//\"@GUI@\"/"\"$exec_path\""}"
        line="${line//@GUI@/"$try_path"}"
        printf '%s\n' "$line"
    done < "$tpl" > "$DESKTOP_FILE.tmp" && mv "$DESKTOP_FILE.tmp" "$DESKTOP_FILE"
    chmod 644 "$DESKTOP_FILE"

    _refresh_menus
    install_update_timer
    echo "Installed menu entry: $DESKTOP_FILE"
}

# Daily update check (update-notify.sh) as a systemd user timer. The
# units are copied and enabled by creating the wants/ link directly, so
# this works even without a reachable user manager (setup.sh running
# through sudo): the timer then starts at the next login.
# systemctl --user, except inside --selftest (the sandboxed unit files
# must not stop/start the real user's timer)
_systemctl_user() {
    [ -n "${DXS_SELFTEST:-}" ] && return 0
    systemctl --user "$@"
}

install_update_timer() {
    command -v systemctl >/dev/null 2>&1 || return 0
    [ -f "$DXSBASH_DIR/systemd/$UPDATE_TIMER" ] || return 0
    mkdir -p "$SYSTEMD_USER_DIR/timers.target.wants"
    cp "$DXSBASH_DIR/systemd/$UPDATE_SERVICE" "$DXSBASH_DIR/systemd/$UPDATE_TIMER" "$SYSTEMD_USER_DIR/"
    ln -sf "../$UPDATE_TIMER" "$SYSTEMD_USER_DIR/timers.target.wants/$UPDATE_TIMER"
    if _systemctl_user daemon-reload >/dev/null 2>&1; then
        _systemctl_user start "$UPDATE_TIMER" >/dev/null 2>&1 || true
    fi
    return 0
}

remove_update_timer() {
    _systemctl_user disable --now "$UPDATE_TIMER" >/dev/null 2>&1 || true
    rm -f "$SYSTEMD_USER_DIR/timers.target.wants/$UPDATE_TIMER" \
          "$SYSTEMD_USER_DIR/$UPDATE_TIMER" "$SYSTEMD_USER_DIR/$UPDATE_SERVICE"
    _systemctl_user daemon-reload >/dev/null 2>&1 || true
    return 0
}

remove_desktop() {
    local f
    rm -f "$DESKTOP_FILE"
    while IFS= read -r f; do
        rm -f "$ICON_HICOLOR/$f"
    done < <(_icon_files)
    _refresh_menus
    remove_update_timer
    echo "Removed menu entry, icons and update check"
}

# Tell the desktop about the change. All optional: KDE also rescans
# on its own, this just makes the entry appear immediately.
_refresh_menus() {
    # --selftest: never rebuild real desktop caches (kbuildsycoca also
    # wrote into the sandbox while it was being deleted)
    [ -n "${DXS_SELFTEST:-}" ] && return 0
    command -v update-desktop-database >/dev/null 2>&1 && \
        update-desktop-database "$(dirname "$DESKTOP_FILE")" >/dev/null 2>&1
    # A stale user icon cache would hide the new icon from GTK
    [ -f "$ICON_HICOLOR/icon-theme.cache" ] && command -v gtk-update-icon-cache >/dev/null 2>&1 && \
        gtk-update-icon-cache -f -t "$ICON_HICOLOR" >/dev/null 2>&1
    local k
    for k in kbuildsycoca6 kbuildsycoca5; do
        if command -v "$k" >/dev/null 2>&1; then
            ( "$k" >/dev/null 2>&1 & )
            break
        fi
    done
    return 0
}

#=================================================================
# zenity plumbing
#=================================================================
ZENITY_MAJOR=0

# GLib converts option arguments (--text=...) from the locale charset:
# under a non-UTF-8 locale (LANG unset, LANG=C) any non-ASCII text —
# emoji, accents, prompt glyphs — makes zenity abort with "This option
# is not available". Switch only the charset category to UTF-8 so the
# user's language (LC_MESSAGES) is kept.
ensure_utf8_locale() {
    case "$(locale charmap 2>/dev/null)" in
        UTF-8|utf8) return 0 ;;
    esac
    if [ -n "${LC_ALL:-}" ]; then
        export LC_ALL=C.UTF-8
    else
        export LC_CTYPE=C.UTF-8
    fi
}

require_zenity() {
    ensure_utf8_locale
    if command -v zenity >/dev/null 2>&1; then
        ZENITY_MAJOR=$(zenity --version 2>/dev/null | cut -d. -f1)
        [[ "$ZENITY_MAJOR" =~ ^[0-9]+$ ]] || ZENITY_MAJOR=0
        return 0
    fi
    local hint="install the 'zenity' package"
    if command -v apt >/dev/null 2>&1; then hint="sudo apt install zenity"
    elif command -v dnf >/dev/null 2>&1; then hint="sudo dnf install zenity"
    elif command -v pacman >/dev/null 2>&1; then hint="sudo pacman -S zenity"
    fi
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --title "$APP_NAME" --error "DXSBash Settings needs zenity.\n\nInstall it with:  $hint"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send "$APP_NAME" "zenity is required — $hint"
    fi
    echo "dxsbash-gui: zenity is required — $hint" >&2
    exit 1
}

# List cells are plain argv words and zenity parses argv with GOption:
# a cell starting with "-" (an alias command like "-la", history "-1")
# is read as an unknown option and the dialog refuses to open. "--"
# does not help (zenity keeps it as a cell). Pass user-derived cells
# through cell(), which prefixes an invisible zero-width space.
cell() {
    case "$1" in
        -*) printf '\u200b%s' "$1" ;;
        *)  printf '%s' "$1" ;;
    esac
}

# History sizes for display: -1 means unlimited
hist_label() { [[ "$1" == -* ]] && echo "unlimited" || echo "$1"; }
#
# Common options. zenity 4 treats --window-icon as deprecated (the
# window icon comes from the desktop entry via StartupWMClass), so it
# is only passed to zenity 3. Diagnostics go to $GUI_LOG.
Z() {
    if [ "$ZENITY_MAJOR" -ge 4 ]; then
        zenity --title="$APP_NAME" "$@" 2>>"$GUI_LOG"
    else
        zenity --title="$APP_NAME" --window-icon="$ICON_PNG" "$@" 2>>"$GUI_LOG"
    fi
}

# Message dialogs carry the DXSBash logo. zenity takes an icon-theme
# *name* (a file path renders as a broken image), so use the name once
# --install-desktop has put dxsbash.svg into the user's hicolor theme.
_icon_opt() {
    local name="utilities-terminal"
    [ -f "$ICON_HICOLOR/48x48/apps/dxsbash.png" ] && name="dxsbash"
    if [ "$ZENITY_MAJOR" -ge 4 ]; then
        printf '%s' "--icon=$name"
    else
        printf '%s' "--icon-name=$name"
    fi
}

# Escape user text for a zenity --text: Pango markup (& < >) plus
# backslashes, which zenity unescapes (\n → newline) — an alias like
# printf "%s\n" would otherwise be displayed wrongly.
esc() {
    local s="$1"
    # Replacements are quoted: in bash >= 5.2 (patsub_replacement) an
    # unquoted & in the replacement stands for the matched text
    s="${s//\\/"\\\\"}"
    s="${s//&/"&amp;"}"; s="${s//</"&lt;"}"; s="${s//>/"&gt;"}"
    printf '%s' "$s"
}

info()  { Z --info  "$(_icon_opt)" --width=440 --text="$1"; }
error() { Z --error --width=440 --text="$1"; }
ask()   { Z --question "$(_icon_opt)" --width=440 --text="$1" "${@:2}"; }

# write_settings refuses unsafe values (quotes, $, `, \) — say so
save_settings() {
    write_settings "dxsbash-gui" && return 0
    error "<b>Settings not saved.</b>\nA value contains a character that is not allowed (\" \$ \` or a backslash)."
    return 1
}

# Mention the backup a theme change made of a hand-written starship.toml
backup_note() {
    [ -n "${STARSHIP_BACKUP:-}" ] || return 0
    printf '%s' "\n\nYour own starship.toml was kept as\n<tt>$(esc "$STARSHIP_BACKUP")</tt>"
}

applied() {
    info "$1\n\n<small>Takes effect in new terminal windows\n(or run <tt>source ~/.bashrc</tt> in an open one).</small>"
}

onoff() { [ "$1" = "true" ] && echo "On" || echo "Off"; }

version() { cat "$DXSBASH_DIR/version.txt" 2>/dev/null || echo "?"; }

strip_ansi() { sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

# Run a command while a pulsating progress dialog is shown; output is
# captured to $2. Returns the command's exit status.
run_with_progress() { # $1 = message, $2 = log file, rest = command
    local msg="$1" log="$2"; shift 2
    "$@" >"$log" 2>&1 &
    local pid=$!
    ( while kill -0 "$pid" 2>/dev/null; do echo "# $msg"; sleep 0.3; done ) | \
        Z --progress --pulsate --auto-close --no-cancel --width=440 --text="$msg"
    wait "$pid"
}

show_log() { # $1 = title, $2 = file
    Z --text-info --width=720 --height=480 --title="$APP_NAME — $1" \
      --font="monospace 10" --filename="$2" >/dev/null
}

#=================================================================
# Updates
#=================================================================
ui_update() {
    local out rc
    out=$(bash "$DXSBASH_DIR/updater.sh" --check 2>&1)
    rc=$?
    case "$rc" in
        0)  info "<b>DXSBash is up to date.</b>\n\n$(esc "$out")"
            return ;;
        10) ;;
        *)  error "<b>Could not check for updates.</b>\nAre you connected to the internet?\n\n<tt>$(esc "$(printf '%s' "$out" | tail -3)")</tt>"
            return ;;
    esac

    # "Update available: 3.7.0 -> 3.8.0" → "3.7.0  →  3.8.0"
    local from to versions detail=""
    if [[ "$out" =~ ([0-9][0-9.]*|unknown)\ -\>\ ([0-9][0-9.]*) ]]; then
        from="${BASH_REMATCH[1]}"; to="${BASH_REMATCH[2]}"
        # "(stable channel)" / "(main @ abc1234)"
        [[ "$out" =~ \((.*)\)$ ]] && detail="\n<small>$(esc "${BASH_REMATCH[1]}")</small>"
        versions="<big>$(esc "$from")  →  <b>$(esc "$to")</b></big>$detail"
    else
        versions="$(esc "$out")"
    fi
    ask "<b>A new version of DXSBash is available.</b>\n\n$versions\n\nInstall it now? Your settings, theme and aliases are kept." \
        --ok-label="Update now" --cancel-label="Later" || return

    local log
    log=$(mktemp)
    # setsid detaches from any controlling terminal so that sudo (used
    # by the updater to relink commands) asks for the password through
    # the graphical SUDO_ASKPASS helper instead of an invisible tty.
    if run_with_progress "Updating DXSBash…" "$log" \
        env SUDO_ASKPASS="$DXSBASH_DIR/gui-askpass.sh" \
        setsid -w bash "$DXSBASH_DIR/updater.sh" </dev/null; then
        strip_ansi <"$log" >"$log.txt"
        show_log "update complete (now $(version))" "$log.txt"
        rm -f "$log" "$log.txt"
        # This window is still running the old code — reload it
        exec bash "$SELF"
    else
        strip_ansi <"$log" >"$log.txt"
        error "<b>The update failed.</b> The log will open next."
        show_log "update log" "$log.txt"
    fi
    rm -f "$log" "$log.txt"
}

#=================================================================
# Prompt: live theme gallery + engine choice
#=================================================================
# Nerd Fonts first: plain Fira Code also has a few private-use glyphs
# and would otherwise win the fallback, drawing wrong symbols. DXSBash
# installs FiraCode Nerd Font; the others cover users who chose theirs.
PREVIEW_FONT="FiraCode Nerd Font Mono,FiraCode Nerd Font,Symbols Nerd Font Mono,Symbols Nerd Font,JetBrainsMono Nerd Font,Hack Nerd Font,MesloLGS NF,monospace 10"

# Render one theme's real prompt — the user's own starship, fonts and
# DXSBash git checkout — as Pango markup for display in a dialog.
_theme_preview() { # $1 = theme id
    local path
    path="$(theme_path "$1")"
    (
        cd "$DXSBASH_DIR" 2>/dev/null || cd "$HOME" || exit 0
        env -u STARSHIP_SHELL -u STARSHIP_SESSION_KEY \
            STARSHIP_CONFIG="$path" \
            timeout 3 starship prompt --status=0 --cmd-duration=0 --jobs=0 \
                --terminal-width=110 2>/dev/null
    ) | awk -f "$DXSBASH_DIR/tools/ansi2pango.awk" \
            -v bg="#0d1117" -v pad=1 -v font="$PREVIEW_FONT"
}

# Previews are drawn in the dialog header, which cannot scroll: beyond
# this many themes the rest are listed without a preview
MAX_PREVIEWS=10

# Ask for a Starship .toml file and add it to ~/.dxsbash/themes.
# Prints the new theme id on success.
_add_user_theme() {
    local src id err
    src=$(Z --file-selection --title="$APP_NAME — add your own Starship theme" \
        --file-filter="Starship config | *.toml") || return 1
    [ -n "$src" ] || return 1
    if [ -f "$USER_THEMES_DIR/${src##*/}" ] && \
       ! ask "A theme named <tt>$(esc "${src##*/}")</tt> already exists. Replace it?"; then
        return 1
    fi
    if ! id=$(import_user_theme "$src" 2>"$GUI_LOG.theme"); then
        err="$(cat "$GUI_LOG.theme" 2>/dev/null)"
        error "<b>Could not add this theme.</b>\n\n$(esc "$err")"
        rm -f "$GUI_LOG.theme"
        return 1
    fi
    rm -f "$GUI_LOG.theme"
    printf '%s' "$id"
}

ui_themes() {
    local have_starship=0 gallery="" entry name id desc preview shown=0
    command -v starship >/dev/null 2>&1 && have_starship=1

    local -a rows=()
    while IFS= read -r entry; do
        name="$(theme_field "$entry" 1)"
        id="$(theme_field "$entry" 2)"
        desc="$(theme_field "$entry" 3)"
        rows+=("$([ "$id" = "$CUR_STARSHIP_THEME" ] && echo TRUE || echo FALSE)" \
               "$(cell "$name")" "$(cell "$desc")" "$id")
        if [ "$have_starship" -eq 1 ] && [ "$shown" -lt "$MAX_PREVIEWS" ]; then
            preview="$(_theme_preview "$id")"
            preview="${preview//\\/"\\\\"}"
            gallery+="<small><b>$(esc "$name")</b></small>\n${preview//$'\n'/\\n}\n"
            shown=$((shown + 1))
        fi
    done < <(theme_entries)

    local header
    if [ "$have_starship" -eq 1 ]; then
        header="<big><b>Choose your prompt style</b></big>   <small>live previews of your own prompt</small>\n\n$gallery"
    else
        header="<big><b>Choose your prompt style</b></big>\n<small>Install Starship (dxsbash-repair --deps) to see live previews here.</small>"
    fi

    local sel rc
    sel=$(Z --list --radiolist --width=1080 --height=780 \
        --text="$header" \
        --column="" --column="Theme" --column="Style" --column="id" \
        --hide-column=4 --print-column=4 \
        --ok-label="Apply theme" --cancel-label="Back" \
        --extra-button="Add your own…" "${rows[@]}")
    rc=$?
    if [ "$sel" = "Add your own…" ]; then
        # Import, then show the picker again with the new theme in it
        _add_user_theme >/dev/null && info "Theme added — it is now in the list with a live preview."
        ui_themes
        return
    fi
    [ "$rc" -eq 0 ] && [ -n "$sel" ] || return

    if ! link_starship_theme "$sel"; then
        error "Theme file not found: $(esc "$(theme_path "$sel")")"
        return
    fi
    CUR_STARSHIP_THEME="$sel"
    local note scheme
    note="$(backup_note)"
    # Picking a Starship theme implies wanting the Starship prompt
    if [ "$CUR_PROMPT_STYLE" != "starship" ]; then
        CUR_PROMPT_STYLE="starship"
        note+="\nPrompt engine switched to Starship."
    fi
    save_settings || return
    if scheme=$(apply_terminal_colors "$sel"); then
        note+="\nKonsole/Yakuake colors: <b>$(esc "$scheme")</b> (new terminal windows)."
    fi
    if [ "$have_starship" -eq 0 ]; then
        note+="\n\n<b>Note:</b> Starship is not installed — the theme applies once it is (run dxsbash-repair --deps)."
        applied "Prompt theme set to <b>$(esc "$(starship_theme_display_name "$sel")")</b>.$note"
    else
        # --no-wrap: a wrapped prompt preview would be unreadable
        Z --info "$(_icon_opt)" --no-wrap \
          --text="Prompt theme set to <b>$(esc "$(starship_theme_display_name "$sel")")</b>.$note\n\n$(_theme_preview "$sel" | sed 's/\\/\\\\/g' | sed ':a;N;$!ba;s/\n/\\n/g')\n\n<small>Takes effect in new terminal windows\n(or run <tt>source ~/.bashrc</tt> in an open one).</small>"
    fi
}

ui_update_channel() {
    local st="FALSE" mn="FALSE" sel
    [ "$CUR_UPDATE_CHANNEL" = "main" ] && mn="TRUE" || st="TRUE"
    sel=$(Z --list --radiolist --width=620 --height=270 \
        --text="<b>Update channel</b>\nWhich DXSBash versions updates (and update notifications) follow.\n<small>Switching to Stable never downgrades: you move on at the next release.</small>" \
        --column="" --column="Channel" --column="What you get" --column="key" \
        --hide-column=4 --print-column=4 \
        "$st" "Stable" "Tagged releases only (recommended)" "stable" \
        "$mn" "Main" "Every change as soon as it is pushed — newest, least tested" "main") || return
    [ -n "$sel" ] || return
    CUR_UPDATE_CHANNEL="$sel"
    save_settings || return
    rm -f "$CONF_DIR/update-notified"   # re-evaluate notifications for the new channel
    applied "Update channel set to <b>$sel</b>."
}

ui_prompt_engine() {
    local s="FALSE" c="FALSE" sel
    [ "$CUR_PROMPT_STYLE" = "custom" ] && c="TRUE" || s="TRUE"
    sel=$(Z --list --radiolist --width=560 --height=260 \
        --text="<b>Prompt engine</b>" \
        --column="" --column="Engine" --column="Description" --column="key" \
        --hide-column=4 --print-column=4 \
        "$s" "Starship" "Themeable cross-shell prompt (recommended)" "starship" \
        "$c" "Built-in" "Classic DXSBash prompt — no Starship needed" "custom") || return
    [ -n "$sel" ] || return
    CUR_PROMPT_STYLE="$sel"
    save_settings || return
    applied "Prompt engine set to <b>$([ "$sel" = starship ] && echo Starship || echo Built-in)</b>."
}

#=================================================================
# Startup & behavior options (one checklist)
#=================================================================
ui_options() {
    local out
    out=$(Z --list --checklist --width=720 --height=380 \
        --text="<b>Startup &amp; behavior</b>\nTick the features you want." \
        --column="On" --column="Option" --column="What it does" --column="key" \
        --hide-column=4 --print-column=4 --separator=" " \
        "$([ "$CUR_FASTFETCH" = true ] && echo TRUE || echo FALSE)" \
            "System info at startup" "Show fastfetch when a local terminal opens" "fastfetch" \
        "$([ "$CUR_SECSUMMARY" = true ] && echo TRUE || echo FALSE)" \
            "Security summary at login" "One-line security status (also over SSH)" "secsummary" \
        "$([ "$CUR_SSH_LITE" = true ] && echo TRUE || echo FALSE)" \
            "Lightweight prompt over SSH" "Minimal, instant prompt inside SSH sessions" "sshlite" \
        "$([ "$CUR_UPDATE_NOTIFY" = true ] && echo TRUE || echo FALSE)" \
            "Notify me about updates" "Daily check; a desktop notification when a release is out" "notify" \
        "$([ "$CUR_TERM_COLORS" = true ] && echo TRUE || echo FALSE)" \
            "Match terminal colors to theme" "Konsole/Yakuake colors follow the prompt theme" "colors") || return

    local was_ss="$CUR_SECSUMMARY" was_colors="$CUR_TERM_COLORS" extra=""
    CUR_FASTFETCH=false; CUR_SECSUMMARY=false; CUR_SSH_LITE=false
    CUR_UPDATE_NOTIFY=false; CUR_TERM_COLORS=false
    [[ " $out " == *" fastfetch "* ]]  && CUR_FASTFETCH=true
    [[ " $out " == *" secsummary "* ]] && CUR_SECSUMMARY=true
    [[ " $out " == *" sshlite "* ]]    && CUR_SSH_LITE=true
    [[ " $out " == *" notify "* ]]     && CUR_UPDATE_NOTIFY=true
    [[ " $out " == *" colors "* ]]     && CUR_TERM_COLORS=true
    save_settings || return
    [ "$was_ss" != "true" ] && [ "$CUR_SECSUMMARY" = "true" ] && prime_secsummary_cache
    local scheme
    if [ "$was_colors" != "true" ] && [ "$CUR_TERM_COLORS" = "true" ] && scheme=$(apply_terminal_colors); then
        extra="\nKonsole/Yakuake colors: <b>$(esc "$scheme")</b>"
    fi
    applied "Options saved.\n\nSystem info: <b>$(onoff "$CUR_FASTFETCH")</b>   Security summary: <b>$(onoff "$CUR_SECSUMMARY")</b>   SSH-lite: <b>$(onoff "$CUR_SSH_LITE")</b>\nUpdate notifications: <b>$(onoff "$CUR_UPDATE_NOTIFY")</b>   Terminal colors: <b>$(onoff "$CUR_TERM_COLORS")</b>$extra"
}

#=================================================================
# Editor, history, login shell
#=================================================================
ui_editor() {
    local -a rows=()
    local ed
    for ed in nano micro vim nvim emacs joe kate gedit mousepad xed code; do
        command -v "$ed" >/dev/null 2>&1 || continue
        rows+=("$([ "$ed" = "$CUR_EDITOR" ] && echo TRUE || echo FALSE)" "$ed")
    done
    [ ${#rows[@]} -gt 0 ] || { error "No known text editors were found."; return; }
    local sel
    sel=$(Z --list --radiolist --width=420 --height=420 \
        --text="<b>Default text editor</b> (\$EDITOR / \$VISUAL)" \
        --column="" --column="Editor" "${rows[@]}") || return
    [ -n "$sel" ] || return
    CUR_EDITOR="$sel"
    save_settings || return
    applied "Default editor set to <b>$(esc "$sel")</b>."
}

ui_history() {
    local presets sel h1 h2
    presets=$(Z --list --radiolist --width=520 --height=340 \
        --text="<b>Shell history size</b> (bash and zsh)\nCurrent: $(hist_label "$CUR_HISTSIZE") in memory / $(hist_label "$CUR_HISTFILESIZE") on disk" \
        --column="" --column="Preset" --column="In memory" --column="On disk" \
        FALSE "Small" 500 5000 \
        FALSE "Medium" 1000 10000 \
        FALSE "Large" 5000 50000 \
        FALSE "Unlimited" "unlimited" "unlimited" \
        FALSE "Custom…" "" "") || return
    sel="$presets"
    case "$sel" in
        Small)     h1=500;  h2=5000 ;;
        Medium)    h1=1000; h2=10000 ;;
        Large)     h1=5000; h2=50000 ;;
        Unlimited) h1=-1;   h2=-1 ;;
        "Custom…")
            local out
            out=$(Z --forms --width=420 --text="<b>Custom history size</b>\nUse -1 for unlimited." \
                --add-entry="In memory (HISTSIZE)" \
                --add-entry="On disk (HISTFILESIZE)") || return
            h1="${out%%|*}"; h2="${out##*|}"
            if ! [[ "$h1" =~ ^-?[0-9]+$ && "$h2" =~ ^-?[0-9]+$ ]]; then
                error "Both values must be whole numbers (or -1)."
                return
            fi
            ;;
        *) return ;;
    esac
    CUR_HISTSIZE="$h1"; CUR_HISTFILESIZE="$h2"
    save_settings || return
    applied "History size set to <b>$(hist_label "$h1")</b> in memory / <b>$(hist_label "$h2")</b> on disk."
}

# Which shells have DXSBash configuration linked for this user
_configured_shells() {
    [ -L "$HOME/.bashrc" ] && readlink "$HOME/.bashrc" | grep -q dxsbash && echo bash
    [ -L "$HOME/.zshrc" ] && readlink "$HOME/.zshrc" | grep -q dxsbash && echo zsh
    [ -L "$HOME/.config/fish/config.fish" ] && \
        readlink "$HOME/.config/fish/config.fish" | grep -q dxsbash && echo fish
    return 0
}

current_login_shell() {
    local sh
    sh=$(getent passwd "$ME" 2>/dev/null | cut -d: -f7)
    basename "${sh:-${SHELL:-bash}}"
}

ui_login_shell() {
    local cur sh path
    cur=$(current_login_shell)
    local -a rows=()
    while IFS= read -r sh; do
        path=$(grep -E "/${sh}$" /etc/shells 2>/dev/null | head -1)
        [ -n "$path" ] || continue
        rows+=("$([ "$sh" = "$cur" ] && echo TRUE || echo FALSE)" "$sh" "$path")
    done < <(_configured_shells)
    if [ ${#rows[@]} -eq 0 ]; then
        error "No shell with DXSBash configuration was found."
        return
    fi
    local sel
    sel=$(Z --list --radiolist --width=520 --height=300 \
        --text="<b>Default login shell</b>\nOnly shells with DXSBash configured are listed.\n<small>To add another shell run: setup.sh --install --shell zsh|fish</small>" \
        --column="" --column="Shell" --column="Path" --print-column=3 "${rows[@]}") || return
    [ -n "$sel" ] || return
    [ "$(basename "$sel")" = "$cur" ] && return

    local log
    log=$(mktemp)
    if SUDO_ASKPASS="$DXSBASH_DIR/gui-askpass.sh" setsid -w sudo -A chsh -s "$sel" "$ME" \
            </dev/null >"$log" 2>&1; then
        info "Login shell changed to <b>$(esc "$(basename "$sel")")</b>.\n\nLog out and back in (or open a new terminal) to use it."
    else
        error "<b>Could not change the login shell.</b>\n\n<tt>$(esc "$(tail -3 "$log")")</tt>"
    fi
    rm -f "$log"
}

#=================================================================
# Custom aliases editor
#=================================================================
_alias_form() { # $1 = existing name ('' for new)
    local old="$1" name cmd
    if [ -z "$old" ]; then
        local out
        out=$(Z --forms --width=560 \
            --text="<b>New alias</b>\nThe command is shell code, exactly as you would type it in a terminal." \
            --add-entry="Alias name" --add-entry="Command") || return 1
        name="${out%%|*}"
        cmd="${out#*|}"
    else
        name=$(Z --entry --width=520 --text="<b>Alias name</b>" --entry-text="$old") || return 1
        cmd=$(Z --entry --width=640 --text="<b>Command for $(esc "$name")</b>" \
            --entry-text="$(alias_get "$old")") || return 1
    fi
    name="${name//[[:space:]]/}"

    if ! alias_valid_name "$name"; then
        error "<b>Invalid alias name:</b> <tt>$(esc "$name")</tt>\n\nUse letters, digits, <tt>_ - .</tt> and start with a letter or <tt>_</tt>."
        return 1
    fi
    if [ -z "${cmd//[[:space:]]/}" ]; then
        error "The command cannot be empty."
        return 1
    fi
    # Shell syntax words (bash/zsh/fish) as alias names break the shell
    if alias_reserved "$name"; then
        error "<tt>$(esc "$name")</tt> is a shell keyword or core command and can't be used as an alias name."
        return 1
    fi
    # Warn when shadowing a builtin or a real program (not when editing in place)
    if [ "$name" != "$old" ] && [ "$(type -t "$name" 2>/dev/null)" = "builtin" ]; then
        ask "<tt>$(esc "$name")</tt> is a shell builtin.\n\nYour alias will replace it in interactive shells. Continue?" \
            --ok-label="Replace it" --cancel-label="Cancel" || return 1
    elif [ "$name" != "$old" ] && type -P "$name" >/dev/null 2>&1; then
        ask "<tt>$(esc "$name")</tt> is an existing command ($(esc "$(type -P "$name")")).\n\nYour alias will replace it in interactive shells. Continue?" \
            --ok-label="Replace it" --cancel-label="Cancel" || return 1
    elif [ "$name" != "$old" ] && [ -n "$(alias_get "$name")" ]; then
        ask "An alias named <tt>$(esc "$name")</tt> already exists. Overwrite it?" || return 1
    fi

    [ -n "$old" ] && [ "$old" != "$name" ] && alias_remove "$old"
    alias_set "$name" "$cmd"
    applied "Alias <tt><b>$(esc "$name")</b></tt> saved:\n<tt>$(esc "$cmd")</tt>"
}

ui_aliases() {
    while true; do
        local -a rows=("__add__" "➕  Add a new alias…" "")
        local name cmd
        while IFS=$'\t' read -r name cmd; do
            rows+=("$name" "$name" "$(cell "$cmd")")
        done < <(alias_list)

        local pick
        pick=$(Z --list --width=760 --height=520 \
            --text="<b>Custom aliases</b> — $(alias_count) defined\nWork in bash, zsh and fish. Select one to edit or delete it." \
            --column="key" --column="Alias" --column="Command" \
            --hide-column=1 --print-column=1 \
            --ok-label="Open" --cancel-label="Back" "${rows[@]}") || return
        [ -n "$pick" ] || continue

        if [ "$pick" = "__add__" ]; then
            _alias_form "" || true
            continue
        fi

        local body action rc
        body="$(alias_get "$pick")"
        action=$(ask "<b>Alias</b> <tt>$(esc "$pick")</tt>\n\n<tt>$(esc "$body")</tt>" \
            --ok-label="Edit" --cancel-label="Back" --extra-button="Delete")
        rc=$?
        if [ "$action" = "Delete" ]; then
            if ask "Delete the alias <tt><b>$(esc "$pick")</b></tt>?" --ok-label="Delete" --cancel-label="Keep"; then
                alias_remove "$pick"
            fi
        elif [ "$rc" -eq 0 ]; then
            _alias_form "$pick" || true
        fi
    done
}

#=================================================================
# Backup / restore, health check, benchmark, reset, about
#=================================================================
ui_export() {
    local dest
    dest=$(Z --file-selection --save \
        --filename="$HOME/dxsbash-backup-$(date +%Y%m%d).tar.gz" \
        --file-filter="DXSBash backup | *.tar.gz") || return
    [ -n "$dest" ] || return
    case "$dest" in *.tar.gz) ;; *) dest="$dest.tar.gz" ;; esac
    local log
    log=$(mktemp)
    if bash "$DXSBASH_DIR/export-import.sh" export "$dest" >"$log" 2>&1; then
        info "<b>Settings backed up to:</b>\n<tt>$(esc "$dest")</tt>\n\nIncludes your preferences, prompt theme and custom aliases."
    else
        error "<b>Backup failed.</b>\n\n<tt>$(esc "$(strip_ansi <"$log" | tail -3)")</tt>"
    fi
    rm -f "$log"
}

ui_import() {
    local src
    src=$(Z --file-selection --file-filter="DXSBash backup | *.tar.gz") || return
    [ -n "$src" ] || return
    ask "Restore settings from\n<tt>$(esc "$src")</tt>?\n\nYour current preferences, theme and custom aliases will be replaced." \
        --ok-label="Restore" --cancel-label="Cancel" || return
    local log
    log=$(mktemp)
    if bash "$DXSBASH_DIR/export-import.sh" import --yes "$src" >"$log" 2>&1; then
        alias_sync_fish
        applied "<b>Settings restored.</b>"
    else
        error "<b>Restore failed.</b>\n\n<tt>$(esc "$(strip_ansi <"$log" | tail -3)")</tt>"
    fi
    rm -f "$log"
}

ui_doctor() {
    local log
    log=$(mktemp)
    run_with_progress "Checking your DXSBash installation…" "$log" \
        bash "$DXSBASH_DIR/doctor.sh" --no-color
    strip_ansi <"$log" >"$log.txt"
    show_log "health check" "$log.txt"
    rm -f "$log" "$log.txt"
}

ui_bench() {
    local log
    log=$(mktemp)
    run_with_progress "Timing shell startup (5 runs per shell)…" "$log" \
        bash "$DXSBASH_DIR/bench.sh" --runs 5
    strip_ansi <"$log" >"$log.txt"
    show_log "startup benchmark" "$log.txt"
    rm -f "$log" "$log.txt"
}

ui_reset() {
    ask "<b>Reset all DXSBash settings to their defaults?</b>\n\nEditor: $DEF_EDITOR · History: $DEF_HISTSIZE / $DEF_HISTFILESIZE\nTheme: $(esc "$(starship_theme_display_name "$DEF_STARSHIP_THEME")") · Prompt: Starship\nSystem info: $(onoff "$DEF_FASTFETCH") · Security summary: $(onoff "$DEF_SECSUMMARY") · SSH-lite: $(onoff "$DEF_SSH_LITE")\nUpdates: $DEF_UPDATE_CHANNEL channel, notifications $(onoff "$DEF_UPDATE_NOTIFY") · Terminal colors: $(onoff "$DEF_TERM_COLORS")\n\n<small>Custom aliases are not touched.</small>" \
        --ok-label="Reset" --cancel-label="Cancel" || return
    reset_settings_to_defaults
    link_starship_theme "$DEF_STARSHIP_THEME" || true
    save_settings || return
    apply_terminal_colors >/dev/null || true
    applied "All settings reset to defaults.$(backup_note)"
}

ui_about() {
    info "<big><b>DXSBash $(esc "$(version)")</b></big>\nProfessional shell environment for Linux power users.\nBash · Zsh · Fish — made in Canada.\n\n<a href=\"https://dxsbash.digitalxs.ca\">dxsbash.digitalxs.ca</a>\n<a href=\"https://github.com/digitalxs/dxsbash\">github.com/digitalxs/dxsbash</a>\n\n<small>© DigitalXS.ca — GPL-3.0</small>"
}

#=================================================================
# Main window
#=================================================================
main_menu() {
    while true; do
        load_settings
        local engine opts
        [ "$CUR_PROMPT_STYLE" = "custom" ] && engine="Built-in" || engine="Starship"
        opts="Info $(onoff "$CUR_FASTFETCH") · Security $(onoff "$CUR_SECSUMMARY") · SSH-lite $(onoff "$CUR_SSH_LITE") · Colors $(onoff "$CUR_TERM_COLORS")"

        local choice
        choice=$(Z --list --width=680 --height=650 \
            --text="<big><b>DXSBash</b></big>  <small>v$(esc "$(version)")</small>\nYour shell environment, configured.  Double-click a setting to change it." \
            --column="key" --column="Setting" --column="Current" \
            --hide-column=1 --print-column=1 \
            --ok-label="Open" --cancel-label="Close" \
            update  "🔄  Check for updates"          "v$(version)" \
            channel "📡  Update channel"             "$CUR_UPDATE_CHANNEL · notifications $(onoff "$CUR_UPDATE_NOTIFY")" \
            themes  "🎨  Prompt theme"               "$(starship_theme_display_name "$CUR_STARSHIP_THEME")" \
            engine  "💻  Prompt engine"              "$engine" \
            aliases "🔖  Custom aliases"             "$(alias_count) defined" \
            options "🧩  Startup & behavior"          "$opts" \
            editor  "📝  Default text editor"        "$(cell "$CUR_EDITOR")" \
            history "🕘  Shell history size"         "$(hist_label "$CUR_HISTSIZE") / $(hist_label "$CUR_HISTFILESIZE")" \
            shell   "🐚  Default login shell"        "$(current_login_shell)" \
            export  "💾  Back up settings"           "export to a file" \
            import  "📂  Restore settings"           "import a backup" \
            doctor  "🩺  Health check"               "diagnose problems" \
            bench   "🚀  Startup speed test"         "benchmark shells" \
            reset   "🧹  Reset to defaults"          "" \
            about   "📘  About DXSBash"              "") || break

        case "$choice" in
            update)  ui_update ;;
            channel) ui_update_channel ;;
            themes)  ui_themes ;;
            engine)  ui_prompt_engine ;;
            aliases) ui_aliases ;;
            options) ui_options ;;
            editor)  ui_editor ;;
            history) ui_history ;;
            shell)   ui_login_shell ;;
            export)  ui_export ;;
            import)  ui_import ;;
            doctor)  ui_doctor ;;
            bench)   ui_bench ;;
            reset)   ui_reset ;;
            about)   ui_about ;;
            *)       break ;;
        esac
    done
}

#=================================================================
# Self-test (no display needed) — run by CI
#=================================================================
# shellcheck disable=SC2034  # overrides globals consumed by settings-lib.sh
selftest() {
    local tmp fails=0
    DXS_SELFTEST=1
    tmp=$(mktemp -d)
    HOME="$tmp"
    # Redirect every settings path into the sandbox (these globals are
    # read by settings-lib.sh — see the SC2034 note on the function)
    CONF_DIR="$tmp/.dxsbash"; CONF_FILE="$CONF_DIR/user.conf"; CONF_FISH_FILE="$CONF_DIR/user.fish"
    ALIAS_FILE="$CONF_DIR/custom-aliases.sh"; ALIAS_FISH_FILE="$CONF_DIR/custom-aliases.fish"
    STARSHIP_LINK="$tmp/.config/starship.toml"
    DATA_HOME="$tmp/.local/share"
    DESKTOP_FILE="$DATA_HOME/applications/dxsbash-settings.desktop"
    ICON_HICOLOR="$DATA_HOME/icons/hicolor"
    SYSTEMD_USER_DIR="$tmp/.config/systemd/user"
    USER_THEMES_DIR="$CONF_DIR/themes"
    KONSOLE_DIR="$tmp/.local/share/konsole"; KONSOLE_PROFILE="$KONSOLE_DIR/DXSBash.profile"

    t() { if eval "$2" >/dev/null 2>&1; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails+1)); fi; }

    load_settings
    t "defaults load"            '[ "$CUR_EDITOR" = "$DEF_EDITOR" ] && [ "$CUR_SSH_LITE" = true ]'
    CUR_EDITOR=vim; CUR_SSH_LITE=false; write_settings selftest; load_settings
    t "settings round-trip"      '[ "$CUR_EDITOR" = vim ] && [ "$CUR_SSH_LITE" = false ]'
    t "fish twin written"        'grep -q "set -gx DXSBASH_SSH_LITE \"false\"" "$CONF_FISH_FILE"'
    t "user.conf is valid sh"    'bash -n "$CONF_FILE"'

    t "theme registry files exist" 'for e in "${STARSHIP_THEMES[@]}"; do [ -f "$STARSHIP_THEMES_DIR/$(theme_field "$e" 2)" ] || exit 1; done'
    link_starship_theme tokyo-night.toml; load_settings
    t "theme link detected"      '[ "$CUR_STARSHIP_THEME" = tokyo-night.toml ]'
    t "unknown theme refused"    '! link_starship_theme does-not-exist.toml'

    alias_set gs2 "git status --short"
    alias_set say "echo \"it's here\""
    alias_set bs 'printf "%s\n" a\\b'
    t "alias count"              '[ "$(alias_count)" = 3 ]'
    t "alias get unescapes"      '[ "$(alias_get say)" = "echo \"it'"'"'s here\"" ]'
    t "alias file is valid sh"   'bash -n "$ALIAS_FILE"'
    t "bash expands alias"       '[ "$(printf "source %q\nsay\n" "$ALIAS_FILE" | bash -O expand_aliases)" = "it'"'"'s here" ]'
    if command -v fish >/dev/null 2>&1; then
        t "fish expands alias"   '[ "$(printf "source %q\nsay\nbs\n" "$ALIAS_FISH_FILE" | fish)" = "$(printf "it'"'"'s here\na\\\\b")" ]'
    fi
    alias_set gs2 "git status"
    t "overwrite dedupes"        '[ "$(alias_count)" = 3 ] && [ "$(alias_get gs2)" = "git status" ]'
    alias_remove gs2
    t "remove"                   '[ "$(alias_count)" = 2 ] && [ -z "$(alias_get gs2)" ]'
    t "fish twin follows remove" '! grep -q "alias gs2" "$ALIAS_FISH_FILE"'
    t "name validation"          'alias_valid_name ok_name-1.x && ! alias_valid_name "bad name" && ! alias_valid_name "x;rm"'
    t "reserved words refused"   'alias_reserved if && alias_reserved end && alias_reserved export && ! alias_reserved ifconfig && ! alias_set for "echo x"'
    t "markup + backslash escape" '[ "$(esc "a\\b<&>")" = "a\\\\b&lt;&amp;&gt;" ]'
    t "hand-written alias read"  'echo "alias hw=\"ls -l\"" >> "$ALIAS_FILE" && [ "$(alias_get hw)" = "ls -l" ]'

    t "markup escaping"          '[ "$(esc "a<b>&c")" = "a&lt;b&gt;&amp;c" ]'

    # --- 3.9.0: settings keys, user themes, terminal colors, update check
    CUR_UPDATE_CHANNEL=main; CUR_UPDATE_NOTIFY=false; CUR_TERM_COLORS=false
    write_settings selftest; load_settings
    t "new keys round-trip"      '[ "$CUR_UPDATE_CHANNEL" = main ] && [ "$CUR_UPDATE_NOTIFY" = false ] && [ "$CUR_TERM_COLORS" = false ]'
    sed -i 's/^export DXSBASH_UPDATE_CHANNEL=.*/export DXSBASH_UPDATE_CHANNEL="nightly"/' "$CONF_FILE"; load_settings
    t "bad channel -> stable"    '[ "$CUR_UPDATE_CHANNEL" = stable ]'

    printf 'format = "$directory$character"\n' > "$tmp/my-prompt.toml"
    t "user theme import"        '[ "$(import_user_theme "$tmp/my-prompt.toml")" = user/my-prompt.toml ]'
    t "user theme listed"        'theme_entries | grep -q "^my-prompt (yours)|user/my-prompt.toml|"'
    link_starship_theme user/my-prompt.toml; load_settings
    t "user theme link detected" '[ "$CUR_STARSHIP_THEME" = user/my-prompt.toml ] && [ "$(readlink "$STARSHIP_LINK")" = "$USER_THEMES_DIR/my-prompt.toml" ]'
    printf 'x' > "$tmp/bad name.toml"
    t "unsafe theme name refused" '! import_user_theme "$tmp/bad name.toml" 2>/dev/null'
    : > "$USER_THEMES_DIR/bad|name.toml"; : > "$USER_THEMES_DIR/cash\$.toml"
    t "unsafe hand-dropped names hidden" '! theme_entries | grep -q "bad\|cash" && [ "$(theme_entries | grep -c "(yours)")" = 1 ]'
    rm -f "$USER_THEMES_DIR/bad|name.toml" "$USER_THEMES_DIR/cash\$.toml"
    t "re-adding own file works" '[ "$(import_user_theme "$USER_THEMES_DIR/my-prompt.toml")" = user/my-prompt.toml ]'
    if command -v starship >/dev/null 2>&1; then
        printf '[character\nbroken =\n' > "$tmp/broken.toml"
        t "broken toml refused"  '! import_user_theme "$tmp/broken.toml" 2>/dev/null && [ ! -f "$USER_THEMES_DIR/broken.toml" ]'
    fi

    mkdir -p "$KONSOLE_DIR"
    printf '[Appearance]\nColorScheme=Breeze\nFont=FiraCode Nerd Font,12\n\n[General]\nName=DXSBash\n' > "$KONSOLE_PROFILE"
    CUR_TERM_COLORS=true
    t "colors applied"           '[ "$(apply_terminal_colors tokyo-night.toml)" = DXSBash-TokyoNight ] && grep -qx "ColorScheme=DXSBash-TokyoNight" "$KONSOLE_PROFILE"'
    t "profile keys preserved"   'grep -qx "Font=FiraCode Nerd Font,12" "$KONSOLE_PROFILE" && grep -qx "Name=DXSBash" "$KONSOLE_PROFILE" && [ "$(grep -c "^ColorScheme=" "$KONSOLE_PROFILE")" = 1 ]'
    t "schemes installed"        '[ -f "$KONSOLE_DIR/DXSBash-Gruvbox.colorscheme" ] && [ -f "$KONSOLE_DIR/DXSBash.colorscheme" ]'
    t "user theme keeps colors"  '! apply_terminal_colors user/my-prompt.toml && grep -qx "ColorScheme=DXSBash-TokyoNight" "$KONSOLE_PROFILE"'
    CUR_TERM_COLORS=false
    t "colors off = untouched"   '! apply_terminal_colors gruvbox-rainbow.toml && grep -qx "ColorScheme=DXSBash-TokyoNight" "$KONSOLE_PROFILE"'
    printf '[General]\nName=x\n' > "$tmp/ini"; _ini_set "$tmp/ini" Appearance ColorScheme Y
    printf '[Appearance]\r\nColorScheme=Breeze\r\n' > "$tmp/crlf"; _ini_set "$tmp/crlf" Appearance ColorScheme Z
    t "ini CRLF header reused"   '[ "$(grep -c Appearance "$tmp/crlf")" = 1 ] && grep -q "^ColorScheme=Z" "$tmp/crlf" && ! grep -q Breeze "$tmp/crlf"'
    t "ini group created"        '[ "$(sed -n "/^\[Appearance\]/,\$p" "$tmp/ini" | tail -1)" = ColorScheme=Y ] && grep -qx "Name=x" "$tmp/ini"'

    # update notifier with a fake updater and a fake notify-send
    mkdir -p "$tmp/bin"
    printf '#!/bin/sh\necho "Update available: 3.8.0 -> 3.9.0 (stable channel)"; exit 10\n' > "$tmp/fake-updater"
    printf '#!/bin/sh\ncase "$1" in --help) echo "  --action=[NAME=]Text"; exit 0;; esac\necho "$*" >> "%s/notified.log"\necho later\n' "$tmp" > "$tmp/bin/notify-send"
    chmod +x "$tmp/fake-updater" "$tmp/bin/notify-send"
    CUR_UPDATE_NOTIFY=true; write_settings selftest
    # fake display so the actionable path is used; DISPLAY= tests the other
    _notify() { HOME="$tmp" PATH="$tmp/bin:$PATH" DXSBASH_UPDATER_CMD="$tmp/fake-updater" DISPLAY="${_ND-:0}" bash "$DXSBASH_DIR/update-notify.sh" >/dev/null; }
    _notify; _notify
    t "notifies once per version" '[ "$(grep -c "DXSBash 3.9.0 is available" "$tmp/notified.log")" = 1 ] && grep -q "3.8.0 -> 3.9.0" "$CONF_DIR/update-notified"'
    t "notification has action"  'grep -q "update=Update now" "$tmp/notified.log"'
    rm -f "$tmp/notified.log" "$CONF_DIR/update-notified"
    _ND="" _notify
    t "no display = plain text"  '[ -f "$tmp/notified.log" ] && ! grep -q -- "--action" "$tmp/notified.log" && grep -q "run update-dxsbash" "$tmp/notified.log"'
    rm -f "$tmp/notified.log" "$CONF_DIR/update-notified"
    CUR_UPDATE_NOTIFY=false; write_settings selftest; _notify
    t "notify off = silent"      '[ ! -f "$tmp/notified.log" ]'
    CUR_UPDATE_NOTIFY=true; write_settings selftest
    printf '#!/bin/sh\ncase "$1" in --help) echo "  --action"; exit 0;; esac\nexit 1\n' > "$tmp/bin/notify-send"
    _notify
    t "failed notify not marked" '[ ! -f "$CONF_DIR/update-notified" ]'
    printf '#!/bin/sh\necho "DXSBash is up to date"; exit 0\n' > "$tmp/fake-updater"; _notify
    t "up to date = silent"      '[ ! -f "$tmp/notified.log" ] || { cat "$tmp/notified.log" >&2; false; }'
    t "dash-leading list cells"  '[ "$(cell -la)" = "$(printf "\u200b-la")" ] && [ "$(cell ls)" = ls ]'
    t "unlimited history label"  '[ "$(hist_label -1)" = unlimited ] && [ "$(hist_label 500)" = 500 ]'
    t "canonical alias parsing"  'printf "%s\n" "alias cc='"'"'ls'"'"'  # note" "alias dq=\"echo \\\$HOME\"" >> "$ALIAS_FILE" && [ "$(alias_get cc)" = ls ] && [ "$(alias_get dq)" = "echo \$HOME" ]'
    install_desktop >/dev/null
    t "desktop entry installed"  '[ -f "$DESKTOP_FILE" ]'
    if command -v systemctl >/dev/null 2>&1; then
        t "update timer installed" '[ -f "$SYSTEMD_USER_DIR/$UPDATE_TIMER" ] && [ -f "$SYSTEMD_USER_DIR/$UPDATE_SERVICE" ] && [ -L "$SYSTEMD_USER_DIR/timers.target.wants/$UPDATE_TIMER" ]'
    fi
    t "icon set installed"       '[ -f "$ICON_HICOLOR/scalable/apps/dxsbash.svg" ] && [ -f "$ICON_HICOLOR/48x48/apps/dxsbash.png" ] && [ -f "$ICON_HICOLOR/256x256/apps/dxsbash.png" ]'
    t "no placeholders left"     '! grep -q "@GUI@" "$DESKTOP_FILE"'
    t "System category"          'grep -qx "Categories=System;" "$DESKTOP_FILE"'
    if command -v desktop-file-validate >/dev/null 2>&1; then
        t "desktop-file-validate" 'desktop-file-validate "$DESKTOP_FILE"'
    fi
    remove_desktop >/dev/null
    t "update timer removed"     '[ ! -e "$SYSTEMD_USER_DIR/$UPDATE_TIMER" ] && [ ! -e "$SYSTEMD_USER_DIR/timers.target.wants/$UPDATE_TIMER" ]'
    t "desktop entry removed"    '[ ! -f "$DESKTOP_FILE" ] && [ -z "$(find "$ICON_HICOLOR" -name "dxsbash.*" 2>/dev/null)" ]'

    rm -rf "$tmp"
    echo ""
    if [ "$fails" -eq 0 ]; then
        echo "dxsbash-gui selftest: all checks passed"
    else
        echo "dxsbash-gui selftest: $fails check(s) FAILED"
    fi
    [ "$fails" -eq 0 ]
}

#=================================================================
# Entry point
#=================================================================
case "${1:-}" in
    --selftest)        selftest; exit $? ;;
    --install-desktop) install_desktop; exit $? ;;
    --remove-desktop)  remove_desktop; exit $? ;;
    --sync-aliases)    alias_sync_fish; exit $? ;;
    --apply-colors)    load_settings; apply_terminal_colors >/dev/null; exit 0 ;;
    -h|--help)         sed -n '/^# Usage:/,/^# All settings/p' "$SELF" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
esac

mkdir -p "$(dirname "$GUI_LOG")" 2>/dev/null && : >"$GUI_LOG" 2>/dev/null || GUI_LOG=/dev/null
require_zenity
load_settings
# Keep the fish copy of custom aliases in step with hand edits (and
# remove it if custom-aliases.sh was deleted)
alias_sync_fish

case "${1:-}" in
    --update)  ui_update ;;
    --themes)  ui_themes ;;
    --aliases) ui_aliases ;;
    *)         main_menu ;;
esac
