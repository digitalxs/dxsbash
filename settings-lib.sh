# shellcheck shell=bash
#=================================================================
# DXSBash settings model — shared by dxsbash-config.sh (terminal UI)
# and dxsbash-gui.sh (graphical UI)
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Single source of truth for the user settings files, so both front
# ends always read and write exactly the same keys:
#
#   ~/.dxsbash/user.conf            sourced by bash/zsh
#   ~/.dxsbash/user.fish            fish twin (fish can't source POSIX)
#   ~/.dxsbash/custom-aliases.sh    user aliases, sourced by bash/zsh
#   ~/.dxsbash/custom-aliases.fish  generated fish twin
#   ~/.config/starship.toml         symlink to the selected preset
#
# This file is sourced, never executed: it only defines variables and
# functions and prints nothing. Adding a setting means adding it to
# DEF_*, load_settings and write_settings here — nowhere else.
#=================================================================

DXSBASH_DIR="${DXSBASH_DIR:-$HOME/linuxtoolbox/dxsbash}"
CONF_DIR="${CONF_DIR:-$HOME/.dxsbash}"
CONF_FILE="${CONF_FILE:-$CONF_DIR/user.conf}"
CONF_FISH_FILE="${CONF_FISH_FILE:-$CONF_DIR/user.fish}"
ALIAS_FILE="${ALIAS_FILE:-$CONF_DIR/custom-aliases.sh}"
ALIAS_FISH_FILE="${ALIAS_FISH_FILE:-$CONF_DIR/custom-aliases.fish}"
STARSHIP_LINK="${STARSHIP_LINK:-$HOME/.config/starship.toml}"
STARSHIP_THEMES_DIR="${STARSHIP_THEMES_DIR:-$DXSBASH_DIR/starship-themes}"
# The user's own Starship themes: any *.toml here shows up in the pickers
USER_THEMES_DIR="${USER_THEMES_DIR:-$CONF_DIR/themes}"
# Konsole profile written by setup.sh (Yakuake uses the same profile)
KONSOLE_DIR="${KONSOLE_DIR:-$HOME/.local/share/konsole}"
KONSOLE_PROFILE="${KONSOLE_PROFILE:-$KONSOLE_DIR/DXSBash.profile}"
KONSOLE_SCHEMES_SRC="${KONSOLE_SCHEMES_SRC:-$DXSBASH_DIR/assets/konsole}"

# ── Starship theme registry ───────────────────────────────────────
# Display name | filename in starship-themes/ | one-line description
# ssh-lite.toml is deliberately absent: it is selected automatically
# over SSH, not a user-facing theme.
STARSHIP_THEMES=(
    "DXS Starship|dxs-starship.toml|The DXSBash signature look — clean, informative, the default"
    "Nerd Font Symbols|nerd-font-symbols.toml|Starship defaults with Nerd Font icons for every module"
    "Bracketed Segments|bracketed-segments.toml|Minimal text, each module wrapped in [brackets] — no special fonts"
    "Pastel Powerline|pastel-powerline.toml|Soft pastel powerline blocks with rounded edges"
    "Tokyo Night|tokyo-night.toml|Deep blues and purples inspired by the Tokyo Night palette"
    "Gruvbox Rainbow|gruvbox-rainbow.toml|Warm retro Gruvbox colors in a rainbow of segments"
    "Catppuccin Powerline|catppuccin-powerline.toml|Catppuccin Mocha pastels on powerline segments"
)

# ── Defaults ──────────────────────────────────────────────────────
DEF_EDITOR="nano"
DEF_HISTSIZE=500
DEF_HISTFILESIZE=10000
DEF_FASTFETCH="true"
DEF_PROMPT_STYLE="starship"
DEF_STARSHIP_THEME="dxs-starship.toml"
DEF_SECSUMMARY="false"
DEF_SSH_LITE="true"
DEF_UPDATE_CHANNEL="stable"    # stable = tagged releases, main = every push
DEF_UPDATE_NOTIFY="true"       # desktop notification when an update exists
DEF_TERM_COLORS="true"         # match Konsole/Yakuake colors to the theme

# ── Current (working) values ──────────────────────────────────────
CUR_EDITOR=""
CUR_HISTSIZE=""
CUR_HISTFILESIZE=""
CUR_FASTFETCH=""
CUR_PROMPT_STYLE=""
CUR_STARSHIP_THEME=""
CUR_SECSUMMARY=""
CUR_SSH_LITE=""
CUR_UPDATE_CHANNEL=""
CUR_UPDATE_NOTIFY=""
CUR_TERM_COLORS=""

#=================================================================
# Settings files
#=================================================================

# Read one value from user.conf without sourcing it
_read_conf() {
    local key="$1" default="$2" val
    if [ ! -f "$CONF_FILE" ]; then
        echo "$default"
        return
    fi
    val=$(grep -E "^export ${key}=" "$CONF_FILE" 2>/dev/null \
          | head -1 \
          | sed -E 's/^export [^=]+="?([^"]*)"?$/\1/')
    echo "${val:-$default}"
}

load_settings() {
    CUR_EDITOR=$(         _read_conf "EDITOR"                 "$DEF_EDITOR")
    CUR_HISTSIZE=$(       _read_conf "HISTSIZE"               "$DEF_HISTSIZE")
    CUR_HISTFILESIZE=$(   _read_conf "HISTFILESIZE"           "$DEF_HISTFILESIZE")
    CUR_FASTFETCH=$(      _read_conf "DXSBASH_FASTFETCH"      "$DEF_FASTFETCH")
    CUR_PROMPT_STYLE=$(   _read_conf "DXSBASH_PROMPT_STYLE"   "$DEF_PROMPT_STYLE")
    CUR_STARSHIP_THEME=$( _read_conf "DXSBASH_STARSHIP_THEME" "$DEF_STARSHIP_THEME")
    CUR_SECSUMMARY=$(     _read_conf "DXSBASH_SECSUMMARY"     "$DEF_SECSUMMARY")
    CUR_SSH_LITE=$(       _read_conf "DXSBASH_SSH_LITE"       "$DEF_SSH_LITE")
    CUR_UPDATE_CHANNEL=$( _read_conf "DXSBASH_UPDATE_CHANNEL" "$DEF_UPDATE_CHANNEL")
    CUR_UPDATE_NOTIFY=$(  _read_conf "DXSBASH_UPDATE_NOTIFY"  "$DEF_UPDATE_NOTIFY")
    CUR_TERM_COLORS=$(    _read_conf "DXSBASH_TERM_COLORS"    "$DEF_TERM_COLORS")
    case "$CUR_UPDATE_CHANNEL" in stable|main) ;; *) CUR_UPDATE_CHANNEL="$DEF_UPDATE_CHANNEL" ;; esac

    # If the starship symlink points at a known theme, trust the
    # filesystem over the conf file — users may have run setup.sh or
    # hand-edited the symlink since the conf was written. setup.sh
    # links the repo-root starship.toml, which is the DXS preset.
    if [ -L "$STARSHIP_LINK" ]; then
        local target id
        target="$(readlink "$STARSHIP_LINK")"
        if _in_user_themes_dir "$target"; then
            id="user/${target##*/}"
        else
            id="${target##*/}"
            [ "$id" = "starship.toml" ] && id="dxs-starship.toml"
        fi
        if theme_known "$id"; then
            CUR_STARSHIP_THEME="$id"
        fi
    fi
}

# Values are written inside double quotes (sh and fish): refuse the
# characters that would end the string or expand ("  $  `  \)
setting_value_safe() {
    [[ "$1" != *[\"\$\`\\]* ]]
}

# Regenerate user.conf and its fish twin from the CUR_* values.
# $1 = name of the tool writing the file (shown in the header).
# Returns 1 and writes nothing if a value is unsafe (see above).
write_settings() {
    local writer="${1:-dxsbash}" stamp v
    for v in "$CUR_EDITOR" "$CUR_HISTSIZE" "$CUR_HISTFILESIZE" "$CUR_FASTFETCH" \
             "$CUR_PROMPT_STYLE" "$CUR_STARSHIP_THEME" "$CUR_SECSUMMARY" "$CUR_SSH_LITE" \
             "$CUR_UPDATE_CHANNEL" "$CUR_UPDATE_NOTIFY" "$CUR_TERM_COLORS"; do
        setting_value_safe "$v" || return 1
    done
    stamp="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$CONF_DIR"
    cat > "$CONF_FILE" <<EOF
# DXSBash User Configuration
# Generated by ${writer} on ${stamp}
# Edit with: dxsbash-config (terminal) or dxsbash-gui (graphical)
# Apply now: source ~/.bashrc  (or ~/.zshrc)

export EDITOR="${CUR_EDITOR}"
export VISUAL="${CUR_EDITOR}"
export HISTSIZE=${CUR_HISTSIZE}
export HISTFILESIZE=${CUR_HISTFILESIZE}
export DXSBASH_FASTFETCH="${CUR_FASTFETCH}"
export DXSBASH_PROMPT_STYLE="${CUR_PROMPT_STYLE}"
export DXSBASH_STARSHIP_THEME="${CUR_STARSHIP_THEME}"
export DXSBASH_SECSUMMARY="${CUR_SECSUMMARY}"
export DXSBASH_SSH_LITE="${CUR_SSH_LITE}"
export DXSBASH_UPDATE_CHANNEL="${CUR_UPDATE_CHANNEL}"
export DXSBASH_UPDATE_NOTIFY="${CUR_UPDATE_NOTIFY}"
export DXSBASH_TERM_COLORS="${CUR_TERM_COLORS}"
EOF

    # Fish cannot source POSIX files — write a fish-syntax twin so the
    # same settings apply there (HISTSIZE has no fish equivalent).
    cat > "$CONF_FISH_FILE" <<EOF
# DXSBash User Configuration (fish)
# Generated by ${writer} on ${stamp}
# Edit with: dxsbash-config (terminal) or dxsbash-gui (graphical)

set -gx EDITOR "${CUR_EDITOR}"
set -gx VISUAL "${CUR_EDITOR}"
set -gx DXSBASH_FASTFETCH "${CUR_FASTFETCH}"
set -gx DXSBASH_PROMPT_STYLE "${CUR_PROMPT_STYLE}"
set -gx DXSBASH_STARSHIP_THEME "${CUR_STARSHIP_THEME}"
set -gx DXSBASH_SECSUMMARY "${CUR_SECSUMMARY}"
set -gx DXSBASH_SSH_LITE "${CUR_SSH_LITE}"
set -gx DXSBASH_UPDATE_CHANNEL "${CUR_UPDATE_CHANNEL}"
set -gx DXSBASH_UPDATE_NOTIFY "${CUR_UPDATE_NOTIFY}"
set -gx DXSBASH_TERM_COLORS "${CUR_TERM_COLORS}"
EOF
}

reset_settings_to_defaults() {
    CUR_EDITOR="$DEF_EDITOR"
    CUR_HISTSIZE="$DEF_HISTSIZE"
    CUR_HISTFILESIZE="$DEF_HISTFILESIZE"
    CUR_FASTFETCH="$DEF_FASTFETCH"
    CUR_PROMPT_STYLE="$DEF_PROMPT_STYLE"
    CUR_STARSHIP_THEME="$DEF_STARSHIP_THEME"
    CUR_SECSUMMARY="$DEF_SECSUMMARY"
    CUR_SSH_LITE="$DEF_SSH_LITE"
    CUR_UPDATE_CHANNEL="$DEF_UPDATE_CHANNEL"
    CUR_UPDATE_NOTIFY="$DEF_UPDATE_NOTIFY"
    CUR_TERM_COLORS="$DEF_TERM_COLORS"
}

# Start refreshing the security-summary cache in the background, so the
# first login after enabling the feature shows real data.
prime_secsummary_cache() {
    if [ -f "$DXSBASH_DIR/secsummary.sh" ]; then
        bash "$DXSBASH_DIR/secsummary.sh" --refresh >/dev/null 2>&1 &
    fi
}

#=================================================================
# Starship themes
#=================================================================
theme_field() { # $1 = registry entry, $2 = 1 name | 2 file | 3 description
    local name file desc
    IFS='|' read -r name file desc <<< "$1"
    case "$2" in
        1) echo "$name" ;;
        2) echo "$file" ;;
        3) echo "$desc" ;;
    esac
}

# All pickable themes as registry entries (name|id|description): the
# built-in presets whose files exist, then the user's own themes from
# ~/.dxsbash/themes (id "user/<file>").
theme_entries() {
    local entry name id desc f base
    for entry in "${STARSHIP_THEMES[@]}"; do
        IFS='|' read -r name id desc <<< "$entry"
        [ -f "$STARSHIP_THEMES_DIR/$id" ] && printf '%s\n' "$entry"
    done
    [ -d "$USER_THEMES_DIR" ] || return 0
    for f in "$USER_THEMES_DIR"/*.toml; do
        [ -f "$f" ] || continue
        base="${f##*/}"
        # Same naming rule as import_user_theme: a hand-dropped file with
        # | " $ ` \ or spaces would corrupt this list or user.conf
        user_theme_name_ok "$base" || continue
        printf '%s|user/%s|Your own theme (~/.dxsbash/themes/%s)\n' "${base%.toml} (yours)" "$base" "$base"
    done
}

user_theme_name_ok() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.toml$ ]]
}

# Is the directory of symlink target $1 the user themes dir? (compared
# after resolving, so ./, trailing slashes or symlinked dirs match)
_in_user_themes_dir() {
    local d u
    d="$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)" || return 1
    u="$(cd "$USER_THEMES_DIR" 2>/dev/null && pwd -P)" || return 1
    [ "$d" = "$u" ]
}

# File behind a theme id
theme_path() {
    case "$1" in
        user/*) printf '%s' "$USER_THEMES_DIR/${1#user/}" ;;
        *)      printf '%s' "$STARSHIP_THEMES_DIR/$1" ;;
    esac
}

theme_known() {
    local name id desc
    while IFS='|' read -r name id desc; do
        [ "$id" = "$1" ] && return 0
    done < <(theme_entries)
    return 1
}

starship_theme_display_name() {
    local name id desc
    while IFS='|' read -r name id desc; do
        if [ "$id" = "$1" ]; then
            printf '%s\n' "$name"
            return
        fi
    done < <(theme_entries)
    echo "unknown ($1)"
}

# Copy a Starship config into ~/.dxsbash/themes so it appears in the
# pickers, and print its theme id. Refuses (reason on stderr) files that
# are not *.toml, have unsafe names, are over 256 KB or — when starship
# is installed — cannot be parsed by starship.
import_user_theme() {
    local src="$1" base err
    base="${src##*/}"
    if [ ! -f "$src" ] || [ ! -r "$src" ]; then
        echo "cannot read $src" >&2; return 1
    fi
    if ! user_theme_name_ok "$base"; then
        echo "use a .toml file named with letters, digits, . _ - only" >&2; return 1
    fi
    if [ "$(wc -c < "$src")" -gt 262144 ]; then
        echo "file is larger than 256 KB" >&2; return 1
    fi
    if command -v starship >/dev/null 2>&1; then
        # starship exits 0 on a broken config but always logs this line
        err=$(STARSHIP_CONFIG="$src" timeout 5 starship prompt 2>&1 >/dev/null)
        if printf '%s' "$err" | grep -q 'Unable to parse the config file'; then
            echo "starship cannot parse it: $(printf '%s' "$err" | sed -E 's/\x1b\[[0-9;]*m//g' | grep -m1 -o 'TOML parse error.*')" >&2
            return 1
        fi
    fi
    mkdir -p "$USER_THEMES_DIR"
    # Picking a file that is already in the themes dir (e.g. after
    # editing it) needs no copy
    if ! [ "$src" -ef "$USER_THEMES_DIR/$base" ]; then
        cp "$src" "$USER_THEMES_DIR/$base" || return 1
    fi
    printf 'user/%s' "$base"
}

# Point ~/.config/starship.toml at a preset. Returns 1 if the preset
# file does not exist (nothing is changed in that case). A hand-written
# starship.toml (a regular file) is user data: it is moved aside, never
# deleted, and STARSHIP_BACKUP names the copy (empty if none was made).
STARSHIP_BACKUP=""
link_starship_theme() {
    local src
    src="$(theme_path "$1")"
    STARSHIP_BACKUP=""
    [ -e "$src" ] || return 1
    mkdir -p "$(dirname "$STARSHIP_LINK")"
    if [ -f "$STARSHIP_LINK" ] && [ ! -L "$STARSHIP_LINK" ]; then
        STARSHIP_BACKUP="$STARSHIP_LINK.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$STARSHIP_LINK" "$STARSHIP_BACKUP" || { STARSHIP_BACKUP=""; return 1; }
    fi
    rm -f "$STARSHIP_LINK"
    ln -s "$src" "$STARSHIP_LINK"
}

#=================================================================
# Terminal colors (Konsole / Yakuake)
#
# Each built-in theme has a matching Konsole color scheme shipped in
# assets/konsole/. Applying one sets ColorScheme= in the DXSBash
# Konsole profile (created by setup.sh; Yakuake shares it). Konsole
# reads profiles when it starts, so new windows pick the change up.
#=================================================================
konsole_scheme_for_theme() {
    case "$1" in
        tokyo-night.toml)          echo "DXSBash-TokyoNight" ;;
        gruvbox-rainbow.toml)      echo "DXSBash-Gruvbox" ;;
        catppuccin-powerline.toml|pastel-powerline.toml)
                                   echo "DXSBash-Catppuccin" ;;
        dxs-starship.toml|nerd-font-symbols.toml|bracketed-segments.toml)
                                   echo "DXSBash" ;;
        *)                         echo "" ;;   # user themes: colors untouched
    esac
}

# Set key=value inside [group] of an INI file, creating either as needed
_ini_set() { # file group key value
    local file="$1" tmp="$1.tmp.$$"
    awk -v g="[$2]" -v k="$3" -v v="$4" '
        # headers compared without CR (CRLF files) or surrounding blanks
        /^[ \t]*\[/ { h = $0; sub(/\r$/, "", h); gsub(/^[ \t]+|[ \t]+$/, "", h)
                    if (ing && !done) { print k "=" v; done = 1 } ing = (h == g) }
        ing && index($0, k "=") == 1 { if (!done) { print k "=" v; done = 1 } next }
        { print }
        END {
            if (!done) {
                if (!ing) { if (NR > 0) print ""; print g }
                print k "=" v
            }
        }' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Apply the Konsole scheme matching theme id $1 (default: the current
# theme) and print the scheme name. Returns 1 when there is nothing to
# do: feature off, no DXSBash Konsole profile, or no matching scheme.
apply_terminal_colors() {
    local id="${1:-$CUR_STARSHIP_THEME}" scheme f
    [ "${CUR_TERM_COLORS:-$DEF_TERM_COLORS}" = "true" ] || return 1
    [ -f "$KONSOLE_PROFILE" ] || return 1
    scheme="$(konsole_scheme_for_theme "$id")"
    [ -n "$scheme" ] || return 1
    [ -f "$KONSOLE_SCHEMES_SRC/$scheme.colorscheme" ] || return 1
    mkdir -p "$KONSOLE_DIR"
    for f in "$KONSOLE_SCHEMES_SRC"/*.colorscheme; do
        cp "$f" "$KONSOLE_DIR/"
    done
    _ini_set "$KONSOLE_PROFILE" Appearance ColorScheme "$scheme" || return 1
    echo "$scheme"
}

#=================================================================
# Custom aliases
#
# custom-aliases.sh holds one "alias name='command'" line per alias,
# sourced by bash and zsh. Fish gets a generated twin
# (custom-aliases.fish) rewritten after every change, because the
# quoting rules differ: POSIX single quotes cannot contain a quote
# (written as '\''), fish single quotes use \' and \\ escapes.
#=================================================================
alias_valid_name() {
    [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]
}

# Words that must never become aliases: shell syntax in bash, zsh or
# fish, or core builtins whose shadowing breaks the shell itself
ALIAS_RESERVED=" if then else elif fi case esac for select while until do done
 in function time coproc begin end switch not and or return exit
 alias unalias set unset source export "
alias_reserved() {
    [[ "${ALIAS_RESERVED//$'\n'/ }" == *" $1 "* ]]
}

alias_file_init() {
    [ -f "$ALIAS_FILE" ] && return 0
    mkdir -p "$CONF_DIR"
    cat > "$ALIAS_FILE" <<'EOF'
# DXSBash custom aliases — managed by dxsbash-gui ("Custom aliases").
# Hand edits are fine: keep to one alias per line, in the form
#   alias name='command'
# then run dxsbash-gui once (or 'dxsbash-gui --sync-aliases') so the
# fish copy (custom-aliases.fish) is regenerated.
EOF
}

# Print "name<TAB>command" for every alias, command unescaped.
# bash itself parses the file — so hand-written quoting ("...", the
# '"'"' idiom, trailing comments) decodes exactly as the shell sees it —
# and prints each alias in canonical form: alias name='..'\''..'
alias_list() {
    [ -f "$ALIAS_FILE" ] || return 0
    local line name body
    while IFS= read -r line; do
        [[ "$line" =~ ^alias\ ([A-Za-z_][A-Za-z0-9_.-]*)=\'(.*)\'$ ]] || continue
        name="${BASH_REMATCH[1]}"
        body="${BASH_REMATCH[2]}"
        printf '%s\t%s\n' "$name" "${body//\'\\\'\'/\'}"
    done < <(bash --norc --noprofile -c 'source "$1" >/dev/null 2>&1; alias -p' _ "$ALIAS_FILE")
}

alias_get() {
    alias_list | awk -F'\t' -v n="$1" '$1 == n { sub(/^[^\t]*\t/, ""); print; exit }'
}

alias_count() {
    alias_list | grep -c . || true
}

alias_remove() {
    [ -f "$ALIAS_FILE" ] || return 0
    local line tmp="$ALIAS_FILE.tmp"
    while IFS= read -r line; do
        [[ "$line" == "alias $1="* ]] && continue
        printf '%s\n' "$line"
    done < "$ALIAS_FILE" > "$tmp" && mv "$tmp" "$ALIAS_FILE"
    alias_sync_fish
}

alias_set() {
    local name="$1" cmd="$2"
    alias_valid_name "$name" || return 1
    alias_reserved "$name" && return 1
    alias_file_init
    alias_remove "$name"
    printf "alias %s='%s'\n" "$name" "${cmd//\'/\'\\\'\'}" >> "$ALIAS_FILE"
    alias_sync_fish
}

# Regenerate custom-aliases.fish from custom-aliases.sh
alias_sync_fish() {
    if [ ! -f "$ALIAS_FILE" ]; then
        rm -f "$ALIAS_FISH_FILE"
        return 0
    fi
    mkdir -p "$CONF_DIR"
    local name cmd esc
    {
        echo "# Generated from custom-aliases.sh by DXSBash — do not edit;"
        echo "# edit custom-aliases.sh or use dxsbash-gui instead."
        while IFS=$'\t' read -r name cmd; do
            esc="${cmd//\\/\\\\}"
            esc="${esc//\'/\\\'}"
            printf "alias %s '%s'\n" "$name" "$esc"
        done < <(alias_list)
    } > "$ALIAS_FISH_FILE"
}
