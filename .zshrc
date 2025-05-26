#!/usr/bin/env zsh

#######################################################################
# DXSBash Enhanced Zsh Configuration
# Version 2.3.0
# Author: Luis Miguel P. Freitas
# Website: https://digitalxs.ca
#######################################################################

# CRITICAL: Single TTY detection with early return
if [[ "$(tty 2>/dev/null)" =~ ^/dev/tty[0-9]+$ ]]; then
    # This is a TTY console session - minimal configuration only
    
    # Basic history settings
    HISTFILE=~/.zsh_history
    HISTSIZE=1000
    SAVEHIST=1000
    
    # Basic ZSH options
    setopt appendhistory
    setopt hist_ignore_dups
    setopt hist_ignore_space
    
    # Basic autocompletion
    autoload -Uz compinit && compinit
    
    # Simple prompt for TTY
    PS1='%n@%m:%~%# '
    
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

# Source global definitions if available
if [ -f /etc/zshrc ]; then
    source /etc/zshrc
fi

# Source dxsbash utilities
if [ -f "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh" ]; then
    source "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh"
fi

export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

#######################################################
# ZSH-SPECIFIC SETTINGS
#######################################################

# Enable colors and change prompt
autoload -U colors && colors

# Enable command completion
autoload -Uz compinit && compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Enhanced completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_find_no_dups
setopt hist_reduce_blanks

# Enables cd when just typing a directory path
setopt autocd

# Allow ** glob pattern (recursive matching)
setopt glob_star_short

#######################################################
# ENVIRONMENT VARIABLES
#######################################################

# Set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Allow ctrl-S for history navigation
stty -ixon

# Set the default editor
export EDITOR=nano
export VISUAL=nano

# Color for manpages in less
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# LS colors
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Path additions
path+=/usr/sbin
path+=/snap/bin
path+="$HOME/.composer/vendor/bin"

#######################################################
# DISTRIBUTION DETECTION AND PACKAGE MANAGEMENT
#######################################################

# Distribution detection function
function detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            # Ubuntu is now supported - treat it like Debian
            export DISTRIBUTION="debian"
            return 0
        elif [[ "$ID" == "debian" ]]; then
            export DISTRIBUTION="debian"
            return 0
        elif [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
            export DISTRIBUTION="arch"
            return 0
        else
            echo "⚠️ Warning: Unsupported distribution detected: $ID" >&2
            echo "This configuration is designed for Debian, Ubuntu, or Arch Linux." >&2
            echo "Some features may not work correctly." >&2
            export DISTRIBUTION="unknown"
            return 0  # Continue anyway instead of blocking
        fi
    else
        echo "⚠️ Warning: Unable to detect distribution." >&2
        echo "This configuration is designed for Debian, Ubuntu, or Arch Linux." >&2
        export DISTRIBUTION="unknown"
        return 0  # Continue anyway instead of blocking
    fi
}

# Run distribution check - but don't exit if it fails
detect_distribution

#######################################################
# ALIASES
#######################################################

# Editor aliases
alias spico='sedit'
alias snano='sudo nano'
alias vim='nvim'
alias vi='vim'
alias svi='sudo vi'
alias vis='nvim "+set si"'

# Set preferred tools based on distribution
if command -v rg &> /dev/null; then
    alias grep='rg'
else
    alias grep="/usr/bin/grep --color=auto"
fi

if [[ "$DISTRIBUTION" == "arch" ]]; then
    alias cat='bat'
else
    alias cat='batcat'
fi

# Docker cleanup alias
alias docker-clean='docker container prune -f ; docker image prune -f ; docker network prune -f ; docker volume prune -f'

# Directory aliases
alias root='cd /'
alias web='cd /var/www/html'
alias password='pwgen -A'

# Package management aliases (distribution-specific)
if [[ "$DISTRIBUTION" == "debian" ]]; then
    # Check if nala is available, otherwise use apt
    if command -v nala &> /dev/null; then
        alias install='sudo nala update && sudo nala install -y'
        alias update='sudo nala update && sudo nala upgrade -y'
        alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
        alias remove='sudo nala update && sudo nala remove'
        alias removeall='sudo nala purge'
        alias searchpkg='sudo nala search'
    else
        alias install='sudo apt update && sudo apt install -y'
        alias update='sudo apt update && sudo apt upgrade -y'
        alias upgrade='sudo apt update && sudo apt dist-upgrade'
        alias remove='sudo apt update && sudo apt remove'
        alias removeall='sudo apt purge'
        alias searchpkg='apt search'
    fi
    alias historypkg='grep " install " /var/log/apt/history.log'
elif [[ "$DISTRIBUTION" == "arch" ]]; then
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
    alias historypkg='cat /var/log/pacman.log'
fi

# General aliases
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias ezrc='edit ~/.zshrc'
alias help='less ~/.zshrc_help'
alias da='date "+%Y-%m-%d %A %T %Z"'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -iv'
alias delete='rm -rfi'
alias mkdir='mkdir -p'
alias ps='ps auxf'
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'
alias apt-get='sudo apt-get'
alias multitail='multitail --no-repeat -c'
alias freshclam='sudo freshclam'

# Git aliases
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

# Navigation aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias bd='cd "$OLDPWD"'
alias rmd='/bin/rm --recursive --force --verbose'

# Directory listing aliases
alias la='ls -Alh'
alias ls='ls -aFh --color=always'
alias lx='ls -lXBh'
alias lk='ls -lSrh'
alias lc='ls -ltcrh'
alias lu='ls -lturh'
alias lr='ls -lRh'
alias lt='ls -ltrh'
alias lm='ls -alh |more'
alias lw='ls -xAh'
alias ll='ls -Fls'
alias labc='ls -lap'
alias lf="ls -l | grep -v '^d'"
alias ldir="ls -l | grep '^d'"
alias lla='ls -Al'
alias las='ls -A'
alias lls='ls -l'

# Permission aliases
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# Search aliases
alias h="history | grep "
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"
alias p="ps aux | grep "
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
alias f="find . | grep "
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

# Network aliases
alias openports='netstat -nape --inet'
alias ports='netstat -tulanp'
alias ipview="netstat -anpl | grep :80 | awk {'print \$5'} | cut -d\":\" -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"
alias restart='sudo shutdown -r now'
alias forcerestart='sudo shutdown -r -n now'
alias turnoff='sudo poweroff'

# Disk usage aliases
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# Archive aliases
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"
alias sha1='openssl sha1'
alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'
alias kssh="kitty +kitten ssh"

# Source additional aliases if they exist
if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Editor function
function edit() {
    if [ "$(type -p jpico)" != "" ]; then
        jpico -nonotice -linums -nobackups "$@"
    elif [ "$(type -p nano)" != "" ]; then
        nano -c "$@"
    elif [ "$(type -p pico)" != "" ]; then
        pico "$@"
    else
        vim "$@"
    fi
}

function sedit() {
    if [ "$(type -p jpico)" != "" ]; then
        sudo jpico -nonotice -linums -nobackups "$@"
    elif [ "$(type -p nano)" != "" ]; then
        sudo nano -c "$@"
    elif [ "$(type -p pico)" != "" ]; then
        sudo pico "$@"
    else
        sudo vim "$@"
    fi
}

# Archive extraction function
function extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
            *.tar.bz2) tar xvjf $archive ;;
            *.tar.gz) tar xvzf $archive ;;
            *.bz2) bunzip2 $archive ;;
            *.rar) rar x $archive ;;
            *.gz) gunzip $archive ;;
            *.tar) tar xvf $archive ;;
            *.tbz2) tar xvjf $archive ;;
            *.tgz) tar xvzf $archive ;;
            *.zip) unzip $archive ;;
            *.Z) uncompress $archive ;;
            *.7z) 7z x $archive ;;
            *) echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# Search for text in files
function ftext() {
    grep -iIHrn --color=always "$1" . | less -r
}

# Copy with progress bar
function cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Directory manipulation functions
function cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

function mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

function mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

function up() {
    local d=""
    limit=$1
    for ((i = 1; i <= limit; i++)); do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

# Enhanced cd command
function cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

function pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Network information
function whatsmyip() {
    # Internal IP Lookup
    if command -v ip &> /dev/null; then
        echo -n "Internal IP Addresses: "
        ip addr | grep "inet " | awk '{print $2}' | cut -d/ -f1
    else
        echo -n "Internal IP Addresses: "
        ifconfig | grep "inet " | awk '{print $2}'
    fi
    # External IP Lookup
    echo -n "External IP Address: "
    curl -s ifconfig.me
}
alias whatismyip="whatsmyip"

function netinfo() {
    echo "--------------- Network Information --------------------------"
    nmcli
    echo "--------------------------------------------------------------"
}

# Server administration functions
function apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    fi
}

function apacheconfig() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        sedit /etc/httpd/conf/httpd.conf
    elif [ -f /etc/apache2/apache2.conf ]; then
        sedit /etc/apache2/apache2.conf
    else
        echo "Error: Apache config file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate httpd.conf && locate apache2.conf
    fi
}

function phpconfig() {
    if [ -f /etc/php.ini ]; then
        sedit /etc/php.ini
    elif [ -f /etc/php/php.ini ]; then
        sedit /etc/php/php.ini
    elif [ -f /etc/php5/php.ini ]; then
        sedit /etc/php5/php.ini
    elif [ -f /usr/bin/php5/bin/php.ini ]; then
        sedit /usr/bin/php5/bin/php.ini
    elif [ -f /etc/php5/apache2/php.ini ]; then
        sedit /etc/php5/apache2/php.ini
    else
        echo "Error: php.ini file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate php.ini
    fi
}

function mysqlconfig() {
    if [ -f /etc/my.cnf ]; then
        sedit /etc/my.cnf
    elif [ -f /etc/mysql/my.cnf ]; then
        sedit /etc/mysql/my.cnf
    elif [ -f /usr/local/etc/my.cnf ]; then
        sedit /usr/local/etc/my.cnf
    elif [ -f /usr/bin/mysql/my.cnf ]; then
        sedit /usr/bin/mysql/my.cnf
    elif [ -f ~/my.cnf ]; then
        sedit ~/my.cnf
    elif [ -f ~/.my.cnf ]; then
        sedit ~/.my.cnf
    else
        echo "Error: my.cnf file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate my.cnf
    fi
}

function trim() {
    local var=$*
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace 
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace
    echo -n "$var"
}

#######################################################
# DISTRIBUTION-SPECIFIC SUPPORT FUNCTIONS
#######################################################

function install_zshrc_support() {
    if [[ "$DISTRIBUTION" == "debian" ]]; then
        echo "Installing dependencies for Debian..."
        sudo apt-get install zsh zsh-autosuggestions zsh-syntax-highlighting bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline
    elif [[ "$DISTRIBUTION" == "arch" ]]; then
        echo "Installing dependencies for Arch Linux..."
        if command -v paru &> /dev/null; then
            paru -S --needed multitail tree zoxide trash-cli fzf zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
        elif command -v yay &> /dev/null; then
            yay -S --needed multitail tree zoxide trash-cli fzf zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
        else
            sudo pacman -S --needed multitail tree zoxide trash-cli fzf zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
        fi
    else
        echo "Unsupported distribution. Please install dependencies manually."
        return 1
    fi
    
    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    return 0
}

#######################################################
# ZSH PLUGINS AND PROMPT CONFIGURATION
#######################################################

# CPU usage function for prompt
function cpu() {
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | awk '{printf("%.1f\n", $1)}'
}

# Custom ZSH prompt
function setprompt() {
    local LAST_EXIT_CODE=$?
    
    # Define colors
    local LIGHTGRAY="%F{240}"
    local WHITE="%F{255}"
    local DARKGRAY="%F{238}"
    local RED="%F{160}"
    local LIGHTRED="%F{196}"
    local GREEN="%F{40}"
    local BROWN="%F{130}"
    local YELLOW="%F{226}"
    local BLUE="%F{33}"
    local MAGENTA="%F{125}"
    local CYAN="%F{37}"
    local NOCOLOR="%f"
    
    PROMPT=""
    
    # Show error exit code if there is one
    if [[ $LAST_EXIT_CODE != 0 ]]; then
        PROMPT+="${DARKGRAY}(${LIGHTRED}ERROR${DARKGRAY})-(${RED}Exit Code ${LIGHTRED}${LAST_EXIT_CODE}${DARKGRAY})-(${RED}"
        case $LAST_EXIT_CODE in
            1) PROMPT+="General error" ;;
            2) PROMPT+="Missing keyword, command, or permission problem" ;;
            126) PROMPT+="Permission problem or command is not an executable" ;;
            127) PROMPT+="Command not found" ;;
            128) PROMPT+="Invalid argument to exit" ;;
            129) PROMPT+="Fatal error signal 1" ;;
            130) PROMPT+="Script terminated by Control-C" ;;
            131) PROMPT+="Fatal error signal 3" ;;
            132) PROMPT+="Fatal error signal 4" ;;
            133) PROMPT+="Fatal error signal 5" ;;
            134) PROMPT+="Fatal error signal 6" ;;
            135) PROMPT+="Fatal error signal 7" ;;
            136) PROMPT+="Fatal error signal 8" ;;
            137) PROMPT+="Fatal error signal 9" ;;
            *) PROMPT+="Unknown error code" ;;
        esac
        PROMPT+="${DARKGRAY})${NOCOLOR}"$'\n'
    fi
    
    # Date and time
    PROMPT+="${DARKGRAY}(${CYAN}%W %D{%b-%m} "
    PROMPT+="${BLUE}%D{%I:%M:%S%p}${DARKGRAY})-"
    
    # CPU and jobs
    PROMPT+="(${MAGENTA}CPU $(cpu)%"
    PROMPT+="${DARKGRAY}:${MAGENTA}%j"
    
    # Network connections
    PROMPT+="${DARKGRAY}:${MAGENTA}Net $(awk 'END {print NR}' /proc/net/tcp)"
    PROMPT+="${DARKGRAY})-"
    
    # User info
    if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
        PROMPT+="(${RED}%n@%m"
    else
        PROMPT+="(${RED}%n"
    fi
    
    # Current directory
    PROMPT+="${DARKGRAY}:${BROWN}%~${DARKGRAY})-"
    
    # Total size of files and number of files
    PROMPT+="(${GREEN}$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')${DARKGRAY}:"
    PROMPT+="${GREEN}$(/bin/ls -A -1 | /usr/bin/wc -l)${DARKGRAY})"
    
    # Skip to the next line
    PROMPT+=$'\n'
    
    # User privilege indicator
    if [[ $EUID -ne 0 ]]; then
        PROMPT+="${GREEN}>${NOCOLOR} "   # Normal user
    else
        PROMPT+="${RED}>${NOCOLOR} "    # Root user
    fi
}

# Load ZSH plugins
if [ -d "$HOME/.oh-my-zsh" ]; then
    # Use Oh My Zsh framework if installed
    ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="robbyrussell"  # Default theme
    
    plugins=(
        git
        history
        sudo
        command-not-found
    )
    
    # Check and add syntax highlighting plugin if available
    if [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
        plugins+=(zsh-syntax-highlighting)
    fi
    
    # Check and add autosuggestions plugin if available
    if [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
        plugins+=(zsh-autosuggestions)
    fi
    
    # Load Oh My Zsh
    if [ -f "$ZSH/oh-my-zsh.sh" ]; then
        source "$ZSH/oh-my-zsh.sh"
    fi
else
    # Standalone plugin loading
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    
    if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi
fi

# Keybindings
bindkey '^[[A' history-beginning-search-backward  # Up arrow
bindkey '^[[B' history-beginning-search-forward   # Down arrow
bindkey '^[[Z' reverse-menu-complete              # Shift+Tab
bindkey '^f' _zoxide_zi_widget

# Create widget for zoxide
zle -N _zoxide_zi_widget
function _zoxide_zi_widget() {
    BUFFER="zi"
    zle accept-line
}

# Load FZF if available
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

#######################################################
# INITIALIZE TOOLS
#######################################################

# Initialize Zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize Starship or use custom prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
else
    setprompt
    precmd() { setprompt }
fi

# Show system info at startup if not in SSH session
if command -v fastfetch &> /dev/null && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
    fastfetch
fi
