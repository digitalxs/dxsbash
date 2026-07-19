#!/bin/bash
#=================================================================
# DXSBash .deb package builder
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Builds a binary Debian package that ships the repository to
# /usr/share/dxsbash and provides /usr/bin/dxsbash-installer, which
# copies it into the invoking user's ~/linuxtoolbox/dxsbash and runs
# the normal interactive installer. Packaging does NOT replace
# setup.sh — per-user symlinks, shell selection and fonts still happen
# through it; the .deb is a distribution vehicle.
#
# Usage:   ./packaging/build-deb.sh
# Output:  dist/dxsbash_<version>_all.deb
#
# Requires dpkg-deb (present on any Debian/Ubuntu system).
#=================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_DIR/version.txt")"
DIST="$REPO_DIR/dist"
PKGROOT="$DIST/pkgroot"
SHARE="$PKGROOT/usr/share/dxsbash"

command -v dpkg-deb >/dev/null 2>&1 || {
    echo "Error: dpkg-deb not found — build on a Debian/Ubuntu system." >&2
    exit 1
}

rm -rf "$PKGROOT"
mkdir -p "$SHARE" "$PKGROOT/usr/bin" "$PKGROOT/DEBIAN" \
         "$PKGROOT/usr/share/doc/dxsbash"

#-----------------------------------------------------------------
# Payload: the repository, minus VCS/CI/build metadata
#-----------------------------------------------------------------
tar -C "$REPO_DIR" \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='dist' \
    --exclude='packaging' \
    -cf - . | tar -C "$SHARE" -xf -

# Debian policy: changelog and copyright under /usr/share/doc
gzip -9 -n -c "$REPO_DIR/CHANGELOG.md" \
    > "$PKGROOT/usr/share/doc/dxsbash/changelog.gz"
cp "$REPO_DIR/LICENSE" "$PKGROOT/usr/share/doc/dxsbash/copyright"

#-----------------------------------------------------------------
# /usr/bin/dxsbash-installer — per-user bootstrap
#-----------------------------------------------------------------
cat > "$PKGROOT/usr/bin/dxsbash-installer" <<'LAUNCHER'
#!/bin/bash
# Bootstrap DXSBash for the current user from /usr/share/dxsbash.
set -euo pipefail

SRC="/usr/share/dxsbash"
DEST="$HOME/linuxtoolbox/dxsbash"

if [ "$(id -u)" -eq 0 ] && [ -z "${DXSBASH_ALLOW_ROOT:-}" ]; then
    echo "Run dxsbash-installer as the user who will use the shell,"
    echo "not as root (set DXSBASH_ALLOW_ROOT=1 to override)."
    exit 1
fi

mkdir -p "$HOME/linuxtoolbox"
if [ -d "$DEST" ]; then
    echo "Refreshing existing $DEST from $SRC..."
else
    echo "Copying $SRC to $DEST..."
fi
cp -a "$SRC/." "$DEST/"
chmod +x "$DEST/setup.sh"
cd "$DEST"
exec ./setup.sh "$@"
LAUNCHER
chmod 755 "$PKGROOT/usr/bin/dxsbash-installer"

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
Recommends: zsh, fish, fzf, zoxide, bat, ripgrep, tree, trash-cli
Suggests: fastfetch, btop, multitail
Installed-Size: $INSTALLED_SIZE
Maintainer: Luis Miguel P. Freitas <luis@digitalxs.ca>
Homepage: https://dxsbash.digitalxs.ca
Description: professional shell environment for Bash, Zsh and Fish
 DXSBash is a cross-shell productivity suite for Debian, Ubuntu, Arch
 and Fedora power users: Starship prompt, fzf-powered history and
 navigation, zoxide, curated aliases and helper commands, with a
 single interactive installer.
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
