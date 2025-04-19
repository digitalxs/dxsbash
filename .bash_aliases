#!/bin/bash
#
# .bash_aliases - Additional professional-grade aliases for dxsbash
# This file contains only aliases that don't conflict with the main dxsbash configuration
# You can add easily you own alias on this file without affecting .bashrc directly

#######################################################
# GENERAL ALIAS'S
#######################################################
# To temporarily bypass an alias, we precede the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
# Edit this .bashrc file
alias ebrc='edit ~/.bashrc'
# Show help for this .bashrc file
alias help='less ~/.bashrc_help'
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
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | egrep '^d'"   # directories only
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

# Python environment management
alias pyenv='python -m venv'               # Create virtualenv more easily
alias pyact='source ./venv/bin/activate'   # Activate virtualenv in current directory 
alias pydact='deactivate'                  # Deactivate current virtualenv
alias pyreq='pip freeze > requirements.txt' # Generate requirements.txt
alias pyup='pip install --upgrade pip'     # Upgrade pip
alias pipi='pip install'                   # Shorter pip install
alias pipun='pip uninstall'                # Shorter pip uninstall

# Python execution shortcuts
alias py3='python3'                        # Explicit Python 3
alias ipy='ipython'                        # Launch IPython
alias jpy='jupyter notebook'               # Launch Jupyter notebook
alias jpyl='jupyter lab'                   # Launch Jupyter lab
alias pt='pytest'                          # Run pytest
alias ptr='pytest -xvs'                    # Run pytest with useful flags
alias ptw='pytest-watch'                   # Run pytest-watch
alias nose='nosetests'                     # Run nosetests

# Django shortcuts
alias djrun='python manage.py runserver'   # Run Django development server
alias djmig='python manage.py migrate'     # Run Django migrations
alias djmm='python manage.py makemigrations' # Make Django migrations
alias djsh='python manage.py shell'        # Django shell
alias djsu='python manage.py createsuperuser' # Create Django superuser
alias djtest='python manage.py test'       # Run Django tests

# Flask shortcuts
alias flrun='flask run'                    # Run Flask development server
alias flshell='flask shell'                # Flask shell

# Python code quality
alias lint='flake8'                        # Run flake8 linter
alias black='black .'                      # Format code with Black
alias mypy='mypy .'                        # Run type checking
alias pylint='pylint'                      # Run pylint

# Python dependency management
alias pipoutdated='pip list --outdated'    # List outdated packages
alias pipgraph='pipdeptree'                # Show dependency tree

# Python documentation
alias pydoc='python -m pydoc'              # Access Python documentation
alias mkdocs='mkdocs serve'                # Serve documentation with MkDocs

# Create a function to create and activate a virtualenv in one command
pyvenv() {
    python -m venv ${1:-venv} && source ${1:-venv}/bin/activate
}

# Create a function to run a Python script with timing information
pytime() {
    time python "$@"
}

# Create a function to profile Python script
pyprofile() {
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
    python -m json.tool "$@"
}

# Clean Python cache files
pyclean() {
    find . -type d -name "__pycache__" -exec rm -rf {} +
    find . -type f -name "*.pyc" -delete
    find . -type f -name "*.pyo" -delete
    find . -type f -name "*.pyd" -delete
    find . -type f -name ".coverage" -delete
    find . -type d -name "*.egg-info" -exec rm -rf {} +
    find . -type d -name "*.egg" -exec rm -rf {} +
    find . -type d -name ".pytest_cache" -exec rm -rf {} +
    find . -type d -name ".coverage" -exec rm -rf {} +
    find . -type d -name "htmlcov" -exec rm -rf {} +
    find . -type d -name ".tox" -exec rm -rf {} +
    find . -type d -name "dist" -exec rm -rf {} +
    find . -type d -name "build" -exec rm -rf {} +
    echo "Cleaned Python cache files."
}


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
