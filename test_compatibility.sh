#!/bin/bash
set -euo pipefail

echo "Testing Debian 13 Trixie Compatibility..."

# Check Debian version
if ! grep -q "13\|trixie" /etc/debian_version; then
    echo "Warning: Not running on Debian 13 Trixie"
fi

# Test critical commands
COMMANDS=(
    "bash:5.2"
    "python3:3.12"
    "git:2.45"
    "systemctl:256"
)

for cmd_ver in "${COMMANDS[@]}"; do
    IFS=':' read -r cmd min_ver <<< "$cmd_ver"
    if command -v "$cmd" &>/dev/null; then
        echo "✓ $cmd found"
    else
        echo "✗ $cmd missing"
    fi
done

# Check for deprecated packages
DEPRECATED=(
    "python3-distutils"
    "nodejs-legacy"
)

for pkg in "${DEPRECATED[@]}"; do
    if dpkg -l "$pkg" &>/dev/null 2>&1; then
        echo "⚠ Deprecated package found: $pkg"
    fi
done

echo "Compatibility check complete"