#!/bin/bash
#=================================================================
# DXSBash Arch Linux package builder
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Builds a native pacman package from this checkout, using
# packaging/arch/PKGBUILD with 'source' pointed at a tarball of the
# working tree (so unreleased changes can be packaged too).
#
# Usage:   ./packaging/build-arch.sh      (as a normal user, not root)
# Output:  dist/dxsbash-<version>-1-any.pkg.tar.zst
# Install: sudo pacman -U dist/dxsbash-<version>-1-any.pkg.tar.zst
#
# Requires makepkg (package "pacman", plus "base-devel" on Arch).
#=================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_DIR/version.txt")"
DIST="$REPO_DIR/dist"
WORK="$DIST/arch-build"

if ! command -v makepkg >/dev/null 2>&1; then
    echo "Error: makepkg not found — build on Arch Linux (sudo pacman -S --needed base-devel)." >&2
    echo "  On Debian/Ubuntu build the .deb instead: packaging/build-deb.sh" >&2
    exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: makepkg refuses to run as root — run this as a normal user." >&2
    exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK"

# Source tarball of the working tree, laid out like GitHub's release
# archive (top folder dxsbash-<version>), so the PKGBUILD needs no
# changes besides where it gets it from
tar -C "$REPO_DIR" \
    --exclude='./.git' --exclude='./.github' --exclude='./dist' \
    --transform "s|^\./|dxsbash-$VERSION/|" \
    -czf "$WORK/dxsbash-$VERSION.tar.gz" .
SUM="$(sha256sum "$WORK/dxsbash-$VERSION.tar.gz" | cut -d' ' -f1)"

sed -e "s|^pkgver=.*|pkgver=$VERSION|" \
    -e "s|^source=.*|source=(\"dxsbash-$VERSION.tar.gz\")|" \
    -e "s|^sha256sums=.*|sha256sums=('$SUM')|" \
    "$REPO_DIR/packaging/arch/PKGBUILD" > "$WORK/PKGBUILD"
cp "$REPO_DIR/packaging/arch/dxsbash.install" "$WORK/"

( cd "$WORK" && PKGDEST="$DIST" makepkg --force --cleanbuild --noconfirm )

PKG="$(ls -t "$DIST"/dxsbash-"$VERSION"-*-any.pkg.tar.* 2>/dev/null | head -n 1)"
rm -rf "$WORK"
echo ""
echo "Built: $PKG"
echo "Install with: sudo pacman -U $PKG"
