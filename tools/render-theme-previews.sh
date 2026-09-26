#!/bin/bash
#=================================================================
# Render the Starship theme preview images used by dxsbash-gui's
# theme picker (assets/theme-previews/<theme>.png).
#
# Developer tool — end users never run this; the PNGs are committed.
# Re-run it whenever a theme in starship-themes/ changes or is added.
#
# Requirements (dev machine only):
#   - starship               (on PATH, or STARSHIP=/path/to/starship)
#   - ImageMagick 'convert'  with the Pango coder (convert -list format | grep PANGO)
#   - Fira Code + a Nerd Font symbols font known to fontconfig
#   - root (a demo user and a fixed hostname are used, so previews do
#     not show root-only styling or this machine's name)
#
# Usage: sudo tools/render-theme-previews.sh
#=================================================================

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/assets/theme-previews"
STARSHIP="${STARSHIP:-$(command -v starship || true)}"
FONT="${PREVIEW_FONT:-Fira Code,Pure Nerd Font,Symbols Nerd Font 13}"
BG="#0d1117"
FG="#e6edf3"
DEMO_USER="dxs"
DEMO_HOST="devbox"

[ -x "$STARSHIP" ] || { echo "starship not found (set STARSHIP=...)" >&2; exit 1; }
convert -list format 2>/dev/null | grep -q PANGO || { echo "ImageMagick lacks the Pango coder" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "run as root (needs a demo user + hostname namespace)" >&2; exit 1; }

id "$DEMO_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$DEMO_USER"
DEMO_HOME="$(getent passwd "$DEMO_USER" | cut -d: -f6)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A realistic demo project: git repo with local changes, a Node
# package and a Python file, so language/package modules have
# something to show.
PROJ="$DEMO_HOME/projects/dxsbash"
rm -rf "$PROJ"
runuser -u "$DEMO_USER" -- bash -c "
    set -e
    mkdir -p '$PROJ' && cd '$PROJ'
    git init -q -b main
    git config user.email demo@example.com; git config user.name Demo
    printf '{\"name\":\"dxsbash\",\"version\":\"$(tr -d '[:space:]' < "$REPO/version.txt")\"}\n' > package.json
    printf 'print(\"hi\")\n' > app.py
    git add -A && git commit -qm init
    echo '# wip' >> app.py
"

# Everything the demo user runs or reads must be outside root-only
# directories (starship may live in e.g. /root/.cargo/bin)
cp "$REPO"/starship-themes/*.toml "$WORK/"
cp "$STARSHIP" "$WORK/starship"
# The container module would print "[Docker]"/"[podman]" when this runs
# in a dev container — noise users never see on their desktop. Disable
# it in the work copies only (never in the shipped themes).
for t in "$WORK"/*.toml; do
    if grep -q '^\[container\][[:space:]]*$' "$t"; then
        sed -i 's/^\[container\][[:space:]]*$/[container]\ndisabled = true/' "$t"
    else
        printf '\n[container]\ndisabled = true\n' >> "$t"
    fi
done
STARSHIP="$WORK/starship"
chmod 644 "$WORK"/*.toml; chmod 755 "$WORK" "$STARSHIP"

mkdir -p "$OUT"
for theme in "$REPO"/starship-themes/*.toml; do
    name="$(basename "$theme" .toml)"
    [ "$name" = "ssh-lite" ] && continue   # automatic over SSH, not user-picked

    # Render the prompt as the demo user, inside a UTS namespace with a
    # fixed hostname, then append a typed command and a cursor.
    unshare --uts bash -c "
        hostname '$DEMO_HOST'
        cd '$PROJ'
        runuser -u '$DEMO_USER' -- env -i HOME='$DEMO_HOME' USER='$DEMO_USER' LOGNAME='$DEMO_USER' \
            PATH='$(dirname "$STARSHIP"):/usr/local/bin:/usr/bin:/bin:$(dirname "$(command -v node || echo /usr/bin/node)")' \
            TERM=xterm-256color COLORTERM=truecolor LANG=C.UTF-8 \
            STARSHIP_CONFIG='$WORK/$name.toml' STARSHIP_CACHE='$WORK/cache' \
            '$STARSHIP' prompt --status=0 --cmd-duration=0 --jobs=0 --terminal-width=110
    " > "$WORK/$name.ansi" 2>/dev/null

    # Same converter the GUI uses for its live previews; append a typed
    # command and a block cursor after the prompt
    { printf '%s' "$(cat "$WORK/$name.ansi")"
      printf '\033[0m git status\033[38;2;230;237;243m \342\226\210\n'
    } | awk -f "$REPO/tools/ansi2pango.awk" -v fg="$FG" -v font="$FONT" > "$WORK/$name.pango"

    # Markup passed inline: distro ImageMagick policies block "@file"
    convert -background "$BG" -density 96 "pango:$(cat "$WORK/$name.pango")" \
        -resize '1000x>' -bordercolor "$BG" -border 16x12 "$OUT/$name.png"
    echo "rendered $name.png ($(identify -format '%wx%h' "$OUT/$name.png"))"
done

rm -rf "$PROJ"
