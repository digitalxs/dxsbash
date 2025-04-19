#!/usr/bin/env zsh

# Reliable TTY detection for ZSH
if [[ "$(tty)" == /dev/tty[1-9]* ]]; then
    # This is a TTY console session - minimal configuration
    
    # Basic history settings
    HISTFILE=~/.zsh_history
    HISTSIZE=1000
    SAVEHIST=1000
    #!/usr/bin/env zsh
# DXSBash ZSH Configuration
# Version: 2.2.6
# Author: Luis Miguel P. Freitas (with modifications)
# Website: https://digitalxs.ca

#######################################################################
# CHECK DISTRIBUTION - BLOCK UBUNTU
#######################################################################

# Detect distribution
function detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "⛔ Ubuntu is not supported by this configuration."
            echo "This configuration is designed for Debian or Arch Linux only."
            echo "Exiting..."
            return 1
        elif [[ "$ID" == "debian" ]]; then
            export DISTRIBUTION="debian"
            return 0
        elif [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
            export DISTRIBUTION="arch"
            return 0
        else
            echo "⚠️ Warning: Unsupported distribution detected."
            echo "This configuration is designed for Debian or Arch Linux."
            echo "Some features may not work correctly."
            export DISTRIBUTION="unknown"
            return 0
        fi
    else
        echo "⚠️ Warning: Unable to detect distribution."
        echo "This configuration is designed for Debian or Arch Linux."
        export DISTRIBUTION="unknown"
        return 0
    fi
}

# Run distribution check
if ! detect_distribution; then
    return 1
fi

#######################################################################
# BASIC DETECTION AND LIGHT CONFIGURATION FOR TTY CONSOLE SESSIONS
#######################################################################

# Reliable TTY detection for ZSH
if [[ "$(tty)" == /dev/tty[1-9]* ]]; then
    # This is a TTY console session - minimal configuration
    HISTFILE=~/.zsh_history
    HISTSIZE=1000
    SAVEHIST=1000
    
    setopt appendhistory
    setopt hist_ignore_dups
    setopt hist_ignore_space
    
    autoload -Uz compinit && compinit
    
    PS1='%n@%m:%~%# '
    
    alias ls='ls --color=auto'
    
    # Exit early, skipping the rest of customizations
    return
fi

#######################################################################
# SOURCE UTILITIES AND GLOBAL DEFINITIONS
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
    alias install='sudo nala update && sudo nala install -y'
    alias update='sudo nala update && sudo nala upgrade -y'
    alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
    alias remove='sudo nala update && sudo nala remove'
    alias removeall='sudo nala purge'
    alias historypkg='nala history'
    alias searchpkg='sudo nala search'
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
    # Basic ZSH options
    setopt appendhistory
    setopt hist_ignore_dups
    setopt hist_ignore_space
    
    # Basic autocompletion
    autoload -Uz compinit && compinit
    
    # Simple prompt for TTY
    PS1='%n@%m:%~%# '
    
    # Basic color for ls
    alias ls='ls --color=auto'
    
    # Exit early, skipping the rest of customizations including starship
    return
fi

#######################################################################
# SOURCED ALIAS'S AND SCRIPTS BY Luis Freitas and others (2025)
# ZSH version converted from dxsbash
# Version 1.0.0
# Start updating .zshrc:
# nano .zshrc
# paste this script and save
# execute command:
# source .zshrc
# execute command:
# install_zshrc_support
# and it will install the necessary software for this script to work.
#######################################################################

# Source global definitions if available
if [ -f /etc/zshrc ]; then
    source /etc/zshrc
fi

#######################################################
# ZSH-SPECIFIC SETTINGS
#######################################################
# Enable colors and change prompt
autoload -U colors && colors

# Enable command completion
autoload -Uz compinit && compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
HISTTIMEFORMAT="%F %T"
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_dups
setopt hist_ignore_space

# Enables cd when just typing a directory path
setopt autocd

# Check window size after each command and update LINES and COLUMNS if necessary
zmodload zsh/terminfo

# Set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Seeing as other scripts will use it might as well export it
export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Allow ctrl-S for history navigation (with ctrl-R)
stty -ixon

# Set the default editor
export EDITOR=nano
export VISUAL=nano
alias spico='sedit'
alias snano='sudo nano'
alias vim='nvim'

# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Check if ripgrep is installed
if command -v rg &> /dev/null; then
    # Alias grep to rg if ripgrep is installed
    alias grep='rg'
else
    # Alias grep to /usr/bin/grep with color options
    alias grep="/usr/bin/grep --color=auto"
fi

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#######################################################
# MACHINE SPECIFIC ALIAS'S
#######################################################
# Alias's for SSH
# alias SERVERNAME='ssh YOURWEBSITE.com -l USERNAME -p PORTNUMBERHERE'
# Alias's to change the directory
alias root='cd /'
alias web='cd /var/www/html'
alias password='pwgen -A'
# Alias's to mount ISO files
# mount -o loop /home/NAMEOFISO.iso /home/ISOMOUNTDIR/
# umount /home/NAMEOFISO.iso
# (Both commands done as root only.)

#######################################################
# Update Computer - Debian - NALA
#######################################################
alias install='sudo nala update && sudo nala install -y'
alias update='sudo nala update && sudo nala upgrade -y'
alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
alias remove='sudo nala update && sudo nala remove'
alias removeall='sudo nala purge'
alias historypkg='nala history'
alias searchpkg='sudo nala search'

#######################################################
# GENERAL ALIAS'S
#######################################################
# To temporarily bypass an alias, we precede the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# Edit this .zshrc file
alias ezrc='edit ~/.zshrc'
# Show help for this .zshrc file
alias help='less ~/.zshrc_help'
# alias to show the date
alias da='date "+%Y-%m-%d %A %T %Z"'
# Alias's to modified commands
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -iv'
alias delete='rm -rfi'
#alias rm='trash -v'
alias mkdir='mkdir -p'
alias ps='ps auxf'
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'
alias apt-get='sudo apt-get'
alias multitail='multitail --no-repeat -c'
alias freshclam='sudo freshclam'
alias vi='vim'
alias svi='sudo vi'
alias vis='nvim "+set si"'

# Git related commands
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

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# cd into the old directory
alias bd='cd "$OLDPWD"'

# Remove a directory and all files
alias rmd='/bin/rm  --recursive --force --verbose '

# Alias's for multiple directory listing commands
alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -ltcrh'              # sort by change time
alias lu='ls -lturh'              # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              # alphabetical sort
alias lf="ls -l | grep -v '^d'"   # files only
alias ldir="ls -l | grep '^d'"    # directories only
alias lla='ls -Al'                # List and Hidden Files
alias las='ls -A'                 # Hidden Files
alias lls='ls -l'                 # List

# alias chmod commands
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# Search command line history
alias h="history | grep "

#Use this for when the boss comes around to look busy.
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"

# Search running processes
alias p="ps aux | grep "
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# Search files in the current folder
alias f="find . | grep "

# Count all files (recursively) in the current folder
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

# To see if a command is aliased, a file, or a built-in command
alias checkcommand="type -t"

# Show open ports
alias openports='netstat -nape --inet'

#Show active ports
alias ports='netstat -tulanp'

# Show current network connections to the server
alias ipview="netstat -anpl | grep :80 | awk {'print \$5'} | cut -d\":\" -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"

# Alias's for safe and forced reboots
alias restart='sudo shutdown -r now'
alias forcerestart='sudo shutdown -r -n now'

# need testing
alias turnoff='sudo poweroff'

# Alias's to show disk space and space used in a folder
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# Alias's for archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Show all logs in /var/log
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"

# SHA1
alias sha1='openssl sha1'
alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'

# KITTY - alias to be able to use kitty features when connecting to remote servers(e.g use tmux on remote server)
alias kssh="kitty +kitten ssh"

# alias to cleanup unused docker containers, images, networks, and volumes
alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '

#######################################################
# SPECIAL FUNCTIONS
#######################################################
# Use the best version of pico installed
edit() {
    if [ "$(type -p jpico)" != "" ]; then
        # Use JOE text editor http://joe-editor.sourceforge.net/
        jpico -nonotice -linums -nobackups "$@"
    elif [ "$(type -p nano)" != "" ]; then
        nano -c "$@"
    elif [ "$(type -p pico)" != "" ]; then
        pico "$@"
    else
        vim "$@"
    fi
}

sedit() {
    if [ "$(type -p jpico)" != "" ]; then
        # Use JOE text editor http://joe-editor.sourceforge.net/
        sudo jpico -nonotice -linums -nobackups "$@"
    elif [ "$(type -p nano)" != "" ]; then
        sudo nano -c "$@"
    elif [ "$(type -p pico)" != "" ]; then
        sudo pico "$@"
    else
        sudo vim "$@"
    fi
}

# Extracts any archive(s) (if unp isn't installed)
extract() {
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

# Searches for text in all files in the current folder
ftext() {
    # -i case-insensitive
    # -I ignore binary files
    # -H causes filename to be printed
    # -r recursive search
    # -n causes line number to be printed
    # optional: -F treat search term as a literal, not a regular expression
    # optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
    grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp() {
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

# Copy and go to the directory
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move and go to the directory
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create and go to the directory
mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

# Goes up a specified number of directories  (i.e. up 4)
up() {
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

# Automatically do an ls after each cd, z, or zoxide
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Show the current distribution
distribution() {
    local dtype="unknown"  # Default to unknown
    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos)
                dtype="redhat"
                ;;
            sles|opensuse*)
                dtype="suse"
                ;;
            ubuntu|debian)
                dtype="debian"
                ;;
            gentoo)
                dtype="gentoo"
                ;;
            arch|manjaro)
                dtype="arch"
                ;;
            slackware)
                dtype="slackware"
                ;;
            *)
                # Check ID_LIKE only if dtype is still unknown
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *fedora*|*rhel*|*centos*)
                            dtype="redhat"
                            ;;
                        *sles*|*opensuse*)
                            dtype="suse"
                            ;;
                        *ubuntu*|*debian*)
                            dtype="debian"
                            ;;
                        *gentoo*)
                            dtype="gentoo"
                            ;;
                        *arch*)
                            dtype="arch"
                            ;;
                        *slackware*)
                            dtype="slackware"
                            ;;
                    esac
                fi
                # If ID or ID_LIKE is not recognized, keep dtype as unknown
                ;;
        esac
    fi
    echo $dtype
}

DISTRIBUTION=$(distribution)
if [ "$DISTRIBUTION" = "redhat" ] || [ "$DISTRIBUTION" = "arch" ]; then
      alias cat='bat'
else
      alias cat='batcat'
fi 

# Show the current version of the operating system
ver() {
    local dtype
    dtype=$(distribution)
    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then
                cat /etc/redhat-release
            else
                cat /etc/issue
            fi
            uname -a
            ;;
        "suse")
            cat /etc/SuSE-release
            ;;
        "debian")
            lsb_release -a
            ;;
        "gentoo")
            cat /etc/gentoo-release
            ;;
        "arch")
            cat /etc/os-release
            ;;
        "slackware")
            cat /etc/slackware-version
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                exit 1
            fi
            ;;
    esac
}

# Automatically install the needed support files for this .zshrc file
install_zshrc_support() {
    local dtype
    dtype=$(distribution)
    case $dtype in
        "redhat")
            sudo yum install multitail tree zoxide trash-cli fzf zsh zsh-completions
            ;;
        "suse")
            sudo zypper install multitail tree zoxide trash-cli fzf zsh zsh-completions
            ;;
        "debian")
            sudo apt-get install zsh zsh-autosuggestions zsh-syntax-highlighting bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline
            ;;
        "arch")
            sudo paru multitail tree zoxide trash-cli fzf zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
            ;;
        "slackware")
            echo "No install support for Slackware yet. Sorry my good old friend Patrick V."
            ;;
        *)
            echo "Unknown distribution"
            ;;
    esac
    
    # Install Oh My Zsh if not already installed (optional but recommended)
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Show current network information
netinfo() {
    echo "--------------- Network Information --------------------------"
    nmcli
    echo "--------------------------------------------------------------"
}

# IP address lookup
alias whatismyip="whatsmyip"
whatsmyip() {
    # Internal IP Lookup.
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

# View Apache logs
apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    fi
}

# Edit the Apache configuration
apacheconfig() {
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

# Edit the PHP configuration file (WILL BE UPDATED VERY SOON)
phpconfig() {
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

# Edit the MySQL configuration file
mysqlconfig() {
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

# Trim leading and trailing spaces (for scripts)
trim() {
    local var=$*
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
    echo -n "$var"
}

#######################################################
# Set the prompt
#######################################################
# CPU usage function for prompt
cpu() {
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' | awk '{printf("%.1f\n", $1)}'
}

# ZSH custom prompt - similar to the Bash prompt but adapted for ZSH
# Only use this if not using Starship prompt
setprompt() {
    local LAST_EXIT_CODE=$?
    
    # Define colors
    local LIGHTGRAY="%F{240}"
    local WHITE="%F{255}"
    local BLACK="%F{0}"
    local DARKGRAY="%F{238}"
    local RED="%F{160}"
    local LIGHTRED="%F{196}"
    local GREEN="%F{40}"
    local LIGHTGREEN="%F{82}"
    local BROWN="%F{130}"
    local YELLOW="%F{226}"
    local BLUE="%F{33}"
    local LIGHTBLUE="%F{75}"
    local MAGENTA="%F{125}"
    local LIGHTMAGENTA="%F{165}"
    local CYAN="%F{37}"
    local LIGHTCYAN="%F{81}"
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

#######################################################
# Initialize prompt system - using Starship if available
#######################################################
# Path inclusions
export PATH=/usr/sbin:$PATH
export PATH=/snap/bin:$PATH
export PATH="$PATH:$HOME/.composer/vendor/bin"

# Check if zoxide is installed and initialize it
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# This section enables zsh-specific plugins

# Check for zsh-syntax-highlighting and source it if available
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Check for zsh-autosuggestions and source it if available
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Use fzf if installed
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# Key bindings - Ctrl+f to trigger zoxide's interactive mode
if command -v zoxide &> /dev/null; then
    bindkey '^f' _zoxide_zi_widget
    zle -N _zoxide_zi_widget
    _zoxide_zi_widget() {
        BUFFER="zi"
        zle accept-line
    }
fi

# Uncomment the setprompt function call below if you want to use the custom prompt
# instead of starship
# setprompt
# PROMPT_COMMAND='setprompt'

# Use starship prompt if available
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Run fastfetch at startup if installed and not in SSH session
if command -v fastfetch &> /dev/null && [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
    fastfetch
fi
