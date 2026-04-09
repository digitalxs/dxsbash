#!/bin/bash
set -euo pipefail

echo "Testing Debian 13 Trixie Compatibility..."

# Check Debian version
if [ -f /etc/debian_version ]; then
    DEBIAN_VER=$(cat /etc/debian_version)
    if echo "$DEBIAN_VER" | grep -qE "^13\.|trixie"; then
        echo "✓ Running on Debian 13 Trixie (${DEBIAN_VER})"
    else
        echo "⚠ Warning: Not running on Debian 13 Trixie (detected: ${DEBIAN_VER})"
    fi
else
    echo "⚠ Warning: /etc/debian_version not found — not a Debian system"
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
        return 1
    fi

    local actual_ver
    actual_ver=$("$cmd" $ver_flag 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)

    if [ -z "$actual_ver" ]; then
        echo "? $cmd — found but could not determine version"
        return 0
    fi

    if version_ge "$actual_ver" "$min_ver"; then
        echo "✓ $cmd ${actual_ver} (>= ${min_ver} required)"
    else
        echo "✗ $cmd ${actual_ver} is below minimum required ${min_ver}"
        return 1
    fi
}

check_version bash  5.2
check_version python3 3.12
check_version git   2.45
# systemd version is reported differently
if command -v systemctl &>/dev/null; then
    SYSTEMD_VER=$(systemctl --version 2>&1 | grep -oE '^systemd [0-9]+' | grep -oE '[0-9]+' || true)
    if [ -n "$SYSTEMD_VER" ] && [ "$SYSTEMD_VER" -ge 256 ] 2>/dev/null; then
        echo "✓ systemd ${SYSTEMD_VER} (>= 256 required)"
    elif [ -n "$SYSTEMD_VER" ]; then
        echo "✗ systemd ${SYSTEMD_VER} is below minimum required 256"
    else
        echo "? systemctl — found but could not determine version"
    fi
else
    echo "✗ systemctl — not found"
fi

# Check for deprecated packages
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

# Check bat binary naming (Debian uses 'batcat' instead of 'bat')
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
