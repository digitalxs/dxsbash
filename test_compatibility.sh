#!/bin/bash
set -euo pipefail

# Identify the platform from os-release
OS_ID=""
PRETTY="unknown"
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
    PRETTY="${PRETTY_NAME:-${ID:-unknown}}"
fi

echo "Testing DXSBash compatibility on: ${PRETTY}"

# Debian 13 Trixie is the reference platform: version minimums are hard
# requirements there and informational everywhere else. Check the
# os-release ID, not the family — Ubuntu also ships /etc/debian_version
# containing "trixie/sid" and must not be held to strict checks.
STRICT=0
if [ "$OS_ID" = debian ] && [ -f /etc/debian_version ] && \
   grep -qE "^13\.|trixie" /etc/debian_version; then
    STRICT=1
    echo "✓ Running on Debian 13 Trixie ($(cat /etc/debian_version)) — strict version checks"
else
    echo "ℹ Not the Debian 13 reference platform — version checks are informational only"
fi

# Compare semantic versions: returns 0 if $1 >= $2
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Test critical commands and their minimum versions
echo ""
echo "Checking required commands and versions:"

check_version() {
    local cmd="$1"
    local min_ver="$2"
    local ver_flag="${3:---version}"

    if ! command -v "$cmd" &>/dev/null; then
        echo "✗ $cmd — not found"
        [ "$STRICT" -eq 1 ] && return 1
        return 0
    fi

    local actual_ver
    actual_ver=$("$cmd" $ver_flag 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)

    if [ -z "$actual_ver" ]; then
        echo "? $cmd — found but could not determine version"
        return 0
    fi

    if version_ge "$actual_ver" "$min_ver"; then
        echo "✓ $cmd ${actual_ver} (>= ${min_ver} reference)"
    elif [ "$STRICT" -eq 1 ]; then
        echo "✗ $cmd ${actual_ver} is below minimum required ${min_ver}"
        return 1
    else
        echo "⚠ $cmd ${actual_ver} is below the Debian 13 reference ${min_ver} (informational)"
    fi
}

check_version bash  5.2
check_version python3 3.12
check_version git   2.45
# systemd version is reported differently; also absent by design on
# some systems (containers, non-systemd distros) — warn, don't fail.
if command -v systemctl &>/dev/null; then
    SYSTEMD_VER=$(systemctl --version 2>&1 | grep -oE '^systemd [0-9]+' | grep -oE '[0-9]+' || true)
    if [ -n "$SYSTEMD_VER" ] && [ "$SYSTEMD_VER" -ge 256 ] 2>/dev/null; then
        echo "✓ systemd ${SYSTEMD_VER} (>= 256 reference)"
    elif [ -n "$SYSTEMD_VER" ] && [ "$STRICT" -eq 1 ]; then
        echo "✗ systemd ${SYSTEMD_VER} is below minimum required 256"
    elif [ -n "$SYSTEMD_VER" ]; then
        echo "⚠ systemd ${SYSTEMD_VER} is below the Debian 13 reference 256 (informational)"
    else
        echo "? systemctl — found but could not determine version"
    fi
else
    echo "⚠ systemctl — not found (container or non-systemd system)"
fi

# Check for deprecated packages (dpkg-based systems only)
if command -v dpkg &>/dev/null; then
    echo ""
    echo "Checking for deprecated packages:"
    DEPRECATED=(
        "python3-distutils"
        "nodejs-legacy"
        "bashtop"
    )

    for pkg in "${DEPRECATED[@]}"; do
        if dpkg -l "$pkg" &>/dev/null 2>&1; then
            echo "⚠ Deprecated package installed: $pkg"
        else
            echo "✓ $pkg not installed"
        fi
    done
fi

# Check bat binary naming (Debian/Ubuntu use 'batcat' instead of 'bat')
echo ""
echo "Checking bat binary naming:"
if command -v batcat &>/dev/null; then
    echo "✓ batcat found (Debian naming convention)"
elif command -v bat &>/dev/null; then
    echo "✓ bat found"
else
    echo "✗ Neither bat nor batcat found — install the 'bat' package"
fi

echo ""
echo "Compatibility check complete"
