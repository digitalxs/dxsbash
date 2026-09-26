#!/bin/bash
# dxsbash-utils.sh - Shared utilities for dxsbash scripts
# UNDER DEVELOPMENT

# Logging function (silent, doesn't echo to console)
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_file="$HOME/.dxsbash/logs/dxsbash.log"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Format the log message
    local formatted_log="[$timestamp] [$level] $message"
    
    # Append to log file
    echo "$formatted_log" >> "$log_file"
}

# Log rotation function
rotate_logs() {
    local log_dir="$HOME/.dxsbash/logs"
    local main_log="$log_dir/dxsbash.log"
    local max_size=1048576  # 1MB
    
    # Check if log exists and is larger than max size
    if [ -f "$main_log" ] && [ "$(stat -c %s "$main_log")" -gt "$max_size" ]; then
        local timestamp
        timestamp=$(date "+%Y%m%d_%H%M%S")
        mv "$main_log" "$log_dir/dxsbash_$timestamp.log"
        # Keep only the 5 most recent log files
        ls -t "$log_dir"/dxsbash_*.log | tail -n +6 | xargs rm -f 2>/dev/null
    fi
}

#######################################################
# SHARED INTERACTIVE HELPERS (bash + zsh)
#
# Sourced by both .bashrc and .zshrc, so these must stay portable
# across the two shells (no bashisms zsh lacks, no ${=...} zsh-isms;
# use arrays where word-splitting behavior differs). Fish has its own
# implementations in config.fish.
#######################################################

# Offline cheatsheet over the DXSBash command reference (commands.md),
# rendered with bat when available.
# Usage: cheat              # browse the whole reference
#        cheat git         # only lines mentioning git
cheat() {
    local doc="$HOME/linuxtoolbox/dxsbash/commands.md"
    if [ ! -f "$doc" ]; then
        echo "cheat: $doc not found (is DXSBash installed?)" >&2
        return 1
    fi
    # Array, not a string: bash word-splits unquoted strings, zsh does
    # not — expanding an array works identically in both.
    local -a renderer
    if command -v bat >/dev/null 2>&1; then
        renderer=(bat --language=md --style=plain --paging=auto)
    elif command -v batcat >/dev/null 2>&1; then
        renderer=(batcat --language=md --style=plain --paging=auto)
    else
        renderer=(cat)
    fi
    if [ $# -eq 0 ]; then
        "${renderer[@]}" "$doc"
    else
        grep -i --color=never -- "$*" "$doc" | "${renderer[@]}"
    fi
}

#######################################################
# PER-DIRECTORY ENVIRONMENTS (.dxsbash-env)
#######################################################
# A .dxsbash-env file in a directory is sourced automatically when you
# cd there — but only after you trust that exact file once with
# 'envallow'. Trust is bound to the file's content hash: if the file
# changes, it will not load again until you re-run envallow. Use
# 'envdeny' to withdraw trust. Loaded settings persist for the rest of
# the shell session (there is no unload on leaving the directory).
#
# Allowlist format: '<sha256>  <absolute path>' per line. The path is
# everything after the first 'hash  ' prefix, so paths containing
# consecutive spaces revoke correctly too.

__dxs_env_hash() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }

# Remove any allowlist entry for path $1 (in-place rewrite)
__dxs_env_forget() {
    local allow="$HOME/.dxsbash/env-allow"
    [ -f "$allow" ] || return 0
    awk -v p="$1" '{ line=$0; sub(/^[^ ]+  /, "", line); if (line != p) print }' \
        "$allow" > "$allow.tmp" && mv "$allow.tmp" "$allow"
}

__dxs_env_check() {
    [ "$PWD" = "${__DXS_ENV_LAST_PWD:-}" ] && return 0
    __DXS_ENV_LAST_PWD="$PWD"
    local f="$PWD/.dxsbash-env" allow="$HOME/.dxsbash/env-allow" h
    [ -f "$f" ] || return 0
    h=$(__dxs_env_hash "$f")
    if [ -f "$allow" ] && grep -qxF "$h  $PWD" "$allow"; then
        # shellcheck source=/dev/null
        source "$f"
    else
        echo "dxsbash: found .dxsbash-env — run 'envallow' to trust and load it (or 'envdeny' to forget)"
    fi
}

envallow() {
    local f="$PWD/.dxsbash-env" allow="$HOME/.dxsbash/env-allow" h
    if [ ! -f "$f" ]; then
        echo "envallow: no .dxsbash-env in $PWD" >&2
        return 1
    fi
    mkdir -p "$HOME/.dxsbash"
    touch "$allow"
    h=$(__dxs_env_hash "$f")
    __dxs_env_forget "$PWD"
    printf '%s  %s\n' "$h" "$PWD" >> "$allow"
    # shellcheck source=/dev/null
    source "$f"
    echo "envallow: trusted and loaded $f"
}

envdeny() {
    __dxs_env_forget "$PWD"
    echo "envdeny: $PWD is no longer trusted"
}

# Pick the lightweight ssh-lite Starship preset inside SSH sessions,
# and heal a stale inherited value outside them. Called by the rc
# files just before 'starship init'.
__dxs_ssh_lite_starship() {
    local lite="$HOME/linuxtoolbox/dxsbash/starship-themes/ssh-lite.toml"
    case "${STARSHIP_CONFIG:-}" in
        */starship-themes/ssh-lite.toml)
            # Inherited from a parent shell: drop it when this shell is
            # not an SSH session (e.g. local terminal under tmux started
            # over SSH) or when the path is unreadable (su to another
            # user whose HOME differs).
            if [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] || \
               [ ! -r "$STARSHIP_CONFIG" ]; then
                unset STARSHIP_CONFIG
            fi
            ;;
    esac
    if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] && \
       [ "${DXSBASH_SSH_LITE:-true}" = "true" ] && \
       [ -z "${STARSHIP_CONFIG:-}" ] && [ -f "$lite" ]; then
        export STARSHIP_CONFIG="$lite"
    fi
}
