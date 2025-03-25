#!/bin/bash
#
# .bash_aliases - Professional-grade aliases for productivity
# Part of dxsbash environment
#

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'                 # Go to previous directory

# Directory views
alias ls='ls -hF --color=auto'    # Add colors for filetype recognition
alias la='ls -A'                  # Show hidden files
alias ll='ls -alh'                # Long list format with human-readable sizes
alias l='ls -CF'                  # Columnized list
alias lt='ls -lt'                 # List by time
alias ltr='ls -ltr'               # List by time, reverse order
alias lss='ls -lahSr'             # List by size
alias lsd="ls -lF | grep --color=never '^d'"  # List only directories

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safer file operations
alias rm='rm -i'                  # Confirm before removing
alias cp='cp -i'                  # Confirm before overwriting
alias mv='mv -i'                  # Confirm before overwriting
alias ln='ln -i'                  # Confirm before overwriting
alias del='rm -r'                 # Delete recursively
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Create directories that don't exist
alias mkdir='mkdir -p'
alias md='mkdir -p'

# Disk space and usage
alias df='df -h'                  # Human-readable sizes
alias du='du -h'                  # Human-readable sizes
alias free='free -m'              # Show memory in megabytes
alias space='du -shc * | sort -rh'  # Sort folders by size

# Process management
alias ps='ps aux'                 # Detailed processes
alias psg='ps aux | grep -v grep | grep -i -e'  # Search for process
alias psr='ps aux | sort -rn -k 3 | head -5'    # Top 5 processes by memory
alias pst='ps aux | sort -rn -k 4 | head -5'    # Top 5 processes by CPU
alias psmem='ps auxf | sort -nr -k 4'           # Sorted by memory usage
alias pscpu='ps auxf | sort -nr -k 3'           # Sorted by CPU usage

# System info
alias meminfo='free -m -l -t'     # Memory info
alias cpuinfo='lscpu'             # CPU info
alias df='df -h'                  # Human-readable disk info
alias diskinfo='df -h'            # Disk info
alias ports='netstat -tulanp'     # Active ports
alias services='systemctl --type=service'  # List services

# IP information
alias myip='curl -s https://api.ipify.org && echo'  # Public IP
alias localip='ip -br a'          # Local IP addresses
alias ips="ip -c a | grep 'inet ' | awk '{print \$2}'"  # All IPs

# Network utilities
alias ping='ping -c 5'            # Ping with 5 packets
alias fastping='ping -c 100 -s.2' # Quick ping
alias ports='netstat -tulanp'     # Show open ports
alias listening='netstat -tlnp'   # Listening connections
alias http-serve='python3 -m http.server'  # Simple HTTP server

# Package management (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    alias update='sudo apt-get update && sudo apt-get upgrade'
    alias install='sudo apt-get install'
    alias remove='sudo apt-get remove'
    alias search='apt-cache search'
    alias purge='sudo apt-get purge'
    alias apti='sudo apt-get install'
    alias apts='apt-cache search'
    alias aptr='sudo apt-get remove'
    alias cleanup='sudo apt-get autoremove && sudo apt-get autoclean'
fi

# Package management (Fedora/RHEL)
if command -v dnf &> /dev/null; then
    alias update='sudo dnf update'
    alias install='sudo dnf install'
    alias remove='sudo dnf remove'
    alias search='dnf search'
    alias cleanup='sudo dnf autoremove'
fi

# Package management (Arch)
if command -v pacman &> /dev/null; then
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -Rs'
    alias search='pacman -Ss'
    alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'  # Remove orphans
fi

# Time and date
alias now='date +"%T"'
alias nowtime='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias cal='cal -3'                # Show 3 months

# Directory management
alias mkdir='mkdir -pv'           # Create with parents and verbose
alias md='mkdir -p'
alias rd='rmdir'
alias rmd='rm -rf'                # Dangerous! Remove directory and its contents

# Command history
alias h='history'
alias hg='history | grep'

# Path information
alias path='echo -e ${PATH//:/\\n}'  # Show PATH entries one per line
alias findfile='find . -type f -name'
alias finddir='find . -type d -name'

# Shortcuts for editing and sourcing configuration files
alias ebrc='$EDITOR ~/.bashrc'
alias sbrc='source ~/.bashrc'
alias ealias='$EDITOR ~/.bash_aliases'
alias salias='source ~/.bash_aliases'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias gf='git fetch'
alias gd='git diff'
alias gb='git branch'
alias gt='git tag'
alias gm='git merge'
alias gr='git rebase'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gst='git stash'
alias gstp='git stash pop'
alias gundo='git reset --soft HEAD~1'  # Undo last commit

# Docker aliases
if command -v docker &> /dev/null; then
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias drun='docker run -it'
    alias dip='docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'
    alias dlogs='docker logs'
    alias dclean='docker system prune -a'
    alias dstop='docker stop $(docker ps -q)'  # Stop all containers
fi

# Docker Compose aliases
if command -v docker-compose &> /dev/null; then
    alias dc='docker-compose'
    alias dcup='docker-compose up -d'
    alias dcdown='docker-compose down'
    alias dcrestart='docker-compose restart'
    alias dclogs='docker-compose logs -f'
fi

# Kubernetes aliases
if command -v kubectl &> /dev/null; then
    alias k='kubectl'
    alias kg='kubectl get'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgn='kubectl get nodes'
    alias kd='kubectl describe'
    alias kdp='kubectl describe pod'
    alias kl='kubectl logs'
    alias ke='kubectl exec -it'
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'
    alias kctx='kubectl config use-context'
    alias kns='kubectl config set-context --current --namespace'
fi

# Python developer shortcuts
alias py='python3'
alias py2='python2'
alias pip='pip3'
alias pipinstall='pip install -r requirements.txt'
alias ve='python3 -m venv ./venv'  # Create virtual environment
alias va='source ./venv/bin/activate'  # Activate virtual environment
alias vd='deactivate'  # Deactivate virtual environment

# JavaScript/Node.js developer shortcuts
if command -v npm &> /dev/null; then
    alias ni='npm install'
    alias nid='npm install --save-dev'
    alias nig='npm install -g'
    alias ns='npm start'
    alias nt='npm test'
    alias nb='npm run build'
    alias nr='npm run'
    alias noup='npm update'
fi

# Quick shortcuts for tools
alias vim='nvim'  # Use neovim if available
alias svim='sudo nvim'
alias e='$EDITOR'  # Use default editor
alias v='vim'
alias tmux='tmux -2'  # Force 256 colors
alias t='tmux'
alias ta='tmux attach'
alias tn='tmux new-session'
alias tls='tmux list-sessions'

# System operations
alias reboot='sudo reboot'
alias poweroff='sudo poweroff'
alias halt='sudo halt'
alias shutdown='sudo shutdown -h now'
alias suspend='systemctl suspend'

# Search for files, excluding .git directories
alias findtext='find . -type f -not -path "*/\.git/*" -exec grep -l'
alias findf='find . -type f -not -path "*/\.git/*" -name'
alias findd='find . -type d -not -path "*/\.git/*" -name'

# Check weather
alias weather='curl wttr.in'  # Weather for current location
alias weather-short='curl "wttr.in?format=3"'  # Compact weather

# Clipboard operations
if command -v xclip &> /dev/null; then
    alias setclip='xclip -selection c'
    alias getclip='xclip -selection c -o'
fi

# Productivity
alias countdown='for i in $(seq $1 -1 1); do echo $i; sleep 1; done; echo "Time is up!"'
alias timer='time read -p "Press Enter to stop timer..."'
alias random-string='openssl rand -base64 32'  # Generate random string
alias calc='bc -l'  # Calculator

# Common typos
alias sl='ls'
alias pdw='pwd'
alias cta='cat'
alias gerp='grep'
alias grpe='grep'

# Show external IP address
alias myip='curl -s https://api.ipify.org && echo'

# Generate a secure password
alias genpass='openssl rand -base64 12'

# Compress and extract archives
alias tarball='tar -czvf'  # Usage: tarball archive.tar.gz folder/
alias untar='tar -xzvf'    # Usage: untar archive.tar.gz

# List open ports
alias openports='netstat -tulanp'

# Better execution permissions
alias ax='chmod a+x'       # Make file executable for all
alias ux='chmod u+x'       # Make file executable for user

# Quick directory navigation
alias back='cd $OLDPWD'

# Show directory size
alias dirsize='du -sh'     # Current directory size
alias dirsizes='du -sh *'  # Size of items in current directory

# Colorize diff output
alias diff='diff --color=auto'

# Easy archive extraction
extract() {
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Make and change to a directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find the process using a specific port
port() {
    lsof -i :"$1"
}

# Find large files (default: >100MB)
findlarge() {
    find . -type f -size +${1:-100M} -exec ls -lh {} \; | sort -k5 -rh
}

# A better cd command that lists directory contents after cd
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

# Better alternative to 'which' command
where() {
    type -a "$1" | grep -v 'not found' | grep -v 'alias for' | head -n1
}

# Run command in background
bk() {
    nohup "$@" >/dev/null 2>&1 &
}

# Display a cheatsheet for a command
cheat() {
    curl "cheat.sh/$1"
}

# Look busy for the boss
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"
