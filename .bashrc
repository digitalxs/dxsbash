#!/usr/bin/env bash

#######################################################################
# DXSBash Enhanced Bash Configuration
# Version 3.0.5
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
#######################################################################

# CRITICAL: Single TTY detection with early return
if [[ "$(tty 2>/dev/null)" =~ ^/dev/tty[0-9]+$ ]]; then
    # This is a TTY console session - minimal configuration only
    
    # Basic history settings
    export HISTSIZE=1000
    export HISTFILESIZE=2000
    export HISTCONTROL=ignoreboth
    
    # Basic shell options
    shopt -s checkwinsize
    shopt -s histappend
    
    # Simple prompt for TTY
    PS1='\u@\h:\w\$ '
    
    # Basic color support
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    
    # Set basic XDG paths
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state" 
    export XDG_CACHE_HOME="$HOME/.cache"
    
    # EXIT EARLY - Skip all advanced features for TTY sessions
    return
fi

#######################################################################
# ADVANCED CONFIGURATION FOR TERMINAL EMULATORS ONLY
#######################################################################

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Source dxsbash utilities
if [ -f "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh" ]; then
    source "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh"
fi

# Enable bash programmable completion features
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

#######################################################
# EXPORTS AND ENVIRONMENT
#######################################################

# Interactive check for bell setting
iatest=$(expr index "$-" i)
if [[ $iatest -gt 0 ]]; then 
    bind "set bell-style visible"
fi

# History configuration
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T"
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Shell options
shopt -s checkwinsize
shopt -s histappend
PROMPT_COMMAND='history -a'

# XDG directories
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Project directory
export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Allow ctrl-S for history navigation
[[ $- == *i* ]] && stty -ixon

# Enhanced auto-completion for interactive shells
if [[ $iatest -gt 0 ]]; then
    bind "set completion-ignore-case on"
    bind "set show-all-if-ambiguous on"
    bind "set menu-complete-display-prefix on"
    bind "TAB:menu-complete"
    bind '"\e[Z": menu-complete-backward'
fi

# Editor settings
export EDITOR=nano
export VISUAL=nano

# Colors for ls and grep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Grep setup - prefer ripgrep if available
if command -v rg &> /dev/null; then
    alias grep='rg'
else
    alias grep="/usr/bin/grep --color=auto"
fi

# Color for manpages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#######################################################
# DISTRIBUTION DETECTION AND PACKAGE MANAGEMENT
#######################################################

# Improved distribution detection
get_distribution() {
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            ubuntu|debian)
                echo "debian"
                ;;
            arch|manjaro|endeavouros)
                echo "arch"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                echo "redhat"
                ;;
            opensuse*|sles)
                echo "suse"
                ;;
            *)
                # Check ID_LIKE for derivatives
                if [[ "$ID_LIKE" == *ubuntu* ]] || [[ "$ID_LIKE" == *debian* ]]; then
                    echo "debian"
                elif [[ "$ID_LIKE" == *arch* ]]; then
                    echo "arch"
                elif [[ "$ID_LIKE" == *fedora* ]] || [[ "$ID_LIKE" == *rhel* ]]; then
                    echo "redhat"
                else
                    echo "unknown"
                fi
                ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRIBUTION=$(get_distribution)

# Set up package management aliases based on distribution
setup_package_aliases() {
    case "$DISTRIBUTION" in
        "debian")
            # Prefer nala if available, fallback to apt
            if command -v nala &> /dev/null; then
                alias install='sudo nala update && sudo nala install -y'
                alias update='sudo nala update && sudo nala upgrade -y'
                alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
                alias remove='sudo nala update && sudo nala remove'
                alias removeall='sudo nala purge'
                alias historypkg='nala history'
                alias searchpkg='sudo nala search'
            else
                alias install='sudo apt update && sudo apt install -y'
                alias update='sudo apt update && sudo apt upgrade -y'
                alias upgrade='sudo apt update && sudo apt dist-upgrade'
                alias remove='sudo apt remove'
                alias removeall='sudo apt purge'
                alias historypkg='grep " install " /var/log/apt/history.log'
                alias searchpkg='apt search'
            fi
            ;;
        "arch")
            # Check for AUR helpers first, then fallback to pacman
            if command -v paru &> /dev/null; then
                alias install='paru -S'
                alias update='paru -Syu'
                alias upgrade='paru -Syu'
                alias remove='paru -R'
                alias removeall='paru -Rns'
                alias searchpkg='paru -Ss'
            elif command -v yay &> /dev/null; then
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
            fi
            alias historypkg='grep -E "installed|upgraded|removed" /var/log/pacman.log'
            ;;
        *)
            # Generic fallbacks - avoid error messages
            echo "Warning: Unknown distribution, package management aliases not set" >&2
            ;;
    esac
}

# Set up aliases
setup_package_aliases

# Set cat alias based on available commands and distribution
setup_cat_alias() {
    if command -v bat &> /dev/null; then
        alias cat='bat'
    elif command -v batcat &> /dev/null; then
        alias cat='batcat'
    fi
}
setup_cat_alias

#######################################################
# MACHINE SPECIFIC ALIASES
#######################################################

alias root='cd /'
alias web='cd /var/www/html'
alias password='pwgen -A'

# Docker cleanup alias
alias docker-clean='docker container prune -f ; docker image prune -f ; docker network prune -f ; docker volume prune -f'

# Source .bash_aliases if it exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Use the best available editor
edit() {
    if command -v jpico &> /dev/null; then
        jpico -nonotice -linums -nobackups "$@"
    elif command -v nano &> /dev/null; then
        nano -c "$@"
    elif command -v pico &> /dev/null; then
        pico "$@"
    else
        vim "$@"
    fi
}

sedit() {
    if command -v jpico &> /dev/null; then
        sudo jpico -nonotice -linums -nobackups "$@"
    elif command -v nano &> /dev/null; then
        sudo nano -c "$@"
    elif command -v pico &> /dev/null; then
        sudo pico "$@"
    else
        sudo vim "$@"
    fi
}

# Extract archives
extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
                *.tar.bz2) tar xvjf "$archive" ;;
                *.tar.gz) tar xvzf "$archive" ;;
                *.bz2) bunzip2 "$archive" ;;
                *.rar) rar x "$archive" ;;
                *.gz) gunzip "$archive" ;;
                *.tar) tar xvf "$archive" ;;
                *.tbz2) tar xvjf "$archive" ;;
                *.tgz) tar xvzf "$archive" ;;
                *.zip) unzip "$archive" ;;
                *.Z) uncompress "$archive" ;;
                *.7z) 7z x "$archive" ;;
                *) echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# Search for text in files
ftext() {
    grep -iIHrn --color=always "$1" . | less -r
}

# Copy with progress bar (simplified version)
cpp() {
    if command -v rsync &> /dev/null; then
        rsync --progress "$1" "$2"
    else
        cp "$1" "$2"
        echo "Copied $1 to $2"
    fi
}

# Copy and change directory
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move and change directory
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create and change to directory
mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

# Go up multiple directories
up() {
    local d=""
    local limit=$1
    for ((i = 1; i <= limit; i++)); do
        d="$d../"
    done
    cd "$d" || return 1
}

# Enhanced cd with ls
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

# Show last 2 directories of pwd
pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Show current OS version
ver() {
    case "$DISTRIBUTION" in
        "debian")
            if command -v lsb_release &> /dev/null; then
                lsb_release -a
            else
                cat /etc/debian_version
            fi
            ;;
        "arch")
            cat /etc/os-release
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                return 1
            fi
            ;;
    esac
}

# Install support packages
install_bashrc_support() {
    case "$DISTRIBUTION" in
        "debian")
            echo "Installing packages for Debian/Ubuntu..."
            sudo apt update
            if command -v nala &> /dev/null; then
                sudo nala install -y bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git plocate nano fish zoxide trash-cli fzf pwgen powerline neovim ripgrep
            else
                sudo apt install -y bash bash-completion tar batcat tree multitail curl wget unzip fontconfig joe git plocate nano fish zoxide trash-cli fzf pwgen powerline-go neovim ripgrep
            fi
            ;;
        "arch")
            echo "Installing packages for Arch Linux..."
            local installer="sudo pacman"
            if command -v paru &> /dev/null; then
                installer="paru"
            elif command -v yay &> /dev/null; then
                installer="yay"
            fi
            
            $installer -S --needed bash bash-completion bat tree curl wget unzip fontconfig joe git fish zoxide trash-cli fzf ripgrep neovim
            ;;
        *)
            echo "Unsupported distribution. Please install dependencies manually."
            return 1
            ;;
    esac
}

# Network functions
netinfo() {
    echo "--------------- Network Information --------------------------"
    if command -v nmcli &> /dev/null; then
        nmcli
    else
        ip addr show
    fi
    echo "--------------------------------------------------------------"
}

whatsmyip() {
    # Internal IP Lookup
    if command -v ip &> /dev/null; then
        echo -n "Internal IP Addresses: "
        ip addr | grep "inet " | awk '{print $2}' | cut -d/ -f1 | grep -v 127.0.0.1 | tr '\n' ' '
        echo
    else
        echo -n "Internal IP Addresses: "
        ifconfig | grep "inet " | awk '{print $2}' | grep -v 127.0.0.1 | tr '\n' ' '
        echo
    fi
    
    # External IP Lookup
    echo -n "External IP Address: "
    if command -v curl &> /dev/null; then
        curl -s ifconfig.me 2>/dev/null || echo "Unable to determine"
    else
        echo "curl not available"
    fi
    echo
}

alias whatismyip="whatsmyip"

# Server administration functions (simplified error handling)
apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    elif [ -d /var/log/apache2 ]; then
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    else
        echo "Apache log directory not found"
    fi
}

apacheconfig() {
    local config_file=""
    for file in /etc/httpd/conf/httpd.conf /etc/apache2/apache2.conf; do
        if [ -f "$file" ]; then
            config_file="$file"
            break
        fi
    done
    
    if [ -n "$config_file" ]; then
        sedit "$config_file"
    else
        echo "Error: Apache config file could not be found."
        echo "Searching for possible locations:"
        find /etc -name "httpd.conf" -o -name "apache2.conf" 2>/dev/null
    fi
}

# Additional server config functions with better error handling
phpconfig() {
    local php_ini=""
    for file in /etc/php.ini /etc/php/*/apache2/php.ini /etc/php*/php.ini; do
        if [ -f "$file" ]; then
            php_ini="$file"
            break
        fi
    done
    
    if [ -n "$php_ini" ]; then
        sedit "$php_ini"
    else
        echo "Error: php.ini file could not be found."
        find /etc -name "php.ini" 2>/dev/null | head -5
    fi
}

mysqlconfig() {
    local mysql_conf=""
    for file in /etc/my.cnf /etc/mysql/my.cnf /usr/local/etc/my.cnf ~/.my.cnf; do
        if [ -f "$file" ]; then
            mysql_conf="$file"
            break
        fi
    done
    
    if [ -n "$mysql_conf" ]; then
        sedit "$mysql_conf"
    else
        echo "Error: MySQL config file could not be found."
        find /etc -name "my.cnf" 2>/dev/null | head -5
    fi
}

# Utility function
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

#######################################################
# CPU USAGE FUNCTION FOR PROMPT
#######################################################
cpu() {
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | awk '{printf("%.1f\n", $1)}'
}

#######################################################
# CUSTOM PROMPT FUNCTION
#######################################################
__setprompt() {
    local LAST_COMMAND=$?

    # Define colors
    local LIGHTGRAY="\033[0;37m"
    local WHITE="\033[1;37m"
    local BLACK="\033[0;30m"
    local DARKGRAY="\033[1;30m"
    local RED="\033[0;31m"
    local LIGHTRED="\033[1;31m"
    local GREEN="\033[0;32m"
    local LIGHTGREEN="\033[1;32m"
    local BROWN="\033[0;33m"
    local YELLOW="\033[1;33m"
    local BLUE="\033[0;34m"
    local LIGHTBLUE="\033[1;34m"
    local MAGENTA="\033[0;35m"
    local LIGHTMAGENTA="\033[1;35m"
    local CYAN="\033[0;36m"
    local LIGHTCYAN="\033[1;36m"
    local NOCOLOR="\033[0m"

    # Show error exit code if there is one
    if [[ $LAST_COMMAND != 0 ]]; then
        PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
        case $LAST_COMMAND in
            1) PS1+="General error" ;;
            2) PS1+="Missing keyword, command, or permission problem" ;;
            126) PS1+="Permission problem or command is not an executable" ;;
            127) PS1+="Command not found" ;;
            128) PS1+="Invalid argument to exit" ;;
            129) PS1+="Fatal error signal 1" ;;
            130) PS1+="Script terminated by Control-C" ;;
            131) PS1+="Fatal error signal 3" ;;
            132) PS1+="Fatal error signal 4" ;;
            133) PS1+="Fatal error signal 5" ;;
            134) PS1+="Fatal error signal 6" ;;
            135) PS1+="Fatal error signal 7" ;;
            136) PS1+="Fatal error signal 8" ;;
            137) PS1+="Fatal error signal 9" ;;
            *) PS1+="Unknown error code" ;;
        esac
        PS1+="\[${DARKGRAY}\])\[${NOCOLOR}\]\n"
    else
        PS1=""
    fi

    # Date and time
    PS1+="\[${DARKGRAY}\](\[${CYAN}\]\$(date +%a) $(date +%b-'%-m')"
    PS1+="${BLUE} $(date +'%-I':%M:%S%P)\[${DARKGRAY}\])-"

    # CPU usage
    PS1+="(\[${MAGENTA}\]CPU $(cpu)%"

    # Job count
    PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]\j"

    # Network connections (simplified)
    if [ -r /proc/net/tcp ]; then
        PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]Net $(awk 'END {print NR-1}' /proc/net/tcp)"
    fi

    PS1+="\[${DARKGRAY}\])-"

    # User and server
    local SSH_IP="${SSH_CLIENT%% *}"
    if [ -n "$SSH_IP" ]; then
        PS1+="(\[${RED}\]\u@\h"
    else
        PS1+="(\[${RED}\]\u"
    fi

    # Current directory
    PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${DARKGRAY}\])-"

    # Total size and file count
    PS1+="(\[${GREEN}\]$(/bin/ls -lah 2>/dev/null | /bin/grep -m 1 total | /bin/sed 's/total //' || echo '0')\[${DARKGRAY}\]:"
    PS1+="\[${GREEN}\]$(/bin/ls -A -1 2>/dev/null | /usr/bin/wc -l)\[${DARKGRAY}\])"

    # New line and prompt symbol
    PS1+="\n"
    if [[ $EUID -ne 0 ]]; then
        PS1+="\[${GREEN}\]>\[${NOCOLOR}\] "
    else
        PS1+="\[${RED}\]>\[${NOCOLOR}\] "
    fi

    # Secondary prompts
    PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "
    PS3='Please enter a number from above list: '
    PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
}

#######################################################
# PATH SETUP
#######################################################
export PATH="/usr/sbin:/snap/bin:$HOME/.composer/vendor/bin:$PATH"

#######################################################
# KEYBINDINGS AND FINAL SETUP
#######################################################

# Bind Ctrl+f to zi (zoxide interactive) for interactive shells
if [[ $- == *i* ]]; then
    bind '"\C-f":"zi\n"'
fi

# Set up prompt (will be overridden by starship if available)
PROMPT_COMMAND='__setprompt'

# Initialize external tools
if command -v zoxide &> /dev/null; then
    ZOXIDE_INIT=$(zoxide init bash 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$ZOXIDE_INIT" ]; then
        eval "$ZOXIDE_INIT"
    fi
fi

# Use starship prompt if available (overrides custom prompt)
if command -v starship &> /dev/null; then
    STARSHIP_INIT=$(starship init bash 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$STARSHIP_INIT" ]; then
        eval "$STARSHIP_INIT"
    fi
fi
# Make it compatible with claude code
export PATH="$HOME/.local/bin:$PATH"
# To make administrative tool more accessible
export PATH="${PATH}:/usr/local/sbin:/usr/sbin:/sbin"

# Show system info at startup if not in SSH session
if command -v fastfetch &> /dev/null && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
    fastfetch
fi
