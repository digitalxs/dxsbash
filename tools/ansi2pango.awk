# ansi2pango.awk — convert ANSI-colored terminal text (e.g. the output
# of `starship prompt`) into Pango markup, so it can be displayed with
# its real colors in zenity dialogs or rendered by ImageMagick.
#
# Used by dxsbash-gui.sh (live theme previews) and
# tools/render-theme-previews.sh (README preview images).
# POSIX awk: works with mawk (Debian/Ubuntu default), gawk and busybox.
#
# Variables (-v):
#   fg=#rrggbb    default foreground            (default #e6edf3)
#   bg=#rrggbb    terminal background strip     (default: none)
#   font="..."    Pango font description for the outer span
#   pad=N         spaces of padding each side   (default 0)
#
# Supports SGR: reset, bold, italic, 30-37/90-97/40-47/100-107,
# 38/48;5;n (256 colors) and 38/48;2;r;g;b (truecolor). Other escape
# sequences are dropped.

function hex2(n) { return sprintf("%02x", n) }

function c256(n,    lv, v) {
    if (n < 16) return basic[n]
    if (n < 232) {
        n -= 16
        split("0 95 135 175 215 255", lv, " ")
        return "#" hex2(lv[int(n / 36) + 1]) hex2(lv[int(n / 6) % 6 + 1]) hex2(lv[n % 6 + 1])
    }
    v = 8 + (n - 232) * 10
    return "#" hex2(v) hex2(v) hex2(v)
}

function xml(s) {
    gsub(/&/, "\\&amp;", s)
    gsub(/</, "\\&lt;", s)
    gsub(/>/, "\\&gt;", s)
    return s
}

function reset_state() { cfg = ""; cbg = ""; bold = 0; ital = 0 }

function apply(codes,    c, n, i, k, key) {
    if (codes == "") { reset_state(); return }
    n = split(codes, c, ";")
    for (i = 1; i <= n; i++) {
        k = c[i] + 0
        if (k == 0) reset_state()
        else if (k == 1) bold = 1
        else if (k == 3) ital = 1
        else if (k == 22) bold = 0
        else if (k == 23) ital = 0
        else if (k == 39) cfg = ""
        else if (k == 49) cbg = ""
        else if (k >= 30 && k <= 37) cfg = basic[k - 30]
        else if (k >= 90 && k <= 97) cfg = basic[k - 82]
        else if (k >= 40 && k <= 47) cbg = basic[k - 40]
        else if (k >= 100 && k <= 107) cbg = basic[k - 92]
        else if ((k == 38 || k == 48) && i < n) {
            if (c[i + 1] == 2 && i + 4 <= n) {
                key = "#" hex2(c[i + 2]) hex2(c[i + 3]) hex2(c[i + 4]); i += 4
            } else if (c[i + 1] == 5 && i + 2 <= n) {
                key = c256(c[i + 2] + 0); i += 2
            } else continue
            if (k == 38) cfg = key; else cbg = key
        }
    }
}

function span(t,    a) {
    a = "foreground=\"" (cfg != "" ? cfg : fg) "\""
    if (cbg != "") a = a " background=\"" cbg "\""
    if (bold) a = a " weight=\"bold\""
    if (ital) a = a " style=\"italic\""
    return "<span " a ">" xml(t) "</span>"
}

BEGIN {
    ESC = sprintf("%c", 27)
    if (fg == "") fg = "#e6edf3"
    split("#1b1f24 #ff7b72 #3fb950 #d29922 #58a6ff #bc8cff #39c5cf #b1bac4 " \
          "#6e7681 #ffa198 #56d364 #e3b341 #79c0ff #d2a8ff #56d4dd #ffffff", tmp, " ")
    for (i = 1; i <= 16; i++) basic[i - 1] = tmp[i]
    padding = ""
    for (i = 0; i < pad + 0; i++) padding = padding " "
    reset_state()
    lines = 0
}

{
    line = $0
    gsub(/\r/, "", line)
    # starship brackets escapes for bash/zsh with \001 \002 (and zsh %{ %})
    gsub(/[\001\002]/, "", line)
    out = ""
    while ((p = index(line, ESC "[")) > 0) {
        if (p > 1) out = out span(substr(line, 1, p - 1))
        rest = substr(line, p + 2)
        if (match(rest, /^[0-9;?]*[A-Za-z]/)) {
            if (substr(rest, RLENGTH, 1) == "m") apply(substr(rest, 1, RLENGTH - 1))
            line = substr(rest, RLENGTH + 1)
        } else {
            line = rest
        }
    }
    if (line != "") out = out span(line)
    buf[++lines] = out
}

END {
    # drop leading/trailing empty lines (starship's add_newline)
    first = 1; while (first <= lines && buf[first] == "") first++
    last = lines; while (last >= first && buf[last] == "") last--
    open = "<span"
    if (font != "") open = open " font=\"" font "\""
    if (bg != "") open = open " background=\"" bg "\""
    open = open ">"
    for (i = first; i <= last; i++) {
        printf "%s%s%s%s</span>", open, padding, buf[i], padding
        if (i < last) printf "\n"
    }
    printf "\n"
}
