#!/bin/bash
#=================================================================
# DXSBash Security Audit — read-only security health check.
# Repository: https://github.com/digitalxs/dxsbash
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
# License: GPL-3.0
#
# Inspects the system the way doctor.sh inspects the installation:
# pending security updates, firewall state, SSH daemon hardening,
# accounts and sudo privileges, PATH hygiene, world-writable and
# SUID/SGID files, failed logins, and network exposure.
# It NEVER changes anything.
#
# Some checks need root; run 'sudo dxsbash audit' for full coverage.
#
# Exit status:
#   0  no FAIL checks (WARN/SKIP allowed)
#   1  at least one FAIL
#   2  bad usage
#
# Usage:
#   secaudit.sh                  run all checks
#   secaudit.sh -v | --verbose   include PASS details
#   secaudit.sh --no-color       disable ANSI colours
#   secaudit.sh -h | --help      show help
#=================================================================

set -u

VERBOSE=0
USE_COLOR=1

while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=1 ;;
        --no-color)   USE_COLOR=0 ;;
        -h|--help)
            sed -n '2,27p' "$0"
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
SKIP_COUNT=0

IS_ROOT=0
[ "$(id -u)" -eq 0 ] && IS_ROOT=1

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

skip() {
    SKIP_COUNT=$((SKIP_COUNT + 1))
    printf "  ${CYAN}[SKIP]${RC} %s\n" "$1"
    [ $# -ge 2 ] && printf "         ${DIM}%s${RC}\n" "$2"
}

section() {
    printf "\n${CYAN}▶ %s${RC}\n" "$1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

printf "${BLUE}╔════════════════════════════════════════════════════════╗${RC}\n"
printf "${BLUE}║  ${WHITE}DXSBash Security Audit — read-only system check${BLUE}       ║${RC}\n"
printf "${BLUE}╚════════════════════════════════════════════════════════╝${RC}\n"
printf "  ${CYAN}Host:${RC}    %s\n" "$(hostname 2>/dev/null || echo unknown)"
printf "  ${CYAN}User:${RC}    %s%s\n" "$(id -un)" "$([ "$IS_ROOT" -eq 1 ] && echo ' (root — full coverage)' || echo ' (some checks need root)')"
printf "  ${CYAN}Date:${RC}    %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"

#=================================================================
# 1. Pending security updates (Debian/Ubuntu)
#=================================================================
if command_exists apt; then
    section "System updates"

    UPGRADABLE_LIST="$(apt list --upgradable 2>/dev/null)"
    SEC_UPDATES=$(printf '%s\n' "$UPGRADABLE_LIST" | grep -ci -- "-security")
    if [ "${SEC_UPDATES:-0}" -gt 0 ]; then
        warn "${SEC_UPDATES} pending security update(s)" \
             "run: sudo apt upgrade   (or the 'update' alias)"
    else
        pass "No pending security updates"
    fi

    if dpkg -s unattended-upgrades >/dev/null 2>&1; then
        pass "unattended-upgrades installed"
    else
        warn "unattended-upgrades not installed" \
             "automatic security patching is recommended on servers: sudo apt install unattended-upgrades"
    fi
fi

#=================================================================
# 2. Firewall
#=================================================================
section "Firewall"

FIREWALL=""
if command_exists systemctl; then
    if systemctl is-active --quiet ufw 2>/dev/null; then
        FIREWALL="ufw"
    elif systemctl is-active --quiet nftables 2>/dev/null; then
        FIREWALL="nftables"
    elif systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALL="firewalld"
    fi
fi
if [ -n "$FIREWALL" ]; then
    pass "Firewall active" "$FIREWALL"
elif ! command_exists systemctl; then
    skip "Firewall state unknown" "no systemd available to query (container?)"
else
    warn "No active firewall detected" "consider: sudo ufw enable   (after allowing SSH!)"
fi

#=================================================================
# 3. SSH daemon hardening
#=================================================================
# Effective option = last occurrence across sshd_config and the
# Debian 12+ sshd_config.d includes. 'sshd -T' would be exact but
# needs root and a valid host key set; file parsing degrades well.
sshd_option() {
    local opt="$1"
    cat /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
        | grep -Ei "^[[:space:]]*${opt}[[:space:]]" \
        | tail -1 \
        | awk '{print tolower($2)}'
}

if [ -r /etc/ssh/sshd_config ]; then
    section "SSH server"

    PRL="$(sshd_option PermitRootLogin)"
    case "$PRL" in
        yes)
            fail "PermitRootLogin is enabled" \
                 "set 'PermitRootLogin no' (or prohibit-password) in /etc/ssh/sshd_config" ;;
        no|prohibit-password|without-password)
            pass "PermitRootLogin restricted" "$PRL" ;;
        "")
            pass "PermitRootLogin not set" "OpenSSH default is prohibit-password" ;;
        *)
            warn "PermitRootLogin has unusual value" "$PRL" ;;
    esac

    PWA="$(sshd_option PasswordAuthentication)"
    case "$PWA" in
        no)
            pass "PasswordAuthentication disabled" "key-based auth only" ;;
        yes)
            warn "PasswordAuthentication enabled" \
                 "prefer SSH keys; set 'PasswordAuthentication no' once keys are in place" ;;
        "")
            warn "PasswordAuthentication not set (default: yes)" \
                 "prefer SSH keys; set 'PasswordAuthentication no' once keys are in place" ;;
    esac
elif [ -e /etc/ssh/sshd_config ]; then
    section "SSH server"
    skip "sshd_config not readable" "run with sudo for SSH checks"
fi

#=================================================================
# 4. Accounts and privileges
#=================================================================
section "Accounts and privileges"

EXTRA_ROOT="$(awk -F: '$3==0 && $1!="root" {print $1}' /etc/passwd 2>/dev/null)"
if [ -n "$EXTRA_ROOT" ]; then
    fail "Additional UID-0 account(s) found" "$(echo "$EXTRA_ROOT" | tr '\n' ' ')"
else
    pass "root is the only UID-0 account"
fi

if [ -r /etc/shadow ]; then
    EMPTY_PW="$(awk -F: '$2=="" {print $1}' /etc/shadow 2>/dev/null)"
    if [ -n "$EMPTY_PW" ]; then
        fail "Account(s) with empty password" "$(echo "$EMPTY_PW" | tr '\n' ' ')"
    else
        pass "No accounts with empty passwords"
    fi
else
    skip "Empty-password check skipped" "needs root to read /etc/shadow"
fi

if [ -r /etc/sudoers ]; then
    NOPASSWD_COUNT=$(grep -rEh '^[^#]*NOPASSWD' /etc/sudoers /etc/sudoers.d 2>/dev/null | grep -c .)
    if [ "${NOPASSWD_COUNT:-0}" -gt 0 ]; then
        warn "${NOPASSWD_COUNT} NOPASSWD sudoers rule(s)" \
             "passwordless sudo removes an authentication barrier — review: sudo grep -r NOPASSWD /etc/sudoers*"
    else
        pass "No NOPASSWD sudoers rules"
    fi
else
    skip "sudoers check skipped" "needs root to read /etc/sudoers"
fi

#=================================================================
# 5. PATH hygiene (for the invoking user)
#=================================================================
section "PATH hygiene"

PATH_ISSUES=""
IFS=':' read -r -a PATH_ENTRIES <<< "$PATH"
for entry in "${PATH_ENTRIES[@]}"; do
    if [ -z "$entry" ] || [ "$entry" = "." ]; then
        PATH_ISSUES="${PATH_ISSUES}  relative entry ('.' or empty) — commands in the current directory would shadow system ones\n"
        continue
    fi
    # -L resolves symlinks (e.g. /bin -> usr/bin) so we test the real
    # target's permissions, not the always-777 symlink itself; the
    # sticky-bit exclusion (-perm -1000) spares safe dirs like /tmp.
    if [ -d "$entry" ] && \
       [ -n "$(find -L "$entry" -maxdepth 0 -perm -0002 ! -perm -1000 2>/dev/null)" ]; then
        PATH_ISSUES="${PATH_ISSUES}  world-writable directory: $entry\n"
    fi
done
if [ -n "$PATH_ISSUES" ]; then
    fail "PATH contains unsafe entries"
    printf "${DIM}%b${RC}" "$PATH_ISSUES"
else
    pass "PATH clean" "${#PATH_ENTRIES[@]} entries, none relative or world-writable"
fi

#=================================================================
# 6. Filesystem permissions
#=================================================================
section "Filesystem"

WW_FILES="$(find /etc /usr/local/bin /usr/local/sbin -xdev -type f -perm -0002 2>/dev/null | head -5)"
if [ -n "$WW_FILES" ]; then
    fail "World-writable file(s) in system directories" "$(echo "$WW_FILES" | tr '\n' ' ')"
else
    pass "No world-writable files in /etc or /usr/local/{bin,sbin}"
fi

# SUID/SGID baseline: first run records the current set; later runs
# flag anything new (a common persistence/privilege-escalation sign).
SUID_BASELINE="$HOME/.dxsbash/suid.baseline"
SUID_CURRENT="$(find /usr -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort)"
if [ ! -f "$SUID_BASELINE" ]; then
    mkdir -p "$(dirname "$SUID_BASELINE")" 2>/dev/null
    if printf '%s\n' "$SUID_CURRENT" > "$SUID_BASELINE" 2>/dev/null; then
        pass "SUID/SGID baseline created" \
             "$(printf '%s\n' "$SUID_CURRENT" | grep -c .) entries recorded in $SUID_BASELINE"
    else
        skip "Could not write SUID/SGID baseline" "$SUID_BASELINE"
    fi
else
    NEW_SUID="$(comm -13 "$SUID_BASELINE" <(printf '%s\n' "$SUID_CURRENT") 2>/dev/null)"
    if [ -n "$NEW_SUID" ]; then
        warn "New SUID/SGID binaries since baseline" \
             "$(echo "$NEW_SUID" | head -5 | tr '\n' ' ')— if legitimate, refresh with: rm $SUID_BASELINE"
    else
        pass "No new SUID/SGID binaries since baseline"
    fi
fi

#=================================================================
# 7. Authentication activity (last ~24h where measurable)
#=================================================================
section "Authentication activity"

AUTH_SOURCE=""
FAILED_LINES=""
if [ -r /var/log/auth.log ]; then
    AUTH_SOURCE="/var/log/auth.log"
    FAILED_LINES="$(grep -a "Failed password" /var/log/auth.log 2>/dev/null)"
elif command_exists journalctl && journalctl -q --system -n 1 >/dev/null 2>&1; then
    AUTH_SOURCE="journal (24h)"
    FAILED_LINES="$(journalctl -q --system --since "24 hours ago" --no-pager 2>/dev/null | grep -a "Failed password")"
fi

if [ -z "$AUTH_SOURCE" ]; then
    skip "Failed-login check skipped" "needs root or membership in the adm/systemd-journal group"
else
    FAILED_COUNT=$(printf '%s' "$FAILED_LINES" | grep -c .)
    if [ "${FAILED_COUNT:-0}" -eq 0 ]; then
        pass "No failed SSH logins" "source: $AUTH_SOURCE"
    else
        TOP_IP="$(printf '%s\n' "$FAILED_LINES" | grep -oE 'from [0-9a-fA-F.:]+' | awk '{print $2}' | sort | uniq -c | sort -rn | head -1 | awk '{print $2" ("$1"x)"}')"
        warn "${FAILED_COUNT} failed SSH login attempt(s)" \
             "source: $AUTH_SOURCE — top offender: ${TOP_IP:-n/a}; consider fail2ban"
    fi
fi

#=================================================================
# 8. Network exposure
#=================================================================
section "Network exposure"

if command_exists ss; then
    LISTENERS="$(ss -tulnH 2>/dev/null)"
    TOTAL=$(printf '%s' "$LISTENERS" | grep -c .)
    # Services that are almost always internal-only, listening on all
    # interfaces (not loopback):
    EXPOSED="$(printf '%s\n' "$LISTENERS" | awk '$5 !~ /^(127\.|\[::1\]|::1)/ {print $5}')"
    RISKY=""
    for port in 3306 5432 6379 27017 11211 9200 2375; do
        if printf '%s\n' "$EXPOSED" | grep -qE "[:.]${port}\$"; then
            RISKY="${RISKY} ${port}"
        fi
    done
    if [ -n "$RISKY" ]; then
        warn "Internal service port(s) listening on all interfaces:${RISKY}" \
             "databases/caches/docker API should bind to 127.0.0.1 or be firewalled"
    else
        pass "No common internal services exposed on all interfaces" \
             "${TOTAL} listening socket(s) total"
    fi
    if [ "$VERBOSE" -eq 1 ] && [ -n "$LISTENERS" ]; then
        printf "${DIM}%s${RC}\n" "$(printf '%s\n' "$LISTENERS" | awk '{printf "         %-6s %s\n", $1, $5}')"
    fi
else
    skip "Listening-socket check skipped" "ss not available"
fi

#=================================================================
# Summary
#=================================================================
printf "\n${BLUE}╔════════════════════════════════════════════════════════╗${RC}\n"
printf "${BLUE}║  ${WHITE}Summary${BLUE}                                               ║${RC}\n"
printf "${BLUE}╚════════════════════════════════════════════════════════╝${RC}\n"
printf "  ${GREEN}pass:${RC} %d   ${YELLOW}warn:${RC} %d   ${RED}fail:${RC} %d   ${CYAN}skip:${RC} %d\n" \
    "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"

if [ "$SKIP_COUNT" -gt 0 ] && [ "$IS_ROOT" -eq 0 ]; then
    printf "\n  ${CYAN}ℹ %d check(s) skipped — run ${WHITE}sudo dxsbash audit${CYAN} for full coverage.${RC}\n" "$SKIP_COUNT"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf "\n  ${RED}✗ Security problems found.${RC} Review the FAIL items above.\n"
    exit 1
fi
if [ "$WARN_COUNT" -gt 0 ]; then
    printf "\n  ${YELLOW}⚠ No critical problems, but some items deserve attention.${RC}\n"
    exit 0
fi
printf "\n  ${GREEN}✓ No security problems detected by these checks.${RC}\n"
exit 0
