#!/bin/bash
#=================================================================
# DXSBash Security Summary — a one-line security status shown at
# login next to fastfetch.
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Startup must stay instant, so the line is read from a cache file
# and only recomputed in the background when stale. Nothing here
# changes system state.
#
# Usage:
#   secsummary.sh --startup   print cached line, refresh in background
#                             if stale (used by the shell rc files)
#   secsummary.sh --refresh   recompute the cache now (foreground)
#   secsummary.sh --show      print the cached line and exit
#   secsummary.sh -h|--help   show help
#=================================================================

set -u

CACHE_DIR="$HOME/.dxsbash"
CACHE_FILE="$CACHE_DIR/security-summary.txt"
# Consider the cache stale after this many seconds (default 1 hour).
MAX_AGE="${DXSBASH_SECSUMMARY_MAXAGE:-3600}"

command_exists() { command -v "$1" >/dev/null 2>&1; }

#=================================================================
# Compute the summary line and write it to the cache atomically.
# Each segment is only added when it has something worth saying, so
# a healthy system shows a short green line rather than noise.
#=================================================================
refresh_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || return 1

    local RC='\033[0m' RED='\033[1;31m' YELLOW='\033[1;33m'
    local GREEN='\033[1;32m' CYAN='\033[1;36m'
    local segments=() problems=0

    # Pending security updates (Debian/Ubuntu)
    if command_exists apt; then
        local sec
        sec=$(apt list --upgradable 2>/dev/null | grep -ci -- "-security")
        if [ "${sec:-0}" -gt 0 ]; then
            segments+=("${RED}${sec} security update(s)${RC}")
            problems=$((problems + 1))
        fi
    fi

    # Failed SSH logins in the last 24h (needs journal/auth.log access)
    local failed=""
    if [ -r /var/log/auth.log ]; then
        failed=$(grep -a "Failed password" /var/log/auth.log 2>/dev/null | grep -c .)
    elif command_exists journalctl && journalctl -q --system -n 1 >/dev/null 2>&1; then
        failed=$(journalctl -q --system --since "24 hours ago" --no-pager 2>/dev/null \
                 | grep -a "Failed password" | grep -c .)
    fi
    if [ -n "$failed" ] && [ "$failed" -gt 0 ]; then
        segments+=("${YELLOW}${failed} failed SSH login(s)${RC}")
        problems=$((problems + 1))
    fi

    # Firewall inactive?
    if command_exists systemctl; then
        if ! systemctl is-active --quiet ufw 2>/dev/null \
           && ! systemctl is-active --quiet nftables 2>/dev/null \
           && ! systemctl is-active --quiet firewalld 2>/dev/null; then
            segments+=("${YELLOW}firewall off${RC}")
            problems=$((problems + 1))
        fi
    fi

    # Reboot required (kernel/library update)
    if [ -f /var/run/reboot-required ]; then
        segments+=("${YELLOW}reboot required${RC}")
        problems=$((problems + 1))
    fi

    local line
    if [ "$problems" -eq 0 ]; then
        line="${CYAN}Security:${RC} ${GREEN}✓ no issues detected${RC}"
    else
        local joined=""
        local s
        for s in "${segments[@]}"; do
            [ -n "$joined" ] && joined="${joined}${CYAN} · ${RC}"
            joined="${joined}${s}"
        done
        line="${CYAN}Security:${RC} ${joined}${CYAN} · run 'dxsbash audit'${RC}"
    fi

    # Atomic write so --startup never reads a half-written file
    printf '%b\n' "$line" > "$CACHE_FILE.tmp" 2>/dev/null && \
        mv -f "$CACHE_FILE.tmp" "$CACHE_FILE" 2>/dev/null
}

cache_is_stale() {
    [ -f "$CACHE_FILE" ] || return 0
    local now mtime age
    now=$(date +%s)
    mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$((now - mtime))
    [ "$age" -ge "$MAX_AGE" ]
}

show_cache() {
    [ -f "$CACHE_FILE" ] && cat "$CACHE_FILE"
}

case "${1:---startup}" in
    --startup)
        # Print whatever we have immediately (may be slightly stale),
        # then refresh in the background if needed so the next login
        # is current. The background job is fully detached.
        show_cache
        if cache_is_stale; then
            ( refresh_cache >/dev/null 2>&1 & ) &
            disown 2>/dev/null || true
        fi
        ;;
    --refresh)
        refresh_cache
        show_cache
        ;;
    --show)
        show_cache
        ;;
    -h|--help)
        sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 2
        ;;
esac
