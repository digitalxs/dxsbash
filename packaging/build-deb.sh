#!/bin/bash
#=================================================================
# DXSBash .deb package builder
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Builds a binary Debian package that ships the repository to
# /usr/share/dxsbash and provides /usr/bin/dxsbash-installer, which
# clones DXSBash into the invoking user's ~/linuxtoolbox/dxsbash and runs
# the normal interactive installer. Packaging does NOT replace
# setup.sh — per-user symlinks, shell selection and fonts still happen
# through it; the .deb is a distribution vehicle.
#
# Usage:   ./packaging/build-deb.sh
# Output:  dist/dxsbash_<version>_all.deb
#
# Requires dpkg-deb: always present on Debian/Ubuntu; on Arch install
# the "dpkg" package, on Fedora "dpkg". (To install DXSBash *on* Arch,
# build the native package instead: packaging/build-arch.sh.)
#=================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_DIR/version.txt")"
DIST="$REPO_DIR/dist"
PKGROOT="$DIST/pkgroot"
SHARE="$PKGROOT/usr/share/dxsbash"

if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "Error: dpkg-deb not found." >&2
    if command -v pacman >/dev/null 2>&1; then
        echo "  Arch: sudo pacman -S dpkg" >&2
        echo "  (a .deb cannot be installed on Arch — for Arch itself use packaging/build-arch.sh)" >&2
    elif command -v dnf >/dev/null 2>&1; then
        echo "  Fedora: sudo dnf install dpkg" >&2
    else
        echo "  Debian/Ubuntu: sudo apt install dpkg" >&2
    fi
    exit 1
fi

rm -rf "$PKGROOT"
mkdir -p "$SHARE" "$PKGROOT/usr/bin" "$PKGROOT/DEBIAN" \
         "$PKGROOT/usr/share/doc/dxsbash"

#-----------------------------------------------------------------
# Payload: the repository, minus VCS/CI/build metadata
#-----------------------------------------------------------------
# packaging/ stays in: DEV.md (also shipped) documents building the
# .deb from the installed tree.
tar -C "$REPO_DIR" \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='dist' \
    -cf - . | tar -C "$SHARE" -xf -

# Debian policy: changelog and copyright under /usr/share/doc
gzip -9 -n -c "$REPO_DIR/CHANGELOG.md" \
    > "$PKGROOT/usr/share/doc/dxsbash/changelog.gz"
cp "$REPO_DIR/LICENSE" "$PKGROOT/usr/share/doc/dxsbash/copyright"

#-----------------------------------------------------------------
# /usr/bin/dxsbash-installer — per-user bootstrap
#-----------------------------------------------------------------
# Shared with the Arch package (packaging/dxsbash-installer)
install -m 755 "$REPO_DIR/packaging/dxsbash-installer" "$PKGROOT/usr/bin/dxsbash-installer"

#-----------------------------------------------------------------
# Control metadata
#-----------------------------------------------------------------
INSTALLED_SIZE=$(du -ks "$PKGROOT/usr" | cut -f1)

cat > "$PKGROOT/DEBIAN/control" <<CONTROL
Package: dxsbash
Version: $VERSION
Section: shells
Priority: optional
Architecture: all
Depends: bash (>= 5.0), git, curl, tar
Recommends: zsh, fish, fzf, zoxide, bat, ripgrep, tree, trash-cli, zenity
Suggests: fastfetch, btop, multitail
Installed-Size: $INSTALLED_SIZE
Maintainer: Luis Miguel P. Freitas <luis@digitalxs.ca>
Homepage: https://dxsbash.digitalxs.ca
Description: professional shell environment for Bash, Zsh and Fish
 DXSBash is a cross-shell productivity suite for Debian, Ubuntu, Arch
 and Fedora power users: Starship prompt, fzf-powered history and
 navigation, zoxide, curated aliases and helper commands, with a
 single interactive installer, plus a graphical settings window
 (System → DXSBash Settings) for prompt themes, custom aliases and
 updates.
 .
 After installing this package, each user runs 'dxsbash-installer'
 once to set up their own shell configuration.
CONTROL

cat > "$PKGROOT/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
    echo "DXSBash installed to /usr/share/dxsbash."
    echo "Each user should now run: dxsbash-installer"
fi
exit 0
POSTINST
chmod 755 "$PKGROOT/DEBIAN/postinst"

# md5sums for package integrity verification
( cd "$PKGROOT" && find usr -type f -exec md5sum {} + > DEBIAN/md5sums )
chmod 644 "$PKGROOT/DEBIAN/md5sums"

#-----------------------------------------------------------------
# Build
#-----------------------------------------------------------------
OUT="$DIST/dxsbash_${VERSION}_all.deb"
dpkg-deb --build --root-owner-group "$PKGROOT" "$OUT"
rm -rf "$PKGROOT"

echo ""
echo "Built: $OUT"
dpkg-deb --info "$OUT" | sed 's/^/  /'
