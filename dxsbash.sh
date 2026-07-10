#!/bin/bash
#=================================================================
# DXSBash umbrella command
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Single entry point for all DXSBash management tasks. Installed as
# /usr/local/bin/dxsbash (a symlink to this file inside the repo).
# The individual commands (update-dxsbash, dxsbash-config, …) keep
# working — this is a convenience wrapper, not a replacement.
#
# Usage:
#   dxsbash update [--check]   Update DXSBash (or just check for updates)
#   dxsbash config             Interactive configuration menu
#   dxsbash doctor [args]      Health-check the installation
#   dxsbash audit [args]       Security audit of the system (read-only)
#   dxsbash repair [args]      Re-create symlinks and helper commands
#   dxsbash uninstall [args]   Remove DXSBash and restore defaults
#   dxsbash version            Print the installed version
#   dxsbash help               Show this help
#=================================================================

set -u

# Resolve the repo directory this script really lives in, following
# the /usr/local/bin/dxsbash symlink.
DXS_DIR="$(dirname "$(readlink -f "$0")")"

usage() {
    cat <<'USAGE'
dxsbash — enhanced shell environment manager

Usage: dxsbash <command> [options]

Commands:
  update      Update DXSBash to the latest release
              (use 'dxsbash update --check' to only check)
  config      Interactive configuration menu (editor, prompt, themes)
  doctor      Health-check the installation (read-only)
  audit       Security audit of the system (read-only)
              (run 'sudo dxsbash audit' for full coverage)
  repair      Re-create broken symlinks and helper commands
  uninstall   Remove DXSBash and restore system defaults
  version     Print the installed version
  help        Show this help

Extra options are passed through to the underlying script,
e.g.:  dxsbash doctor --verbose
       dxsbash audit --verbose
       dxsbash repair --dry-run
USAGE
}

run_script() {
    local script="$DXS_DIR/$1"
    shift
    if [ ! -f "$script" ]; then
        echo "Error: $script not found. Is DXSBash installed correctly?" >&2
        echo "Try reinstalling: https://github.com/digitalxs/dxsbash" >&2
        exit 1
    fi
    exec bash "$script" "$@"
}

CMD="${1:-help}"
[ $# -gt 0 ] && shift

case "$CMD" in
    update)              run_script updater.sh "$@" ;;
    config)              run_script dxsbash-config.sh "$@" ;;
    doctor)              run_script doctor.sh "$@" ;;
    audit)               run_script secaudit.sh "$@" ;;
    secsummary)          run_script secsummary.sh "$@" ;;
    repair)              run_script repair.sh "$@" ;;
    uninstall)           run_script uninstall.sh "$@" ;;
    version|-v|--version)
        if [ -f "$DXS_DIR/version.txt" ]; then
            cat "$DXS_DIR/version.txt"
        else
            echo "unknown"
        fi
        ;;
    help|-h|--help)      usage ;;
    *)
        echo "Unknown command: $CMD" >&2
        echo "" >&2
        usage >&2
        exit 2
        ;;
esac
