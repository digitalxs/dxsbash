#!/bin/bash
#
# .bash_aliases - Enhanced professional-grade aliases for dxsbash
# This file contains only aliases that don't conflict with the main dxsbash configuration
# You can add your own aliases to this file without affecting .bashrc directly
# 
# Fixed version addressing security, consistency, and usability issues

#######################################################
# GENERAL ALIAS'S
#######################################################
# To temporarily bypass an alias, we precede the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls

# Add an "alert" alias for long running commands. Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Edit this .bashrc file
alias ebrc='edit ~/.bashrc'

# Show help for this .bashrc file
alias help='less ~/.bashrc_help'

# Alias to show the date
alias da='date "+%Y-%m-%d %A %T %Z"'

# Alias's to modified commands
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
alias rmd='/bin/rm --recursive --force --verbose'

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

# SAFER chmod commands - removed dangerous recursive operations
alias mx='chmod a+x'
# Removed dangerous 000, 644, 666, 755, 777 recursive aliases
# Use the safer functions below instead

# Search command line history
alias h="history | grep "

# Use this for when the boss comes around to look busy
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

# Show active ports
alias ports='netstat -tulanp'

# Show current network connections to the server
alias ipview="netstat -anpl | grep :80 | awk {'print \$5'} | cut -d\":\" -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"

# Alias's for safe and forced reboots
alias restart='sudo shutdown -r now'
alias forcerestart='sudo shutdown -r -n now'
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

# System information aliases
alias meminfo='free -m -l -t'                     # Detailed memory information
alias cpuinfo='lscpu'                             # CPU information
alias listening='netstat -tlnp'                   # Show only listening connections
alias fastping='ping -c 100 -s.2'                 # Quick ping for network testing

# Check if systemctl exists before creating alias
if command -v systemctl &> /dev/null; then
    alias services='systemctl --type=service'     # List all services
fi

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

#######################################################
# DOCKER ALIASES (only if docker is available)
#######################################################
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
    alias docker-clean='docker container prune -f ; docker image prune -f ; docker network prune -f ; docker volume prune -f'
fi

#######################################################
# DOCKER COMPOSE ALIASES (only if docker-compose is available)
#######################################################
if command -v docker-compose &> /dev/null; then
    alias dc='docker-compose'                     # Docker compose shortcut
    alias dcup='docker-compose up -d'             # Start in background
    alias dcdown='docker-compose down'            # Stop and remove
    alias dcrestart='docker-compose restart'      # Restart services
    alias dclogs='docker-compose logs -f'         # Follow logs
fi

#######################################################
# KUBERNETES ALIASES (only if kubectl is available)
#######################################################
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

#######################################################
# PYTHON DEVELOPMENT SHORTCUTS
#######################################################
alias py='python3'                                # Python 3 shortcut
alias py2='python2'                               # Python 2 shortcut (if available)
alias pipinstall='pip install -r requirements.txt' # Install requirements

# Python environment management (cleaned up duplicates)
alias ve='python3 -m venv ./venv'                 # Create virtual environment
alias va='source ./venv/bin/activate'             # Activate virtual environment
alias vd='deactivate'                             # Deactivate virtual environment

# Python execution shortcuts
alias py3='python3'                               # Explicit Python 3
if command -v ipython &> /dev/null; then
    alias ipy='ipython'                            # Launch IPython
fi
if command -v jupyter &> /dev/null; then
    alias jpy='jupyter notebook'                   # Launch Jupyter notebook
    alias jpyl='jupyter lab'                       # Launch Jupyter lab
fi

# Python testing (prefer pytest over deprecated nose) - FIXED: No warning message
if command -v pytest &> /dev/null; then
    alias pt='pytest'                              # Run pytest
    alias ptr='pytest -xvs'                       # Run pytest with useful flags
    if command -v pytest-watch &> /dev/null; then
        alias ptw='pytest-watch'                   # Run pytest-watch (if available)
    fi
fi

# Django shortcuts (only if manage.py exists in current directory)
if [ -f "manage.py" ]; then
    alias djrun='python manage.py runserver'       # Run Django development server
    alias djmig='python manage.py migrate'         # Run Django migrations
    alias djmm='python manage.py makemigrations'   # Make Django migrations
    alias djsh='python manage.py shell'            # Django shell
    alias djsu='python manage.py createsuperuser'  # Create Django superuser
    alias djtest='python manage.py test'           # Run Django tests
fi

# Flask shortcuts
if command -v flask &> /dev/null; then
    alias flrun='flask run'                        # Run Flask development server
    alias flshell='flask shell'                    # Flask shell
fi

# Python code quality tools
if command -v flake8 &> /dev/null; then
    alias lint='flake8'                            # Run flake8 linter
fi
if command -v black &> /dev/null; then
    alias black='black .'                          # Format code with Black
fi
if command -v mypy &> /dev/null; then
    alias mypy='mypy .'                            # Run type checking
fi

# Python dependency management
alias pipoutdated='pip list --outdated'           # List outdated packages
if command -v pipdeptree &> /dev/null; then
    alias pipgraph='pipdeptree'                    # Show dependency tree
fi

# Python documentation
alias pydoc='python -m pydoc'                     # Access Python documentation
if command -v mkdocs &> /dev/null; then
    alias mkdocs='mkdocs serve'                    # Serve documentation with MkDocs
fi

#######################################################
# NODE.JS DEVELOPMENT SHORTCUTS (only if npm is available)
#######################################################
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

#######################################################
# DATE AND TIME ALIASES
#######################################################
alias cal='cal -3'                                # Show 3 months of calendar
alias now='date +"%T"'                            # Current time
alias nowtime='date +"%T"'                        # Current time
alias nowdate='date +"%d-%m-%Y"'                  # Current date

#######################################################
# ADVANCED SEARCH ALIASES
#######################################################
alias findtext='find . -type f -not -path "*/\.git/*" -exec grep -l' # Find files containing text
alias findf='find . -type f -not -path "*/\.git/*" -name' # Find files by name excluding .git
alias findd='find . -type d -not -path "*/\.git/*" -name' # Find directories by name excluding .git

# Weather information (if curl is available)
if command -v curl &> /dev/null; then
    alias weather='curl wttr.in'                      # Full weather report
    alias weather-short='curl "wttr.in?format=3"'     # Compact weather report
fi

# Clipboard operations (if xclip is available)
if command -v xclip &> /dev/null; then
    alias setclip='xclip -selection c'            # Copy to clipboard
    alias getclip='xclip -selection c -o'         # Paste from clipboard
fi

# Random utilities
alias random-string='openssl rand -base64 32'     # Generate random string
alias calc='bc -l'                                # Calculator
alias genpass='openssl rand -base64 12'           # Generate secure password

#######################################################
# SAFER PERMISSION FUNCTIONS (replacing dangerous aliases)
#######################################################

# Safer chmod functions with confirmation prompts
set_permissions() {
    local perm="$1"
    local target="${2:-.}"
    
    if [ ! -e "$target" ]; then
        echo "Error: Target '$target' does not exist"
        return 1
    fi
    
    echo "This will set permissions to $perm on: $target"
    read -p "Are you sure? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod -R "$perm" "$target"
        echo "Permissions set to $perm on $target"
    else
        echo "Operation cancelled"
    fi
}

#######################################################
# ENHANCED FUNCTIONS
#######################################################

# Create a function to create and activate a virtualenv in one command
pyvenv() {
    local venv_name="${1:-venv}"
    if python3 -m venv "$venv_name"; then
        echo "Virtual environment '$venv_name' created successfully"
        source "$venv_name/bin/activate"
        echo "Virtual environment activated"
    else
        echo "Error: Failed to create virtual environment"
        return 1
    fi
}

# Create a function to run a Python script with timing information
pytime() {
    if [ $# -eq 0 ]; then
        echo "Usage: pytime <python_script> [args...]"
        return 1
    fi
    time python "$@"
}

# Create a function to profile Python script
pyprofile() {
    if [ $# -eq 0 ]; then
        echo "Usage: pyprofile <python_script> [args...]"
        return 1
    fi
    python -m cProfile -s tottime "$@" | head -20
}

# Create a function to run a Python simple HTTP server
pyserver() {
    local port=${1:-8000}
    echo "Starting HTTP server on port $port..."
    python -m http.server "$port"
}

# Create a function to prettify Python JSON
pyjson() {
    if [ $# -eq 0 ]; then
        echo "Usage: pyjson <json_file>"
        return 1
    fi
    python -m json.tool "$@"
}

# Clean Python cache files with better feedback
pyclean() {
    echo "Cleaning Python cache files..."
    local count=0
    local total_removed=0
    
    # Count files before deletion
    count=$(find . \( -name "*.pyc" -o -name "*.pyo" -o -name "*.pyd" -o -name ".coverage" \) -type f 2>/dev/null | wc -l)
    local dir_count
    dir_count=$(find . \( -name "__pycache__" -o -name "*.egg-info" -o -name "*.egg" -o -name ".pytest_cache" -o -name "htmlcov" -o -name ".tox" -o -name "dist" -o -name "build" \) -type d 2>/dev/null | wc -l)
    
    if [ "$count" -eq 0 ] && [ "$dir_count" -eq 0 ]; then
        echo "No Python cache files found."
        return 0
    fi
    
    echo "Found $count cache files and $dir_count cache directories to clean..."
    
    # Perform cleanup with error handling
    find . -type f -name "*.pyc" -delete 2>/dev/null && ((total_removed++)) || true
    find . -type f -name "*.pyo" -delete 2>/dev/null && ((total_removed++)) || true
    find . -type f -name "*.pyd" -delete 2>/dev/null && ((total_removed++)) || true
    find . -type f -name ".coverage" -delete 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "*.egg" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name ".tox" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    find . -type d -name "build" -exec rm -rf {} + 2>/dev/null && ((total_removed++)) || true
    
    echo "Python cache cleanup completed."
}

# Find the process using a specific port (renamed from 'port' to avoid conflicts)
showport() {
    if [ $# -eq 0 ]; then
        echo "Usage: showport <port_number>"
        return 1
    fi
    
    if ! command -v lsof &> /dev/null; then
        echo "Error: lsof not found. Please install lsof."
        return 1
    fi
    
    lsof -i :"$1"
}

# Find large files with improved error handling
findlarge() {
    local size="${1:-100M}"
    
    # Validate size parameter
    if [[ ! "$size" =~ ^[0-9]+[GMKgmk]?$ ]]; then
        echo "Error: Invalid size format. Use format like 100M, 1G, 500K"
        echo "Usage: findlarge [size]"
        echo "Examples: findlarge 100M, findlarge 1G, findlarge 500K"
        return 1
    fi
    
    echo "Searching for files larger than $size..."
    find . -type f -size +"$size" -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh
}

# Better alternative to 'which' command
where() {
    if [ $# -eq 0 ]; then
        echo "Usage: where <command>"
        return 1
    fi
    
    type -a "$1" 2>/dev/null | grep -v 'not found' | grep -v 'alias for' | head -n1
}

# Run command in background
bk() {
    if [ $# -eq 0 ]; then
        echo "Usage: bk <command> [args...]"
        return 1
    fi
    
    nohup "$@" >/dev/null 2>&1 &
    echo "Started '$*' in background (PID: $!)"
}

# Display a cheatsheet for a command
cheat() {
    if [ $# -eq 0 ]; then
        echo "Usage: cheat <command>"
        return 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo "Error: curl not found. Please install curl."
        return 1
    fi
    
    curl "cheat.sh/$1"
}

# Countdown timer with validation
countdown() {
    local seconds="$1"
    
    if [ $# -eq 0 ] || ! [[ "$seconds" =~ ^[0-9]+$ ]]; then
        echo "Usage: countdown <seconds>"
        return 1
    fi
    
    for i in $(seq "$seconds" -1 1); do 
        echo "$i"
        sleep 1
    done
    echo "Time is up!"
}

# Simple timer
timer() {
    echo "Timer started. Press Enter to stop..."
    time read -r
}

# Look busy for the boss (alternative version)
look-busy() {
    echo "Looking busy... Press Ctrl+C to stop"
    for i in {1..100}; do 
        echo $RANDOM
        sleep .3
    done | sort
}
