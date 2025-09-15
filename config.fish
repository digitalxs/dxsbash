#!/usr/bin/env fish

# Detect if this is a TTY console
if string match -q "/dev/tty[1-9]*" (tty)
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
    
    # Skip rest of configuration
    exit
end

#######################################################################
# SOURCED ALIAS'S AND FUNCTIONS BY Luis Freitas and others (2025)
#######################################################################
# FISH version converted from dxsbash
# Version 3.0.3
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
# GENERAL ALIASES
#######################################################
# Edit config files
alias efrc='edit ~/.config/fish/config.fish'
alias help='less ~/.config/fish/fish_help'

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
alias apt-get='sudo apt-get'
alias multitail='multitail --no-repeat -c'
alias freshclam='sudo freshclam'

# Editor aliases
alias vi='vim'
alias svi='sudo vi'
alias vis='nvim "+set si"'
alias snano='sudo nano'
alias vim='nvim'
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
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

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

# Network commands
alias openports='netstat -nape --inet'
alias ports='netstat -tulanp'
alias ipview="netstat -anpl | grep :80 | awk '{print \$5}' | cut -d: -f1 | sort | uniq -c | sort -n | sed -e 's/^ *//' -e 's/ *\$//'"

# Reboot/shutdown
alias restart='sudo shutdown -r now'
alias forcerestart='sudo shutdown -r -n now'
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
# Hash functions
alias sha1='openssl sha1'

# Copy-paste with delay
alias clickpaste='sleep 3; xdotool type (xclip -o -selection clipboard)'

# Kitty SSH
alias kssh="kitty +kitten ssh"

# Docker cleanup
alias docker-clean='docker container prune -f; docker image prune -f; docker network prune -f; docker volume prune -f'

# Use ripgrep if available, otherwise regular grep with color
if type -q rg
    alias grep='rg'
else
    alias grep='/usr/bin/grep --color=auto'
end

# Use bat or batcat based on distribution
function get_distribution
    set dtype "unknown"
    
    if test -r /etc/os-release
        set -l distro_id (cat /etc/os-release | grep "^ID=" | cut -d= -f2 | tr -d '"')
        switch $distro_id
            case 'fedora' 'rhel' 'centos'
                set dtype "redhat"
            case 'sles' 'opensuse*'
                set dtype "suse"
            case 'ubuntu' 'debian'
                set dtype "debian"
            case 'gentoo'
                set dtype "gentoo"
            case 'arch' 'manjaro'
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
if test "$DISTRIBUTION" = "redhat"; or test "$DISTRIBUTION" = "arch"
    alias cat='bat'
else
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
            sudo yum install multitail tree zoxide trash-cli fzf fish
        case "suse"
            sudo zypper install multitail tree zoxide trash-cli fzf fish
        case "debian"
            sudo apt-get install fish bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline
        case "arch"
            sudo paru -S multitail tree zoxide trash-cli fzf fish
        case "slackware"
            echo "No install support for Slackware yet. Sorry my good old friend Patrick V."
        case "*"
            echo "Unknown distribution"
    end
    
    # Install Fisher plugin manager
    if not type -q fisher
        echo "Installing Fisher plugin manager..."
        curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
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
        starship init fish | source
    end
    
    # Run fastfetch if installed and not in SSH session
    if type -q fastfetch; and not set -q SSH_CLIENT; and not set -q SSH_TTY
        fastfetch
    end
end
