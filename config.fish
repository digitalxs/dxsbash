#!/usr/bin/env fish

# Detect if this is a TTY console.
# Note: fish glob patterns do not support [1-9] bracket classes, so this
# must be a regex match (-r). And it must 'return', never 'exit' — exit
# in config.fish terminates the login shell itself.
if string match -qr '^/dev/tty[0-9]+$' (tty)
    # This is a TTY console - minimal configuration

    # Set a simple prompt
    function fish_prompt
        echo -n (whoami)"@"(hostname)":"(prompt_pwd)" > "
    end

    # Clear fish greeting
    set fish_greeting ""

    # Basic history
    set -g HISTSIZE 1000

    # Basic color for ls
    alias ls='ls --color=auto'

    # Basic XDG paths
    set -x XDG_DATA_HOME "$HOME/.local/share"
    set -x XDG_CONFIG_HOME "$HOME/.config"
    set -x XDG_STATE_HOME "$HOME/.local/state"
    set -x XDG_CACHE_HOME "$HOME/.cache"

    # Skip rest of configuration (requires fish >= 3.4)
    return
end

#######################################################################
# SOURCED ALIAS'S AND FUNCTIONS BY Luis Freitas and others (2025)
#######################################################################
# FISH version converted from dxsbash
# Version 3.5.0
# Start updating fish config:
# nano ~/.config/fish/config.fish
# paste this script and save
# execute command:
# source ~/.config/fish/config.fish
# execute command:
# install_fish_support
# and it will install the necessary software for this script to work.
#######################################################################

# Set XDG directories
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_STATE_HOME "$HOME/.local/state" 
set -x XDG_CACHE_HOME "$HOME/.cache"

# Set Linux Toolbox dir
set -x LINUXTOOLBOXDIR "$HOME/linuxtoolbox"

# Add paths
fish_add_path /usr/sbin
fish_add_path /snap/bin
fish_add_path "$HOME/.composer/vendor/bin"

# Set default editor
set -x EDITOR nano
set -x VISUAL nano

# Set colors for ls, grep, etc.
set -x CLICOLOR 1
set -x LS_COLORS 'no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Set colors for man pages
set -x LESS_TERMCAP_mb \e'[01;31m'
set -x LESS_TERMCAP_md \e'[01;31m'
set -x LESS_TERMCAP_me \e'[0m'
set -x LESS_TERMCAP_se \e'[0m'
set -x LESS_TERMCAP_so \e'[01;44;33m'
set -x LESS_TERMCAP_ue \e'[0m'
set -x LESS_TERMCAP_us \e'[01;32m'

#######################################################
# MACHINE SPECIFIC ALIASES
#######################################################
# Alias's for SSH
# alias SERVERNAME='ssh YOURWEBSITE.com -l USERNAME -p PORTNUMBERHERE'

# Directory shortcuts
alias root='cd /'
alias web='cd /var/www/html'
alias password='pwgen -A'

#######################################################
# Package management — nala/apt (Debian/Ubuntu), dnf (Fedora/RHEL),
# paru/yay/pacman (Arch)
#######################################################
if type -q nala
    alias install='sudo nala update && sudo nala install -y'
    alias update='sudo nala update && sudo nala upgrade -y'
    alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
    alias remove='sudo nala update && sudo nala remove'
    alias removeall='sudo nala purge'
    alias historypkg='nala history'
    alias searchpkg='sudo nala search'
else if type -q apt
    alias install='sudo apt update && sudo apt install -y'
    alias update='sudo apt update && sudo apt upgrade -y'
    alias upgrade='sudo apt update && sudo apt dist-upgrade'
    alias remove='sudo apt remove'
    alias removeall='sudo apt purge'
    alias historypkg='grep " install " /var/log/apt/history.log'
    alias searchpkg='apt search'
else if type -q dnf
    alias install='sudo dnf install -y'
    alias update='sudo dnf upgrade -y'
    alias upgrade='sudo dnf upgrade -y'
    alias remove='sudo dnf remove'
    alias removeall='sudo dnf remove'
    alias historypkg='dnf history'
    alias searchpkg='dnf search'
else if type -q pacman
    # Prefer an AUR helper when present; they wrap pacman and call sudo
    # themselves, so they must not be run under sudo
    if type -q paru
        alias install='paru -S'
        alias update='paru -Syu'
        alias upgrade='paru -Syu'
        alias remove='paru -R'
        alias removeall='paru -Rns'
        alias searchpkg='paru -Ss'
    else if type -q yay
        alias install='yay -S'
        alias update='yay -Syu'
        alias upgrade='yay -Syu'
        alias remove='yay -R'
        alias removeall='yay -Rns'
        alias searchpkg='yay -Ss'
    else
        alias install='sudo pacman -S'
        alias update='sudo pacman -Syu'
        alias upgrade='sudo pacman -Syu'
        alias remove='sudo pacman -R'
        alias removeall='sudo pacman -Rns'
        alias searchpkg='pacman -Ss'
    end
    alias historypkg='grep -E "installed|upgraded|removed" /var/log/pacman.log'
end

#######################################################
# GENERAL ALIASES
#######################################################
# Edit config files
alias efrc='edit ~/.config/fish/config.fish'
# Show help (execute the fish help script, pipe through pager)
function help
    fish ~/.config/fish/fish_help $argv 2>/dev/null | less -RFX
end

# Date and time
alias da='date "+%Y-%m-%d %A %T %Z"'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -iv'
alias delete='rm -rfi'
alias mkdir='mkdir -p'

# System commands
alias ps='ps auxf'
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'
if type -q apt-get
    alias apt-get='sudo apt-get'
end
alias multitail='multitail --no-repeat -c'
alias freshclam='sudo freshclam'

# Editor aliases
if type -q nvim
    alias vim='nvim'
    alias vis='nvim "+set si"'
end
alias vi='vim'
alias svi='sudo vi'
alias snano='sudo nano'
alias spico='sedit'

# Git shortcuts
alias gs='git status'
alias gc='git commit'
alias ga='git add'
alias gd='git diff'
alias gb='git branch'
alias gl='git log'
alias gsb='git show-branch'
alias gco='git checkout'
alias gg='git grep'
alias gk='gitk --all'
alias gr='git rebase'
alias gri='git rebase --interactive'
alias gcp='git cherry-pick'
alias grm='git rm'

# Directory navigation
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Go back to previous directory
alias bd='cd "$OLDPWD"'

# Remove directory and contents
alias rmd='/bin/rm  --recursive --force --verbose'

# Directory listing aliases
alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -ltcrh'              # sort by change time
alias lu='ls -lturh'              # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh | more'         # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              # alphabetical sort
alias lf="ls -l | grep -v '^d'"   # files only
alias ldir="ls -l | grep '^d'"    # directories only
alias lla='ls -Al'                # List and Hidden Files
alias las='ls -A'                 # Hidden Files
alias lls='ls -l'                 # List

# Chmod aliases
alias mx='chmod a+x'
# Recursive 000/644/666/755/777 chmod aliases were removed as dangerous
# (matching .bash_aliases) — one mistyped word could re-permission a tree.

# Search history
function h
    history | grep $argv
end

# Look busy for the boss
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"

# Search processes
function p
    ps aux | grep $argv
end

alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# Find files
function f
    find . | grep $argv
end

# Count files
function countfiles
    for t in files links directories
        echo (find . -type (string sub -l 1 $t) | wc -l) $t
    end 2>/dev/null
end

# Command type checker
function checkcommand
    type $argv
end

# List DXSBash aliases and functions, optionally filtered by a pattern.
# With no args and fzf + tty available, launches an interactive picker
# with a preview pane that shows the definition of the selected entry.
# Usage: aliases            # interactive picker (falls back to plain list)
#        aliases git        # plain grep by substring; pipe-friendly
function aliases
    set -l pattern $argv[1]
    set -l listing (begin
        alias | string replace -r '^alias ' ''
        functions --names 2>/dev/null | string match -rv '^_' | string replace -r '^' 'fn: '
    end | sort -f)

    if test -n "$pattern"
        printf '%s\n' $listing | grep -i --color=auto -- "$pattern"
        return
    end

    if not command -v fzf >/dev/null 2>&1; or not isatty stdout
        printf '%s\n' $listing
        return
    end

    set -l dir (mktemp -d 2>/dev/null)
    if test -z "$dir"
        printf '%s\n' $listing
        return 1
    end

    for fn in (functions --names 2>/dev/null | string match -rv '^_')
        functions -- "$fn" >"$dir/$fn" 2>/dev/null
    end

    set -x __DXSBASH_ALIASES_DIR "$dir"
    printf '%s\n' $listing | fzf \
        --height=80% --reverse --prompt='aliases> ' \
        --preview='L={}; case "$L" in "fn: "*) cat "$__DXSBASH_ALIASES_DIR/${L#fn: }" 2>/dev/null ;; *) echo "$L" ;; esac' \
        --preview-window=down:15:wrap
    set -e __DXSBASH_ALIASES_DIR
    rm -rf "$dir"
end

# Offline cheatsheet over the DXSBash command reference (commands.md),
# rendered with bat when available.
# Usage: cheat              # browse the whole reference
#        cheat git         # only sections/lines mentioning git
function cheat
    set -l doc "$HOME/linuxtoolbox/dxsbash/commands.md"
    if not test -f "$doc"
        echo "cheat: $doc not found (is DXSBash installed?)" >&2
        return 1
    end
    set -l renderer cat
    if type -q bat
        set renderer bat --language=md --style=plain --paging=auto
    else if type -q batcat
        set renderer batcat --language=md --style=plain --paging=auto
    end
    if test (count $argv) -eq 0
        $renderer "$doc"
    else
        grep -i --color=never -- "$argv" "$doc" | $renderer
    end
end

#######################################################
# PER-DIRECTORY ENVIRONMENTS (.dxsbash-env)
#######################################################
# A .dxsbash-env file in a directory is applied automatically when you
# cd there — but only after you trust that exact file once with
# 'envallow'. Trust is bound to the file's content hash: if the file
# changes, it will not load again until you re-run envallow. Use
# 'envdeny' to withdraw trust.
#
# .dxsbash-env files are written in POSIX sh (bash and zsh source them
# directly). Fish applies the portable subset: 'export KEY=VALUE' and
# "alias name='command'" lines; anything else is ignored here.

function __dxs_env_apply
    set -l file $argv[1]
    for line in (grep -E "^(export [A-Za-z_][A-Za-z0-9_]*=|alias [A-Za-z_][A-Za-z0-9_-]*=)" "$file" | string trim)
        if string match -q 'export *' -- $line
            set -l kv (string replace 'export ' '' -- $line)
            set -l parts (string split -m1 '=' -- $kv)
            set -gx $parts[1] (string trim -c "\"'" -- $parts[2])
        else
            set -l kv (string replace 'alias ' '' -- $line)
            set -l parts (string split -m1 '=' -- $kv)
            alias $parts[1] (string trim -c "\"'" -- $parts[2])
        end
    end
end

function __dxs_env_check --on-variable PWD
    status is-interactive; or return 0
    set -l f "$PWD/.dxsbash-env"
    test -f "$f"; or return 0
    set -l allow "$HOME/.dxsbash/env-allow"
    set -l h (sha256sum "$f" 2>/dev/null | awk '{print $1}')
    if test -f "$allow"; and grep -qxF "$h  $PWD" "$allow"
        __dxs_env_apply "$f"
    else
        echo "dxsbash: found .dxsbash-env — run 'envallow' to trust and load it (or 'envdeny' to forget)"
    end
end

function envallow
    set -l f "$PWD/.dxsbash-env"
    set -l allow "$HOME/.dxsbash/env-allow"
    if not test -f "$f"
        echo "envallow: no .dxsbash-env in $PWD" >&2
        return 1
    end
    mkdir -p "$HOME/.dxsbash"
    touch "$allow"
    set -l h (sha256sum "$f" | awk '{print $1}')
    awk -v p="$PWD" '{ line=$0; sub(/^[^ ]+  /, "", line); if (line != p) print }' "$allow" > "$allow.tmp"; and mv "$allow.tmp" "$allow"
    printf '%s  %s\n' "$h" "$PWD" >> "$allow"
    __dxs_env_apply "$f"
    echo "envallow: trusted and loaded $f"
end

function envdeny
    set -l allow "$HOME/.dxsbash/env-allow"
    test -f "$allow"; or return 0
    awk -v p="$PWD" '{ line=$0; sub(/^[^ ]+  /, "", line); if (line != p) print }' "$allow" > "$allow.tmp"; and mv "$allow.tmp" "$allow"
    echo "envdeny: $PWD is no longer trusted"
end

# Network commands
alias openports='netstat -nape --inet'
alias ports='netstat -tulanp'
alias ipview="netstat -anpl | grep :80 | awk '{print \$5}' | cut -d: -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"

# Reboot/shutdown
alias restart='sudo shutdown -r now'
if type -q systemctl
    alias forcerestart='sudo systemctl reboot --force'
else
    alias forcerestart='sudo reboot -f'
end
alias turnoff='sudo poweroff'

# Disk usage
alias diskspace="du -S | sort -n -r | more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# Archive commands
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Log viewing
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:\$//g' | grep -v '[0-9]\$' | xargs tail -f"
# Checksums — sha256 is the promoted default. SHA-1 and MD5 are
# deprecated for integrity verification (collision attacks); they are
# kept only for checking legacy vendor-published hashes.
alias sha256='sha256sum'
alias sha512='sha512sum'
alias sha1='openssl sha1'   # deprecated — prefer sha256

# checksum [sha256|sha512|sha1|md5] <file>... — defaults to sha256
function checksum
    set -l algo sha256
    switch "$argv[1]"
        case sha1 sha256 sha512 md5
            set algo $argv[1]
            set -e argv[1]
    end
    if test (count $argv) -eq 0
        echo "Usage: checksum [sha256|sha512|sha1|md5] <file>..."
        echo "Defaults to sha256. Output matches "$algo"sum for easy verification."
        return 1
    end
    command {$algo}sum $argv
end

# Copy-paste with delay — X11-only (xdotool/xclip are absent on
# Wayland-only or headless setups)
if type -q xdotool; and type -q xclip
    alias clickpaste='sleep 3; xdotool type (xclip -o -selection clipboard)'
end

# Kitty SSH
alias kssh="kitty +kitten ssh"

# Docker cleanup
alias docker-clean='docker container prune -f; docker image prune -f; docker network prune -f; docker volume prune -f'

# Grep with color. Note: do NOT alias grep to rg — ripgrep's flags are
# incompatible with GNU grep (e.g. rg -r means --replace, not recursive).
# ripgrep remains available as `rg`.
alias grep='grep --color=auto'

# Use bat or batcat based on distribution
function get_distribution
    set dtype "unknown"
    
    if test -r /etc/os-release
        set -l distro_id (cat /etc/os-release | grep "^ID=" | cut -d= -f2 | tr -d '"')
        switch $distro_id
            case 'fedora' 'rhel' 'centos' 'rocky' 'almalinux'
                set dtype "redhat"
            case 'sles' 'opensuse*'
                set dtype "suse"
            case 'ubuntu' 'debian'
                set dtype "debian"
            case 'gentoo'
                set dtype "gentoo"
            case 'arch' 'manjaro' 'endeavouros'
                set dtype "arch"
            case 'slackware'
                set dtype "slackware"
            case '*'
                # Check ID_LIKE if dtype is still unknown
                set distro_like (grep -oP '(?<=^ID_LIKE=).+' /etc/os-release | tr -d '"')
                
                if test -n "$distro_like"
                    if string match -q '*fedora*' $distro_like; or string match -q '*rhel*' $distro_like; or string match -q '*centos*' $distro_like
                        set dtype "redhat"
                    else if string match -q '*sles*' $distro_like; or string match -q '*opensuse*' $distro_like
                        set dtype "suse"
                    else if string match -q '*ubuntu*' $distro_like; or string match -q '*debian*' $distro_like
                        set dtype "debian"
                    else if string match -q '*gentoo*' $distro_like
                        set dtype "gentoo"
                    else if string match -q '*arch*' $distro_like
                        set dtype "arch"
                    else if string match -q '*slackware*' $distro_like
                        set dtype "slackware"
                    end
                end
        end
    end
    
    echo $dtype
end

set DISTRIBUTION (get_distribution)
# Use bat/batcat for cat only when actually installed — an unguarded
# alias would break `cat` entirely on systems without the bat package.
if type -q bat
    alias cat='bat'
else if type -q batcat
    alias cat='batcat'
end

#######################################################
# SPECIAL FUNCTIONS
#######################################################
# Edit function
function edit
    if type -q jpico
        jpico -nonotice -linums -nobackups $argv
    else if type -q nano
        nano -c $argv
    else if type -q pico
        pico $argv
    else
        vim $argv
    end
end

# Edit with sudo
function sedit
    if type -q jpico
        sudo jpico -nonotice -linums -nobackups $argv
    else if type -q nano
        sudo nano -c $argv
    else if type -q pico
        sudo pico $argv
    else
        sudo vim $argv
    end
end

# Extract archives
function extract
    for file in $argv
        if test -f $file
            switch $file
                case "*.tar.bz2"
                    tar xvjf $file
                case "*.tar.gz"
                    tar xvzf $file
                case "*.bz2"
                    bunzip2 $file
                case "*.rar"
                    rar x $file
                case "*.gz"
                    gunzip $file
                case "*.tar"
                    tar xvf $file
                case "*.tbz2"
                    tar xvjf $file
                case "*.tgz"
                    tar xvzf $file
                case "*.zip"
                    unzip $file
                case "*.Z"
                    uncompress $file
                case "*.7z"
                    7z x $file
                case "*"
                    echo "don't know how to extract '$file'..."
            end
        else
            echo "'$file' is not a valid file!"
        end
    end
end

# Search for text in files
function ftext
    grep -iIHrn --color=always $argv . | less -r
end

# Copy with progress bar (note: this is simplified from the bash version)
function cpp
    set -l source $argv[1]
    set -l target $argv[2]
    
    if type -q rsync
        rsync --progress $source $target
    else
        cp $source $target
        echo "Copied $source to $target"
    end
end

# Copy and change directory
function cpg
    set -l source $argv[1]
    set -l target $argv[2]
    
    if test -d "$target"
        cp $source $target
        cd $target
    else
        cp $source $target
    end
end

# Move and change directory
function mvg
    set -l source $argv[1]
    set -l target $argv[2]
    
    if test -d "$target"
        mv $source $target
        cd $target
    else
        mv $source $target
    end
end

# Make directory and change to it
function mkdirg
    mkdir -p $argv[1]
    cd $argv[1]
end

# Go up multiple directories
function up
    set -l limit $argv[1]
    set -l path ""
    
    for i in (seq 1 $limit)
        set path "$path../"
    end
    
    cd $path
end

# Show current OS version
function ver
    set dtype (get_distribution)
    
    switch $dtype
        case "redhat"
            if test -s /etc/redhat-release
                cat /etc/redhat-release
            else
                cat /etc/issue
            end
            uname -a
        case "suse"
            cat /etc/SuSE-release
        case "debian"
            lsb_release -a
        case "gentoo"
            cat /etc/gentoo-release
        case "arch"
            cat /etc/os-release
        case "slackware"
            cat /etc/slackware-version
        case "*"
            if test -s /etc/issue
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                return 1
            end
    end
end

# Install dependencies
function install_fish_support
    set dtype (get_distribution)
    
    switch $dtype
        case "redhat"
            sudo dnf install -y fish bash-completion tar bat tree multitail curl wget unzip fontconfig joe git plocate nano zoxide trash-cli fzf pwgen powerline
        case "suse"
            sudo zypper install multitail tree zoxide trash-cli fzf fish
        case "debian"
            sudo apt-get install fish bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline
        case "arch"
            # AUR helpers must NOT run under sudo; they call sudo themselves
            if type -q paru
                paru -S --needed multitail tree zoxide trash-cli fzf fish
            else if type -q yay
                yay -S --needed multitail tree zoxide trash-cli fzf fish
            else
                sudo pacman -S --needed multitail tree zoxide trash-cli fzf fish
            end
        case "slackware"
            echo "No install support for Slackware yet. Sorry my good old friend Patrick V."
        case "*"
            echo "Unknown distribution"
    end
    
    # Install Fisher plugin manager (git.io redirects were shut down by
    # GitHub in 2022 — install from the canonical location instead)
    if not type -q fisher
        echo "Installing Fisher plugin manager..."
        curl -sSfL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    end
    
    # Install useful plugins
    fisher install jorgebucaran/nvm.fish
    fisher install PatrickF1/fzf.fish
    fisher install jethrokuan/z
    fisher install IlanCosman/tide@v5
end

# Show network information
function netinfo
    echo "--------------- Network Information --------------------------"
    nmcli
    echo "--------------------------------------------------------------"
end

# Show IP address information
function whatsmyip
    # Internal IP Lookup
    if type -q ip
        echo -n "Internal IP Addresses: "
        ip addr | grep "inet " | awk '{print $2}' | cut -d/ -f1
    else
        echo -n "Internal IP Addresses: "
        ifconfig | grep "inet " | awk '{print $2}'
    end
    
    # External IP Lookup
    echo -n "External IP Address: "
    curl -s ifconfig.me
end

alias whatismyip=whatsmyip

# View Apache logs
function apachelog
    if test -f /etc/httpd/conf/httpd.conf
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    end
end

# Edit Apache config
function apacheconfig
    if test -f /etc/httpd/conf/httpd.conf
        sedit /etc/httpd/conf/httpd.conf
    else if test -f /etc/apache2/apache2.conf
        sedit /etc/apache2/apache2.conf
    else
        echo "Error: Apache config file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate httpd.conf && locate apache2.conf
    end
end

# Edit PHP config
function phpconfig
    if test -f /etc/php.ini
        sedit /etc/php.ini
    else if test -f /etc/php/php.ini
        sedit /etc/php/php.ini
    else if test -f /etc/php5/php.ini
        sedit /etc/php5/php.ini
    else if test -f /usr/bin/php5/bin/php.ini
        sedit /usr/bin/php5/bin/php.ini
    else if test -f /etc/php5/apache2/php.ini
        sedit /etc/php5/apache2/php.ini
    else
        echo "Error: php.ini file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate php.ini
    end
end

# Edit MySQL config
function mysqlconfig
    if test -f /etc/my.cnf
        sedit /etc/my.cnf
    else if test -f /etc/mysql/my.cnf
        sedit /etc/mysql/my.cnf
    else if test -f /usr/local/etc/my.cnf
        sedit /usr/local/etc/my.cnf
    else if test -f /usr/bin/mysql/my.cnf
        sedit /usr/bin/mysql/my.cnf
    else if test -f ~/my.cnf
        sedit ~/my.cnf
    else if test -f ~/.my.cnf
        sedit ~/.my.cnf
    else
        echo "Error: my.cnf file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate my.cnf
    end
end

# CPU usage function
function cpu
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | awk '{printf("%.1f\n", $1)}'
end

# Trim whitespace
function trim
    echo $argv | string trim
end

# Override the cd command to automatically run ls after cd
function cd
    if count $argv > /dev/null
        builtin cd $argv
        and ls
    else
        builtin cd ~
        and ls
    end
end

# PWD tail - show last 2 directories
function pwdtail
    pwd | awk -F/ '{nlast = NF -1; print $nlast"/"$NF}'
end

# Initialize
if status is-interactive
    # Load user configuration overrides written by dxsbash-config
    # (editor, fastfetch toggle, starship theme, etc.)
    if test -f "$HOME/.dxsbash/user.fish"
        source "$HOME/.dxsbash/user.fish"
    end

    # The PWD watcher does not fire for the login directory — check once
    __dxs_env_check

    # Setup key bindings for Ctrl+F to trigger zoxide interactive
    if type -q zoxide
        function _zoxide_zi_widget
            commandline "zi"
            commandline -f execute
        end
        
        # Bind Ctrl+F to zoxide interactive
        bind \cf _zoxide_zi_widget
    end
    
    # Use zoxide if installed
    if type -q zoxide
        zoxide init fish | source
    end
    
    # Use starship prompt if installed
    if type -q starship
        # In SSH sessions switch to the lightweight preset (no git
        # status scan, no language versions) so the prompt stays
        # instant on slow links. Opt out with DXSBASH_SSH_LITE=false.
        # Heal a stale inherited value first: drop it when this shell
        # is not an SSH session or the inherited path is unreadable
        # (e.g. su to a user with a different HOME).
        if set -q STARSHIP_CONFIG; and string match -q '*/starship-themes/ssh-lite.toml' -- "$STARSHIP_CONFIG"
            if begin; not set -q SSH_CONNECTION; and not set -q SSH_CLIENT; and not set -q SSH_TTY; end
                or not test -r "$STARSHIP_CONFIG"
                set -e STARSHIP_CONFIG
            end
        end
        if begin; set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY; end
            and test "$DXSBASH_SSH_LITE" != "false"
            and not set -q STARSHIP_CONFIG
            and test -f "$HOME/linuxtoolbox/dxsbash/starship-themes/ssh-lite.toml"
            set -gx STARSHIP_CONFIG "$HOME/linuxtoolbox/dxsbash/starship-themes/ssh-lite.toml"
        end
        starship init fish | source
    end
    
    # Run fastfetch if installed and not in SSH session.
    # Set DXSBASH_FASTFETCH=false via dxsbash-config to disable.
    if type -q fastfetch; and not set -q SSH_CLIENT; and not set -q SSH_TTY; and test "$DXSBASH_FASTFETCH" != "false"
        fastfetch
    end

    # Show a one-line security summary at login (opt-in; shown in SSH
    # too, where it matters most). Enable via dxsbash-config. Reads from
    # a cache and refreshes in the background, so startup stays instant.
    if test "$DXSBASH_SECSUMMARY" = "true"; and test -f "$HOME/linuxtoolbox/dxsbash/secsummary.sh"
        bash "$HOME/linuxtoolbox/dxsbash/secsummary.sh" --startup 2>/dev/null
    end
end
