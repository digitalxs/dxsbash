#!/bin/bash
#
# .bash_aliases - Additional professional-grade aliases for dxsbash
# This file contains only aliases that don't conflict with the main dxsbash configuration
#

# System information aliases
alias meminfo='free -m -l -t'                     # Detailed memory information
alias cpuinfo='lscpu'                             # CPU information
alias listening='netstat -tlnp'                   # Show only listening connections
alias fastping='ping -c 100 -s.2'                 # Quick ping for network testing
alias services='systemctl --type=service'         # List all services

# IP and network aliases
alias myip='curl -s https://api.ipify.org && echo'  # Show public IP address
alias localip='ip -br a'                          # Simplified local IP display
alias ips="ip -c a | grep 'inet ' | awk '{print \$2}'"  # List all IPs

# Path information
alias path='echo -e ${PATH//:/\\n}'               # Show PATH entries one per line

# Enhanced git aliases (extending the basic ones in dxsbash)
alias gca='git commit --amend'                    # Amend previous commit
alias gcm='git commit -m'                         # Commit with message
alias gcob='git checkout -b'                      # Create and checkout branch
alias gf='git fetch'                              # Fetch from remote
alias gt='git tag'                                # List tags
alias gm='git merge'                              # Merge
alias glog='git log --oneline --decorate --graph' # Pretty git log
alias gloga='git log --oneline --decorate --graph --all' # Pretty git log (all branches)
alias gst='git stash'                             # Stash changes
alias gstp='git stash pop'                        # Pop stashed changes
alias gundo='git reset --soft HEAD~1'             # Undo last commit preserving changes

# Docker aliases
if command -v docker &> /dev/null; then
    alias dps='docker ps'                         # List running containers
    alias dpsa='docker ps -a'                     # List all containers
    alias di='docker images'                      # List images
    alias dex='docker exec -it'                   # Execute interactive
    alias drun='docker run -it'                   # Run interactive
    alias dip='docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"' # Get container IP
    alias dlogs='docker logs'                     # Show container logs
    alias dclean='docker system prune -a'         # Clean unused images and containers
    alias dstop='docker stop $(docker ps -q)'     # Stop all running containers
fi

# Docker Compose aliases
if command -v docker-compose &> /dev/null; then
    alias dc='docker-compose'                     # Docker compose shortcut
    alias dcup='docker-compose up -d'             # Start in background
    alias dcdown='docker-compose down'            # Stop and remove
    alias dcrestart='docker-compose restart'      # Restart services
    alias dclogs='docker-compose logs -f'         # Follow logs
fi

# Kubernetes aliases
if command -v kubectl &> /dev/null; then
    alias k='kubectl'                             # Kubectl shortcut
    alias kg='kubectl get'                        # Get resources
    alias kgp='kubectl get pods'                  # Get pods
    alias kgs='kubectl get services'              # Get services
    alias kgn='kubectl get nodes'                 # Get nodes
    alias kd='kubectl describe'                   # Describe resources
    alias kdp='kubectl describe pod'              # Describe pod
    alias kl='kubectl logs'                       # View logs
    alias ke='kubectl exec -it'                   # Execute interactive
    alias kaf='kubectl apply -f'                  # Apply from file
    alias kdf='kubectl delete -f'                 # Delete from file
    alias kctx='kubectl config use-context'       # Switch context
    alias kns='kubectl config set-context --current --namespace' # Switch namespace
fi

# Python developer shortcuts
alias py='python3'                                # Python 3 shortcut
alias py2='python2'                               # Python 2 shortcut
alias pipinstall='pip install -r requirements.txt' # Install requirements
alias ve='python3 -m venv ./venv'                 # Create virtual environment
alias va='source ./venv/bin/activate'             # Activate virtual environment
alias vd='deactivate'                             # Deactivate virtual environment

# JavaScript/Node.js developer shortcuts
if command -v npm &> /dev/null; then
    alias ni='npm install'                        # Install dependencies
    alias nid='npm install --save-dev'            # Install dev dependencies
    alias nig='npm install -g'                    # Install global package
    alias ns='npm start'                          # Start application
    alias nt='npm test'                           # Run tests
    alias nb='npm run build'                      # Build application
    alias nr='npm run'                            # Run script
    alias noup='npm update'                       # Update packages
fi

# Date and time aliases
alias cal='cal -3'                                # Show 3 months of calendar
alias now='date +"%T"'                            # Current time
alias nowtime='date +"%T"'                        # Current time
alias nowdate='date +"%d-%m-%Y"'                  # Current date

# Advanced search aliases
alias findtext='find . -type f -not -path "*/\.git/*" -exec grep -l' # Find files containing text
alias findf='find . -type f -not -path "*/\.git/*" -name' # Find files by name excluding .git
alias findd='find . -type d -not -path "*/\.git/*" -name' # Find directories by name excluding .git

# Weather information
alias weather='curl wttr.in'                      # Full weather report
alias weather-short='curl "wttr.in?format=3"'     # Compact weather report

# Clipboard operations
if command -v xclip &> /dev/null; then
    alias setclip='xclip -selection c'            # Copy to clipboard
    alias getclip='xclip -selection c -o'         # Paste from clipboard
fi

# Random utilities
alias countdown='for i in $(seq $1 -1 1); do echo $i; sleep 1; done; echo "Time is up!"' # Countdown timer
alias timer='time read -p "Press Enter to stop timer..."' # Simple timer
alias random-string='openssl rand -base64 32'     # Generate random string
alias calc='bc -l'                                # Calculator
alias genpass='openssl rand -base64 12'           # Generate secure password

# Additional functions that don't conflict with dxsbash

# Find the process using a specific port
port() {
    lsof -i :"$1"
}

# Find large files (default: >100MB)
findlarge() {
    find . -type f -size +${1:-100M} -exec ls -lh {} \; | sort -k5 -rh
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

# Look busy for the boss (different version than dxsbash)
alias look-busy="for i in {1..100}; do echo $RANDOM; sleep .3; done | sort"
