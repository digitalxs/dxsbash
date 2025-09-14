#!/usr/bin/env zsh
#=================================================================
# DXSBash Zsh Configuration v3.0.2
# Compatible with: Debian 13, Fedora 42, Arch Linux (latest)
# Author: Luis Miguel P. Freitas
# License: GPL-3.0
#=================================================================

# Early exit for non-interactive shells
[[ -o interactive ]] || return

#=================================================================
# PERFORMANCE OPTIMIZATIONS
#=================================================================

# Enable Zsh's built-in profiling (uncomment to debug slow startup)
# zmodload zsh/zprof

# Compile zcompdump for faster loading
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qNmh+24) ]]; then
    compinit
    compdump
else
    compinit -C
fi

#=================================================================
# MINIMAL CONFIGURATION FOR TTY/RECOVERY MODE
#=================================================================

# Detect if we're in a minimal environment
if [[ "$(tty 2>/dev/null)" =~ ^/dev/tty[0-9]+$ ]] || [[ "${TERM}" == "linux" ]]; then
    # Minimal configuration for TTY sessions
    PS1='%n@%m:%~%# '
    alias ls='ls --color=auto 2>/dev/null || ls'
    alias ll='ls -la'
    alias grep='grep --color=auto 2>/dev/null || grep'
    
    # Basic history
    HISTFILE=~/.zsh_history
    HISTSIZE=1000
    SAVEHIST=1000
    setopt appendhistory
    
    # Basic completion
    autoload -Uz compinit && compinit
    
    return
fi

#=================================================================
# SYSTEM DETECTION
#=================================================================

# Function to check command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe source function
safe_source() {
    [[ -f "$1" ]] && source "$1"
}

# Comprehensive distribution detection
detect_distribution() {
    local distro_id=""
    local distro_family=""
    local distro_version=""
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro_id="${ID:-unknown}"
        distro_version="${VERSION_ID:-unknown}"
        
        case "${distro_id}" in
            # Debian family
            debian|ubuntu|linuxmint|pop|elementary|kali|parrot|raspbian|devuan|mx|antix|pureos|deepin|zorin)
                distro_family="debian"
                ;;
            # RedHat family
            fedora|rhel|centos|rocky|almalinux|oracle|scientific|clearos|eurolinux|amzn)
                distro_family="redhat"
                ;;
            # Arch family
            arch|manjaro|endeavouros|artix|arcolinux|garuda|archcraft|blackarch|parabola|rebornos)
                distro_family="arch"
                ;;
            # SUSE family
            opensuse*|sles|suse|gecko)
                distro_family="suse"
                ;;
            # Gentoo family
            gentoo|funtoo|calculate|redcore)
                distro_family="gentoo"
                ;;
            # Alpine
            alpine|postmarket)
                distro_family="alpine"
                ;;
            # Void
            void)
                distro_family="void"
                ;;
            # NixOS
            nixos)
                distro_family="nixos"
                ;;
            # Slackware family
            slackware|slackel|salix)
                distro_family="slackware"
                ;;
            *)
                # Try to detect from ID_LIKE
                if [[ -n "${ID_LIKE:-}" ]]; then
                    case "${ID_LIKE}" in
                        *debian*|*ubuntu*) distro_family="debian" ;;
                        *fedora*|*rhel*|*centos*) distro_family="redhat" ;;
                        *arch*) distro_family="arch" ;;
                        *suse*) distro_family="suse" ;;
                        *gentoo*) distro_family="gentoo" ;;
                        *) distro_family="unknown" ;;
                    esac
                else
                    distro_family="unknown"
                fi
                ;;
        esac
    else
        distro_family="unknown"
    fi
    
    export DISTRO_ID="${distro_id}"
    export DISTRO_FAMILY="${distro_family}"
    export DISTRO_VERSION="${distro_version}"
}

# Run distribution detection
detect_distribution

#=================================================================
# PRIVILEGE ESCALATION DETECTION
#=================================================================

if command_exists sudo; then
    PRIV_ESC="sudo"
elif command_exists doas; then
    PRIV_ESC="doas"
else
    PRIV_ESC=""
fi

#=================================================================
# ZSH OPTIONS
#=================================================================

# Directory navigation
setopt auto_cd              # Type directory name to cd
setopt auto_pushd          # Make cd push old directory onto stack
setopt pushd_ignore_dups   # Don't push duplicates
setopt pushd_minus         # Exchange + and - for pushd/popd
setopt cdable_vars         # cd into variable values

# History configuration
setopt extended_history       # Save timestamp and duration
setopt hist_expire_dups_first # Expire duplicates first
setopt hist_ignore_dups       # Don't record duplicates
setopt hist_ignore_all_dups   # Delete old recorded duplicates
setopt hist_ignore_space      # Don't record commands starting with space
setopt hist_find_no_dups      # Don't display duplicates in search
setopt hist_reduce_blanks     # Remove extra blanks
setopt hist_verify            # Show command before executing from history
setopt inc_append_history     # Add to history immediately
setopt share_history          # Share history between sessions

# Completion options
setopt always_to_end          # Move cursor to end after completion
setopt auto_menu              # Show completion menu on tab
setopt complete_in_word       # Complete from cursor position
setopt menu_complete          # Cycle through completions with tab
setopt list_ambiguous         # List ambiguous completions immediately
setopt list_packed            # Compact completion list

# Globbing and expansion
setopt extended_glob          # Extended globbing patterns
setopt glob_dots              # Include dotfiles in globbing
setopt glob_star_short        # ** for recursive directory matching
setopt brace_ccl              # Expand {a-z} to a b c ... z
setopt numeric_glob_sort      # Sort numeric filenames numerically

# Job control
setopt long_list_jobs         # List jobs in long format
setopt notify                 # Report job status immediately
setopt auto_resume           # Resume jobs with same name

# Input/Output
setopt correct                # Spelling correction for commands
setopt interactive_comments   # Allow comments in interactive shell
setopt rc_quotes             # Allow 'quotes' in single quotes
setopt mail_warning          # Warn if mail file has been accessed

# Other options
setopt combining_chars       # Combine zero-length chars with base
setopt no_beep              # Don't beep
setopt no_flow_control      # Disable flow control (ctrl-s/ctrl-q)
setopt multios              # Multiple redirections
setopt prompt_subst         # Expand parameters in prompt

#=================================================================
# ENVIRONMENT VARIABLES
#=================================================================

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Create XDG directories
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

# History settings
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=50000
export SAVEHIST=50000

# Editor configuration
if command_exists nvim; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command_exists vim; then
    export EDITOR="vim"
    export VISUAL="vim"
elif command_exists nano; then
    export EDITOR="nano"
    export VISUAL="nano"
else
    export EDITOR="vi"
    export VISUAL="vi"
fi

# Pager configuration
if command_exists less; then
    export PAGER="less"
    export LESS="-R -F -X"
    export LESSCHARSET="UTF-8"
    
    # Less colors for man pages
    export LESS_TERMCAP_mb=$'\E[01;31m'      # Begin blinking
    export LESS_TERMCAP_md=$'\E[01;38;5;74m' # Begin bold
    export LESS_TERMCAP_me=$'\E[0m'          # End mode
    export LESS_TERMCAP_se=$'\E[0m'          # End standout
    export LESS_TERMCAP_so=$'\E[38;5;246m'   # Begin standout
    export LESS_TERMCAP_ue=$'\E[0m'          # End underline
    export LESS_TERMCAP_us=$'\E[04;38;5;146m' # Begin underline
else
    export PAGER="more"
fi

# Terminal settings
export TERM="${TERM:-xterm-256color}"

# Language settings
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# DXSBash directories
export LINUXTOOLBOXDIR="${HOME}/linuxtoolbox"
export DXSBASH_DIR="${LINUXTOOLBOXDIR}/dxsbash"

# Zsh specific
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

#=================================================================
# PATH CONFIGURATION
#=================================================================

# Function to add to PATH (Zsh style)
path_prepend() {
    [[ -d "$1" ]] && path=("$1" $path)
}

path_append() {
    [[ -d "$1" ]] && path+=("$1")
}

# Configure PATH
typeset -U path  # Remove duplicates
path_prepend "/usr/local/sbin"
path_prepend "/usr/local/bin"
path_prepend "${HOME}/.local/bin"
path_prepend "${HOME}/bin"
path_append "/snap/bin"
path_append "${HOME}/.cargo/bin"
path_append "${HOME}/go/bin"
path_append "${HOME}/.npm-global/bin"
path_append "${HOME}/.composer/vendor/bin"

export PATH

#=================================================================
# COLORS AND THEMING
#=================================================================

# Color definitions
typeset -A colors=(
    reset     $'\e[0m'
    bold      $'\e[1m'
    dim       $'\e[2m'
    underline $'\e[4m'
    blink     $'\e[5m'
    reverse   $'\e[7m'
    hidden    $'\e[8m'
    
    black     $'\e[30m'
    red       $'\e[31m'
    green     $'\e[32m'
    yellow    $'\e[33m'
    blue      $'\e[34m'
    magenta   $'\e[35m'
    cyan      $'\e[36m'
    white     $'\e[37m'
    
    bg_black  $'\e[40m'
    bg_red    $'\e[41m'
    bg_green  $'\e[42m'
    bg_yellow $'\e[43m'
    bg_blue   $'\e[44m'
    bg_magenta $'\e[45m'
    bg_cyan   $'\e[46m'
    bg_white  $'\e[47m'
)

# LS Colors
export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# Enable color support
autoload -U colors && colors

#=================================================================
# PACKAGE MANAGER ALIASES
#=================================================================

setup_package_manager() {
    case "${DISTRO_FAMILY}" in
        debian)
            if command_exists nala; then
                alias install="${PRIV_ESC} nala install -y"
                alias update="${PRIV_ESC} nala update && ${PRIV_ESC} nala upgrade -y"
                alias search="nala search"
                alias remove="${PRIV_ESC} nala remove"
                alias autoremove="${PRIV_ESC} nala autoremove"
                alias pkginfo="nala show"
            elif command_exists apt; then
                alias install="${PRIV_ESC} apt update && ${PRIV_ESC} apt install -y"
                alias update="${PRIV_ESC} apt update && ${PRIV_ESC} apt upgrade -y"
                alias search="apt search"
                alias remove="${PRIV_ESC} apt remove"
                alias autoremove="${PRIV_ESC} apt autoremove"
                alias pkginfo="apt show"
            fi
            ;;
            
        redhat)
            if command_exists dnf; then
                alias install="${PRIV_ESC} dnf install -y"
                alias update="${PRIV_ESC} dnf upgrade -y"
                alias search="dnf search"
                alias remove="${PRIV_ESC} dnf remove"
                alias autoremove="${PRIV_ESC} dnf autoremove"
                alias pkginfo="dnf info"
            elif command_exists yum; then
                alias install="${PRIV_ESC} yum install -y"
                alias update="${PRIV_ESC} yum update -y"
                alias search="yum search"
                alias remove="${PRIV_ESC} yum remove"
                alias autoremove="${PRIV_ESC} yum autoremove"
                alias pkginfo="yum info"
            fi
            ;;
            
        arch)
            if command_exists paru; then
                alias install="paru -S --needed"
                alias update="paru -Syu"
                alias search="paru -Ss"
                alias remove="paru -R"
                alias autoremove="paru -Rns \$(paru -Qtdq) 2>/dev/null || echo 'No orphans'"
                alias pkginfo="paru -Si"
            elif command_exists yay; then
                alias install="yay -S --needed"
                alias update="yay -Syu"
                alias search="yay -Ss"
                alias remove="yay -R"
                alias autoremove="yay -Rns \$(yay -Qtdq) 2>/dev/null || echo 'No orphans'"
                alias pkginfo="yay -Si"
            elif command_exists pacman; then
                alias install="${PRIV_ESC} pacman -S --needed"
                alias update="${PRIV_ESC} pacman -Syu"
                alias search="pacman -Ss"
                alias remove="${PRIV_ESC} pacman -R"
                alias autoremove="${PRIV_ESC} pacman -Rns \$(pacman -Qtdq) 2>/dev/null || echo 'No orphans'"
                alias pkginfo="pacman -Si"
            fi
            ;;
            
        suse)
            if command_exists zypper; then
                alias install="${PRIV_ESC} zypper install -y"
                alias update="${PRIV_ESC} zypper update -y"
                alias search="zypper search"
                alias remove="${PRIV_ESC} zypper remove"
                alias autoremove="${PRIV_ESC} zypper remove --clean-deps"
                alias pkginfo="zypper info"
            fi
            ;;
            
        gentoo)
            if command_exists emerge; then
                alias install="${PRIV_ESC} emerge"
                alias update="${PRIV_ESC} emerge --sync && ${PRIV_ESC} emerge -uDN @world"
                alias search="emerge --search"
                alias remove="${PRIV_ESC} emerge --unmerge"
                alias autoremove="${PRIV_ESC} emerge --depclean"
                alias pkginfo="emerge --info"
            fi
            ;;
            
        void)
            if command_exists xbps-install; then
                alias install="${PRIV_ESC} xbps-install -Sy"
                alias update="${PRIV_ESC} xbps-install -Su"
                alias search="xbps-query -Rs"
                alias remove="${PRIV_ESC} xbps-remove"
                alias autoremove="${PRIV_ESC} xbps-remove -O"
                alias pkginfo="xbps-query -S"
            fi
            ;;
            
        alpine)
            if command_exists apk; then
                alias install="${PRIV_ESC} apk add"
                alias update="${PRIV_ESC} apk upgrade"
                alias search="apk search"
                alias remove="${PRIV_ESC} apk del"
                alias autoremove="${PRIV_ESC} apk cache clean"
                alias pkginfo="apk info"
            fi
            ;;
            
        nixos)
            if command_exists nix-env; then
                alias install="nix-env -iA"
                alias update="nix-channel --update && nix-env -u"
                alias search="nix-env -qaP"
                alias remove="nix-env -e"
                alias autoremove="nix-collect-garbage -d"
                alias pkginfo="nix-env -qa --description"
            fi
            ;;
    esac
}

setup_package_manager

#=================================================================
# ALIASES - CROSS-DISTRIBUTION COMPATIBLE
#=================================================================

# Core aliases
alias reload='source ~/.zshrc'
alias zshconfig="${EDITOR} ~/.zshrc"
alias zshreload='source ~/.zshrc'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# Directory stack
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# Listing with modern tools fallback
if command_exists eza; then
    alias ls='eza --group-directories-first'
    alias ll='eza -la --group-directories-first --icons'
    alias la='eza -a --group-directories-first --icons'
    alias lt='eza -T --level=2 --group-directories-first --icons'
    alias l='eza -l --group-directories-first --icons'
elif command_exists exa; then
    alias ls='exa --group-directories-first'
    alias ll='exa -la --group-directories-first --icons'
    alias la='exa -a --group-directories-first --icons'
    alias lt='exa -T --level=2 --group-directories-first --icons'
    alias l='exa -l --group-directories-first --icons'
else
    alias ls='ls --color=auto --group-directories-first 2>/dev/null || ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
    alias lt='ls -alt'
fi

# Color support
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto 2>/dev/null || diff'
alias ip='ip --color=auto 2>/dev/null || ip'

# Clear screen
alias c='clear'
alias cls='clear'

# System information
alias meminfo='free -h'
alias cpuinfo='lscpu'
alias diskinfo='df -h'
alias mountinfo='mount | column -t'

# Process management
alias psg='ps aux | grep -v grep | grep -i'
alias psm='ps aux --sort=-%mem | head -20'
alias psc='ps aux --sort=-%cpu | head -20'

# Network
alias ports='netstat -tulanp 2>/dev/null || ss -tulanp'
alias listening='netstat -tlnp 2>/dev/null || ss -tlnp'
alias myip='curl -s http://ipinfo.io/ip 2>/dev/null || wget -qO- http://ipinfo.io/ip'
alias localip='hostname -I | cut -d" " -f1'

# File operations
alias mkdir='mkdir -pv'
alias tree='tree -C'
alias duh='du -h --max-depth=1 | sort -hr'
alias biggest='find . -type f -exec ls -s {} \; | sort -n -r | head -10'

# Modern tool replacements
if command_exists batcat; then
    alias bat='batcat'
    alias cat='batcat --style=plain'
elif command_exists bat; then
    alias cat='bat --style=plain'
fi

if command_exists rg; then
    alias grep='rg'
elif command_exists ag; then
    alias grep='ag'
fi

if command_exists fd; then
    alias find='fd'
fi

# Archive operations
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Git aliases
if command_exists git; then
    alias g='git'
    alias gs='git status'
    alias gss='git status -s'
    alias ga='git add'
    alias gaa='git add --all'
    alias gc='git commit'
    alias gcm='git commit -m'
    alias gca='git commit --amend'
    alias gp='git push'
    alias gpl='git pull'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gb='git branch'
    alias gba='git branch -a'
    alias gbd='git branch -d'
    alias gbD='git branch -D'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gl='git log --oneline --graph --decorate'
    alias gla='git log --oneline --graph --decorate --all'
    alias glg='git log --graph --pretty=format:"%C(yellow)%h%C(reset) - %C(green)(%cr)%C(reset) %s %C(dim white)- %an%C(reset) %C(auto)%d%C(reset)"'
    alias gst='git stash'
    alias gstp='git stash pop'
    alias gstl='git stash list'
    alias gr='git remote'
    alias grv='git remote -v'
    alias gf='git fetch'
    alias gm='git merge'
    alias grb='git rebase'
fi

# Docker aliases
if command_exists docker; then
    alias d='docker'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs'
    alias dstop='docker stop $(docker ps -q)'
    alias drm='docker rm $(docker ps -aq)'
    alias drmi='docker rmi $(docker images -q)'
    alias dprune='docker system prune -af'
    alias dc='docker-compose'
    alias dcup='docker-compose up'
    alias dcupd='docker-compose up -d'
    alias dcdown='docker-compose down'
fi

# Kubernetes aliases
if command_exists kubectl; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kaf='kubectl apply -f'
    alias kdel='kubectl delete'
    alias klog='kubectl logs'
    alias kexec='kubectl exec -it'
fi

# Systemd aliases
if command_exists systemctl; then
    alias systart='${PRIV_ESC} systemctl start'
    alias systop='${PRIV_ESC} systemctl stop'
    alias syrestart='${PRIV_ESC} systemctl restart'
    alias systatus='systemctl status'
    alias syenable='${PRIV_ESC} systemctl enable'
    alias sydisable='${PRIV_ESC} systemctl disable'
    alias syjobs='systemctl list-units --type=service'
fi

# Editor shortcuts
alias e="${EDITOR}"
alias se="${PRIV_ESC} ${EDITOR}"

# Help command
alias help='cat ~/.zshrc_help 2>/dev/null || echo "Help file not found"'

# Suffix aliases (Zsh specific)
alias -s {txt,md,markdown}="${EDITOR}"
alias -s {jpg,jpeg,png,gif}="xdg-open 2>/dev/null || open"
alias -s {pdf,doc,docx}="xdg-open 2>/dev/null || open"
alias -s {mp3,mp4,avi,mkv}="xdg-open 2>/dev/null || open"
alias -s {html,htm}="xdg-open 2>/dev/null || open"

# Global aliases (Zsh specific)
alias -g L='| less'
alias -g G='| grep'
alias -g T='| tail'
alias -g H='| head'
alias -g W='| wc -l'
alias -g N='> /dev/null 2>&1'

#=================================================================
# FUNCTIONS - CROSS-DISTRIBUTION COMPATIBLE
#=================================================================

# Enhanced cd with auto-ls
cd() {
    builtin cd "$@" && ls
}

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.deb)       ar x "$1"        ;;
            *.rpm)       rpm2cpio "$1" | cpio -idmv ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Search for text in files
ftext() {
    if command_exists rg; then
        rg --color=always "$@" | less -R
    elif command_exists ag; then
        ag --color "$@" | less -R
    else
        grep -r --color=always "$@" . | less -R
    fi
}

# Find file by name
fname() {
    if command_exists fd; then
        fd "$@"
    else
        find . -name "*$@*" 2>/dev/null
    fi
}

# Directory sizes
dirsize() {
    du -sh "${1:-.}"/* 2>/dev/null | sort -h
}

# Show PATH
path() {
    echo -e "${PATH//:/\\n}"
}

# Backup file with timestamp
backup() {
    if [[ -e "$1" ]]; then
        cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backup created: $1.backup.$(date +%Y%m%d_%H%M%S)"
    else
        echo "File not found: $1"
    fi
}

# IP information
ipinfo() {
    echo "Local IP addresses:"
    if command_exists ip; then
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
    else
        ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
    fi
    echo -e "\nPublic IP address:"
    curl -s http://ipinfo.io/ip 2>/dev/null || echo "Unable to fetch public IP"
}

# System information
sysinfo() {
    print -P "%B%F{green}System Information%f%b"
    echo "==================="
    print -P "%F{green}Hostname:%f $(hostname)"
    print -P "%F{green}OS:%f ${(C)DISTRO_ID} ${DISTRO_VERSION} (${DISTRO_FAMILY})"
    print -P "%F{green}Kernel:%f $(uname -r)"
    print -P "%F{green}Architecture:%f $(uname -m)"
    print -P "%F{green}CPU:%f $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    print -P "%F{green}Memory:%f $(free -h | awk '/^Mem:/ {print $2 " total, " $3 " used"}')"
    print -P "%F{green}Disk:%f $(df -h / | awk 'NR==2 {print $2 " total, " $3 " used (" $5 ")"}')"
    print -P "%F{green}Load:%f $(uptime | awk -F'load average:' '{print $2}')"
    print -P "%F{green}Uptime:%f $(uptime -p)"
    print -P "%F{green}Shell:%f Zsh ${ZSH_VERSION}"
}

# Weather (works everywhere)
weather() {
    local location="${1:-}"
    curl -s "http://wttr.in/${location}?format=3" 2>/dev/null || echo "Unable to fetch weather"
}

# Quick notes
note() {
    local note_file="${HOME}/notes.txt"
    if [[ $# -eq 0 ]]; then
        if [[ -f "$note_file" ]]; then
            cat "$note_file"
        else
            echo "No notes found"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$note_file"
        echo "Note added"
    fi
}

# Process lookup
psfind() {
    ps aux | grep -v grep | grep -i "$1"
}

# Kill process by name
pskill() {
    local pid
    pid=$(ps aux | grep -v grep | grep -i "$1" | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "Killing process: $1 (PID: $pid)"
        kill $pid
    else
        echo "Process not found: $1"
    fi
}

# CPU usage
cpu_usage() {
    if [[ -f /proc/stat ]]; then
        grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f%%\n", usage}'
    elif command_exists top; then
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    else
        echo "Unable to determine CPU usage"
    fi
}

# Memory usage
mem_usage() {
    free | awk '/^Mem:/ {printf "%.1f%%\n", $3/$2 * 100}'
}

# Disk usage for current directory
disk_usage() {
    df -h . | awk 'NR==2 {print $5}'
}

# Install DXSBash dependencies
install_dxsbash_deps() {
    echo "Installing DXSBash dependencies for ${(C)DISTRO_ID}..."
    
    local deps="curl wget git tar unzip fontconfig zsh"
    
    case "${DISTRO_FAMILY}" in
        debian)
            deps="$deps bat fd-find ripgrep fzf neovim trash-cli zsh-autosuggestions zsh-syntax-highlighting"
            ;;
        redhat)
            deps="$deps bat fd-find ripgrep fzf neovim"
            ;;
        arch)
            deps="$deps bat fd ripgrep fzf neovim trash-cli starship zoxide zsh-completions zsh-autosuggestions zsh-syntax-highlighting"
            ;;
    esac
    
    echo "Installing: $deps"
    install $deps
}

# Update DXSBash
update_dxsbash() {
    if [[ -f "${DXSBASH_DIR}/updater.sh" ]]; then
        bash "${DXSBASH_DIR}/updater.sh"
    else
        echo "DXSBash updater not found. Please check your installation."
    fi
}

# Zsh specific: Command not found handler
command_not_found_handler() {
    print -P "%F{red}Command not found: %B$1%b%f"
    
    # Suggest installation if package manager has command-not-found
    if command_exists command-not-found; then
        command-not-found "$1"
    elif [[ -x /usr/lib/command-not-found ]]; then
        /usr/lib/command-not-found "$1"
    else
        print -P "%F{yellow}Try: %Bsearch $1%b to find the package%f"
    fi
    
    return 127
}

#=================================================================
# PLUGIN MANAGEMENT
#=================================================================

# Function to safely load plugins
load_plugin() {
    local plugin_path="$1"
    [[ -f "$plugin_path" ]] && source "$plugin_path"
}

# Oh My Zsh Configuration (if installed)
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    
    # Theme (use robbyrussell as fallback)
    ZSH_THEME="robbyrussell"
    
    # Plugins to load
    plugins=(
        git
        docker
        kubectl
        history
        sudo
        command-not-found
        colored-man-pages
        extract
    )
    
    # Add distribution-specific plugins
    case "${DISTRO_FAMILY}" in
        debian|ubuntu)
            plugins+=(ubuntu debian)
            ;;
        arch)
            plugins+=(archlinux)
            ;;
        redhat)
            plugins+=(dnf yum)
            ;;
    esac
    
    # Load Oh My Zsh
    source "$ZSH/oh-my-zsh.sh"
else
    # Manual plugin loading for systems without Oh My Zsh
    
    # Zsh autosuggestions
    for dir in \
        /usr/share/zsh-autosuggestions \
        /usr/share/zsh/plugins/zsh-autosuggestions \
        /usr/local/share/zsh-autosuggestions \
        /opt/homebrew/share/zsh-autosuggestions \
        ${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions
    do
        if [[ -f "$dir/zsh-autosuggestions.zsh" ]]; then
            source "$dir/zsh-autosuggestions.zsh"
            break
        fi
    done
    
    # Zsh syntax highlighting
    for dir in \
        /usr/share/zsh-syntax-highlighting \
        /usr/share/zsh/plugins/zsh-syntax-highlighting \
        /usr/local/share/zsh-syntax-highlighting \
        /opt/homebrew/share/zsh-syntax-highlighting \
        ${ZDOTDIR:-$HOME}/.zsh/zsh-syntax-highlighting
    do
        if [[ -f "$dir/zsh-syntax-highlighting.zsh" ]]; then
            source "$dir/zsh-syntax-highlighting.zsh"
            break
        fi
    done
    
    # Zsh history substring search
    for dir in \
        /usr/share/zsh-history-substring-search \
        /usr/share/zsh/plugins/zsh-history-substring-search \
        /usr/local/share/zsh-history-substring-search \
        ${ZDOTDIR:-$HOME}/.zsh/zsh-history-substring-search
    do
        if [[ -f "$dir/zsh-history-substring-search.zsh" ]]; then
            source "$dir/zsh-history-substring-search.zsh"
            # Bind keys for history substring search
            bindkey '^[[A' history-substring-search-up
            bindkey '^[[B' history-substring-search-down
            bindkey '^P' history-substring-search-up
            bindkey '^N' history-substring-search-down
            break
        fi
    done
fi

#=================================================================
# COMPLETION SYSTEM
#=================================================================

# Initialize completion system
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"

# Completion options
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Completion formatting
zstyle ':completion:*:descriptions' format '%B%F{yellow}--- %d ---%f%b'
zstyle ':completion:*:messages' format '%B%F{purple}--- %d ---%f%b'
zstyle ':completion:*:warnings' format '%B%F{red}No matches for:%f %F{yellow}%d%f%b'
zstyle ':completion:*:corrections' format '%B%F{green}--- %d (errors: %e) ---%f%b'
zstyle ':completion:*' group-name ''

# Specific completions
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Directory completion
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' ignore-parents parent pwd

# Host completion
zstyle ':completion:*:hosts' hosts $(awk '/^[^#]/ {print $2}' /etc/hosts 2>/dev/null)

# SSH/SCP/RSYNC completion
if [[ -r ~/.ssh/known_hosts ]]; then
    _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*})
    zstyle ':completion:*:(ssh|scp|rsync):*' hosts $_ssh_hosts
fi

#=================================================================
# KEY BINDINGS
#=================================================================

# Emacs key bindings (default)
bindkey -e

# History search
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# Navigate words with ctrl+arrow
bindkey '^[[1;5C' forward-word   # Ctrl+Right
bindkey '^[[1;5D' backward-word  # Ctrl+Left

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Delete key
bindkey '^[[3~' delete-char

# Edit command line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Bind Ctrl+F for zoxide interactive (if available)
if command_exists zoxide; then
    bindkey -s '^F' 'zi\n'
fi

#=================================================================
# PROMPT CONFIGURATION
#=================================================================

# Enable prompt substitution
setopt prompt_subst

# Git info for prompt
git_info() {
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        local status=""
        git diff --quiet || status+="*"
        git diff --cached --quiet || status+="+"
        [[ -n "$(git ls-files --others --exclude-standard)" ]] && status+="?"
        echo " %F{magenta}($branch$status)%f"
    fi
}

# Default prompt (if not using Starship)
if ! command_exists starship; then
    # Simple but informative prompt
    PROMPT='%F{green}%n%f@%F{blue}%m%f:%F{yellow}%~%f$(git_info)
%(?:%F{green}❯%f:%F{red}❯%f) '
    
    # Right prompt with time
    RPROMPT='%F{240}%*%f'
fi

#=================================================================
# EXTERNAL TOOLS INTEGRATION
#=================================================================

# FZF integration
if command_exists fzf; then
    # Try to source FZF files from various locations
    for dir in \
        /usr/share/fzf \
        /usr/local/opt/fzf/shell \
        /opt/homebrew/opt/fzf/shell \
        ${HOME}/.fzf
    do
        [[ -f "$dir/key-bindings.zsh" ]] && source "$dir/key-bindings.zsh"
        [[ -f "$dir/completion.zsh" ]] && source "$dir/completion.zsh"
    done
    
    # FZF configuration
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
    
    # Use fd or ripgrep if available
    if command_exists fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    elif command_exists rg; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Zoxide integration
if command_exists zoxide; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
if command_exists starship; then
    eval "$(starship init zsh)"
fi

# Atuin history
if command_exists atuin; then
    eval "$(atuin init zsh)"
fi

# Direnv
if command_exists direnv; then
    eval "$(direnv hook zsh)"
fi

# thefuck
if command_exists thefuck; then
    eval "$(thefuck --alias)"
fi

#=================================================================
# STARTUP TASKS
#=================================================================

# Welcome message and system info
if [[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]; then
    # Run fastfetch/neofetch if available
    if command_exists fastfetch; then
        fastfetch
    elif command_exists neofetch; then
        neofetch
    fi
    
    # Welcome message
    print -P "%F{green}Welcome to DXSBash on ${(C)DISTRO_ID} ${DISTRO_VERSION}%f"
    print -P "Type %F{yellow}help%f for DXSBash commands, %F{yellow}sysinfo%f for system information"
fi

# Source additional configurations
safe_source ~/.zshrc.local
safe_source ~/.zsh_aliases
safe_source "${DXSBASH_DIR}/dxsbash-utils.sh"

#=================================================================
# CLEANUP AND PERFORMANCE
#=================================================================

# Remove duplicate entries from PATH
typeset -U PATH path

# Compile functions for faster loading
if [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]]; then
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
fi

# Uncomment to profile startup time
# zprof

#=================================================================
# END OF ZSHRC
#=================================================================