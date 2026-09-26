#!/bin/bash
#=================================================================
# DXSBash update notifier
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Run once a day by the systemd user timer dxsbash-update-check.timer
# (installed with the desktop menu entry). When update-dxsbash --check
# reports a new release on the user's channel, shows one desktop
# notification per new version, with an "Update now" button that
# opens the DXSBash Settings update screen.
#
# Silent by design: no notification when up to date, offline, when the
# setting is off (DXSBASH_UPDATE_NOTIFY="false"), or for a version the
# user was already told about.
#
# Usage: update-notify.sh [--force]   (--force: ignore "already told")
#=================================================================

set -u

SELF="$(readlink -f "$0")"
DXSBASH_DIR="${DXSBASH_DIR:-$(dirname "$SELF")}"
# shellcheck source=settings-lib.sh
source "$DXSBASH_DIR/settings-lib.sh" || exit 0

STATE_FILE="$CONF_DIR/update-notified"
# Test hook: lets the self-test substitute a fake updater
UPDATER="${DXSBASH_UPDATER_CMD:-$DXSBASH_DIR/updater.sh}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

load_settings
[ "$CUR_UPDATE_NOTIFY" = "true" ] || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0

out=$(bash "$UPDATER" --check 2>/dev/null)
[ $? -eq 10 ] || exit 0

# "Update available: 3.8.0 -> 3.9.0 (stable channel)"
current="" latest=""
if [[ "$out" =~ ([0-9][0-9.]*|unknown)\ -\>\ ([0-9][0-9.]*) ]]; then
    current="${BASH_REMATCH[1]}"; latest="${BASH_REMATCH[2]}"
fi
[ -n "$latest" ] || exit 0

# One notification per version
if [ "$FORCE" -eq 0 ] && [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "$latest" ]; then
    exit 0
fi
title="DXSBash $latest is available"
body="You have $current. Your settings, theme and aliases are kept when you update."
icon="dxsbash"
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/48x48/apps/dxsbash.png" ] || icon="system-software-update"

# Remember the version only once a notification was really shown: with
# no desktop session (e.g. an SSH-only login) notify-send fails, and the
# user must still be told at the next graphical login.
mark_notified() {
    mkdir -p "$CONF_DIR" && printf '%s\n' "$latest" > "$STATE_FILE"
}

# libnotify >= 0.7.10 has clickable actions; older ones get plain text
if notify-send --help 2>&1 | grep -q -- '--action'; then
    # --action waits for a click (or the notification expiring).
    # "default" is what clicking the notification body does.
    choice=$(timeout 6h notify-send --app-name="DXSBash" --icon="$icon" \
        --action=default="Open DXSBash Settings" \
        --action=update="Update now" --action=later="Later" \
        "$title" "$body" 2>/dev/null) || exit 0
    mark_notified
    if [ "$choice" = "update" ] || [ "$choice" = "default" ]; then
        setsid bash "$DXSBASH_DIR/dxsbash-gui.sh" --update >/dev/null 2>&1 < /dev/null &
    fi
else
    notify-send --app-name="DXSBash" --icon="$icon" "$title" \
        "$body Open DXSBash Settings (System menu) or run update-dxsbash." 2>/dev/null \
        && mark_notified
fi
exit 0
