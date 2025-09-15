#!/bin/bash
# Dependency checker for DXSBash

check_command() {
    if command -v "$1" &> /dev/null; then
        echo "✓ $1"
    else
        echo "✗ $1 (missing)"
        return 1
    fi
}

echo "Checking DXSBash dependencies..."
echo "================================"

REQUIRED="git curl bash"
OPTIONAL="zsh fish starship zoxide fzf fastfetch bat ripgrep tree multitail nano nvim docker kubectl xclip xdotool notify-send bc lsof openssl"

echo "Required:"
for cmd in $REQUIRED; do
    check_command "$cmd"
done

echo ""
echo "Optional:"
for cmd in $OPTIONAL; do
    check_command "$cmd"
done