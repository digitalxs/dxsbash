#!/bin/bash
#=================================================================
# DXSBash settings export/import
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Packs the personal DXSBash state — ~/.dxsbash (user.conf, trusted
# per-directory env allowlist, ...) plus the selected Starship theme —
# into a single tarball, and restores it on another machine.
#
# Usage:
#   dxsbash export [file.tar.gz]     default: ~/dxsbash-backup-YYYYMMDD.tar.gz
#   dxsbash import <file.tar.gz>
#
# Logs, caches and the security-summary snapshot are excluded: they
# are machine-specific and regenerate themselves.
#=================================================================

set -euo pipefail

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
CYAN='\033[36m'

MODE="${1:-}"
shift 2>/dev/null || true

CONF_DIR="$HOME/.dxsbash"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
DXSBASH_DIR="$HOME/linuxtoolbox/dxsbash"

# Staging dir shared with the EXIT trap — a function-local would be out
# of scope by the time the trap fires (unbound under set -u).
STAGE=""
trap '[ -n "$STAGE" ] && rm -rf "$STAGE"' EXIT

usage() {
    echo "Usage: dxsbash export [file.tar.gz]"
    echo "       dxsbash import [--yes] <file.tar.gz>"
}

do_export() {
    local out="${1:-$HOME/dxsbash-backup-$(date +%Y%m%d).tar.gz}"

    STAGE=$(mktemp -d)


    mkdir -p "$STAGE/payload"

    # ~/.dxsbash minus regenerable machine-local state
    if [ -d "$CONF_DIR" ]; then
        mkdir -p "$STAGE/payload/.dxsbash"
        local f base
        for f in "$CONF_DIR"/*; do
            [ -e "$f" ] || continue
            base=$(basename "$f")
            case "$base" in
                logs|*.cache|security-summary.txt|suid-baseline.txt) continue ;;
                # env-allow holds per-machine trust decisions for
                # .dxsbash-env files — transferring it would let a
                # shared backup pre-authorize code execution on the
                # importing machine. Never exported, never imported.
                env-allow) continue ;;
            esac
            cp -a "$f" "$STAGE/payload/.dxsbash/"
        done
    fi

    # Starship config: record whether it is a preset symlink (portable —
    # re-linked on import) or a custom file (copied verbatim).
    if [ -L "$STARSHIP_CONFIG" ]; then
        basename "$(readlink "$STARSHIP_CONFIG")" > "$STAGE/payload/starship-theme.txt"
    elif [ -f "$STARSHIP_CONFIG" ]; then
        cp "$STARSHIP_CONFIG" "$STAGE/payload/starship.toml"
    fi

    # Manifest for humans and for import sanity-checking
    {
        echo "dxsbash-backup-version: 1"
        echo "created: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "host: $(hostname 2>/dev/null || echo unknown)"
        echo "dxsbash: $(cat "$DXSBASH_DIR/version.txt" 2>/dev/null || echo unknown)"
    } > "$STAGE/payload/MANIFEST"

    tar -czf "$out" -C "$STAGE/payload" .
    echo -e "${GREEN}✓ Exported DXSBash settings to:${RC} $out"
    echo -e "  Restore on another machine with: ${CYAN}dxsbash import $(basename "$out")${RC}"
}

do_import() {
    local in="" assume_yes=0 arg
    for arg in "$@"; do
        case "$arg" in
            -y|--yes) assume_yes=1 ;;
            *) in="$arg" ;;
        esac
    done
    if [ -z "$in" ] || [ ! -f "$in" ]; then
        echo -e "${RED}✗ Backup file not found: ${in:-<none given>}${RC}" >&2
        usage >&2
        exit 1
    fi

    STAGE=$(mktemp -d)

    tar -xzf "$in" -C "$STAGE"

    if [ ! -f "$STAGE/MANIFEST" ]; then
        echo -e "${RED}✗ Not a DXSBash backup (missing MANIFEST)${RC}" >&2
        exit 1
    fi
    echo -e "${CYAN}Backup contents:${RC}"
    sed 's/^/  /' "$STAGE/MANIFEST"
    echo ""

    # Import overwrites current settings — never proceed silently: an
    # interactive user must confirm, a non-interactive caller (cron,
    # ssh command, piped stdin) must pass --yes explicitly.
    if [ "$assume_yes" -ne 1 ]; then
        if [ -t 0 ]; then
            read -r -p "Import these settings, overwriting current ones? (y/N): " ok
            [[ "$ok" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
        else
            echo -e "${RED}✗ Refusing to overwrite settings non-interactively without --yes${RC}" >&2
            exit 1
        fi
    fi

    if [ -d "$STAGE/.dxsbash" ]; then
        # Strip a trust allowlist from older backups — trust for
        # .dxsbash-env files is per-machine and must be re-granted
        # locally with envallow.
        rm -f "$STAGE/.dxsbash/env-allow"
        mkdir -p "$CONF_DIR"
        cp -a "$STAGE/.dxsbash/." "$CONF_DIR/"
        echo -e "${GREEN}✓ Restored ~/.dxsbash settings${RC} (per-machine env trust not transferred)"
    fi

    # Starship: prefer re-linking the named preset from this machine's
    # repo; fall back to the literal file if the preset is unknown here.
    mkdir -p "$HOME/.config"
    if [ -f "$STAGE/starship-theme.txt" ]; then
        local theme preset
        theme=$(cat "$STAGE/starship-theme.txt")
        if [ "$theme" = "starship.toml" ]; then
            preset="$DXSBASH_DIR/starship.toml"
        else
            preset="$DXSBASH_DIR/starship-themes/$theme"
        fi
        if [ -f "$preset" ]; then
            ln -sf "$preset" "$STARSHIP_CONFIG"
            echo -e "${GREEN}✓ Starship theme re-linked:${RC} $theme"
        else
            echo -e "${YELLOW}⚠ Theme '$theme' not found in this install; leaving prompt config unchanged${RC}"
        fi
    elif [ -f "$STAGE/starship.toml" ]; then
        cp "$STAGE/starship.toml" "$STARSHIP_CONFIG"
        echo -e "${GREEN}✓ Restored custom starship.toml${RC}"
    fi

    echo ""
    echo -e "${GREEN}Import complete.${RC} Open a new shell (or source your rc file) to apply."
}

case "$MODE" in
    export) do_export "$@" ;;
    import) do_import "$@" ;;
    *) usage >&2; exit 2 ;;
esac
