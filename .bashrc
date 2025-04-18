#!/usr/bin/env bash
iatest=$(expr index "$-" i)
# Check if this is a TTY session
if [[ "$(tty)" == /dev/tty[1-9]* ]]; then
    # This is definitely a TTY console session
    
    # Basic history settings
    export HISTSIZE=1000
    export HISTFILESIZE=2000
    export HISTCONTROL=ignoreboth
    
    # Basic shell options
    shopt -s checkwinsize
    shopt -s histappend
    
    # Simple prompt
    PS1='\u@\h:\w\$ '
    
    # Basic color support for common commands
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    
    # Exit early, skipping all customizations including starship
    return
fi
#######################################################################
# SOURCED ALIAS'S AND SCRIPTS BY Luis Freitas and others (2025)
# Get List of commands at README
# Version 2.2.6
# Start updating .bashrc:
# nano .bashrc
# paste this bash script and save
# execute comand:
# source .bashrc
# execute command:
# install_bashrc_support
# and it will install the necessary software for this script to work.
#######################################################################
# Source global definitions
if [ -f /etc/bashrc ]; then
	 . /etc/bashrc
fi
# Source dxsbash utilities
if [ -f "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh" ]; then
    source "$HOME/linuxtoolbox/dxsbash/dxsbash-utils.sh"
fi
# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi
#######################################################
# EXPORTS
#######################################################
# Disable the bell
if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T" # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Seeing as other scripts will use it might as well export it
export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Allow ctrl-S for history navigation (with ctrl-R)
[[ $- == *i* ]] && stty -ixon
# Enhanced auto-completion
if [[ $iatest -gt 0 ]]; then
    bind "set completion-ignore-case on"
    bind "set show-all-if-ambiguous on"
    bind "set menu-complete-display-prefix on"
    bind "TAB:menu-complete"
    bind '"\e[Z": menu-complete-backward' # Shift+Tab to go backward
fi

# Set the default editor
export EDITOR=nano
export VISUAL=nano
alias spico='sedit'
alias snano='sudo nano'
alias vim='nvim'
# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
#export GREP_OPTIONS='--color=auto' #deprecated
# Remove the next line for server usage
alias grep="/usr/bin/grep $GREP_OPTIONS"
# Uncomment this for server
# alias grep="/bin/grep $GREP_OPTIONS"
# Check if ripgrep is installed
if command -v rg &> /dev/null; then
    # Alias grep to rg if ripgrep is installed
    alias grep='rg'
else
    # Alias grep to /usr/bin/grep with GREP_OPTIONS if ripgrep is not installed
    alias grep="/usr/bin/grep $GREP_OPTIONS"
fi
unset GREP_OPTIONS
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
# Update Computer - Debian/Ubuntu - NALA
#######################################################
alias install='sudo nala update && sudo nala install -y'
alias update='sudo nala update && sudo nala upgrade -y'
alias upgrade='sudo nala update && sudo apt-get dist-upgrade'
alias remove='sudo nala update && sudo nala remove'
alias removeall='sudo nala purge'
alias historypkg='nala history'
alias searchpkg='sudo nala search'
# For Arch Linux
if command -v pacman &> /dev/null; then
    # Check for AUR helpers
    if command -v yay &> /dev/null; then
        alias install='yay -S'
        alias update='yay -Syu'
        alias upgrade='yay -Syu'
        alias remove='yay -R'
        alias removeall='yay -Rns'
        alias searchpkg='yay -Ss'
    elif command -v paru &> /dev/null; then
        alias install='paru -S'
        alias update='paru -Syu'
        alias upgrade='paru -Syu'
        alias remove='paru -R'
        alias removeall='paru -Rns'
        alias searchpkg='paru -Ss'
    else
        # Fallback to regular pacman
        alias install='sudo pacman -S'
        alias update='sudo pacman -Syu'
        alias upgrade='sudo pacman -Syu'
        alias remove='sudo pacman -R'
        alias removeall='sudo pacman -Rns'
        alias searchpkg='pacman -Ss'
    fi
    # Add history package listing for Arch
    alias historypkg='cat /var/log/pacman.log'
fi

# alias to cleanup unused docker containers, images, networks, and volumes
alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '
# Source .bash_aliases if it exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
#######################################################
# SPECIAL FUNCTIONS
#######################################################
# Use the best version of pico installed
edit ()
{
	if [ "$(type -t jpico)" = "file" ]; then
		# Use JOE text editor http://joe-editor.sourceforge.net/
		jpico -nonotice -linums -nobackups "$@"
	elif [ "$(type -t nano)" = "file" ]; then
		nano -c "$@"
	elif [ "$(type -t pico)" = "file" ]; then
		pico "$@"
	else
		vim "$@"
	fi
}
sedit ()
{
	if [ "$(type -t jpico)" = "file" ]; then
		# Use JOE text editor http://joe-editor.sourceforge.net/
		sudo jpico -nonotice -linums -nobackups "$@"
	elif [ "$(type -t nano)" = "file" ]; then
		sudo nano -c "$@"
	elif [ "$(type -t pico)" = "file" ]; then
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
cd ()
{
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
distribution () 
{
    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            ubuntu|debian)
                echo "debian"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            *)
                # Check ID_LIKE only if dtype is still unknown
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *ubuntu*|*debian*)
                            echo "debian"
                            ;;
                        *arch*)
                            echo "arch"
                            ;;
                        *)
                            echo "unknown"
                            ;;
                    esac
                else
                    echo "unknown"
                fi
                ;;
        esac
    else
        echo "unknown"
    fi
}
DISTRIBUTION=$(distribution)
# Set cat alias based on available commands and distribution
if command -v bat &> /dev/null; then
    alias cat='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat'
fi
# Show the current version of the operating system
ver() {
    case $(distribution) in
        "debian")
            lsb_release -a
            ;;
        "arch")
            cat /etc/os-release
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
# Automatically install the needed support files for this .bashrc file
install_bashrc_support() {
    case $(distribution) in
        "debian")
            echo "Installing packages for Debian/Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline neovim ripgrep
            ;;
        "arch")
            echo "Installing packages for Arch Linux..."
            
            # Determine which AUR helper to use, or fallback to pacman
            AUR_HELPER="sudo pacman"
            AUR_INSTALL_FLAG="-S --needed"
            
            if command -v yay &> /dev/null; then
                AUR_HELPER="yay"
                AUR_INSTALL_FLAG="-S --needed"
            elif command -v paru &> /dev/null; then
                AUR_HELPER="paru"
                AUR_INSTALL_FLAG="-S --needed"
            else
                echo "No AUR helper found. Using pacman for official packages only."
                echo "Consider installing yay or paru for AUR support."
            fi
            
            # Install official packages with pacman
            sudo pacman -S --needed bash bash-completion bat tree curl wget unzip fontconfig joe git fish zoxide trash-cli fzf ripgrep neovim
            
            # Install AUR packages if an AUR helper is available
            if [ "$AUR_HELPER" != "sudo pacman" ]; then
                echo "Installing AUR packages with $AUR_HELPER..."
                $AUR_HELPER $AUR_INSTALL_FLAG fastfetch powerline
            else
                echo "To install AUR packages, please install an AUR helper like yay or paru."
            fi
            ;;
        *)
            echo "Unsupported distribution. Only Debian, Ubuntu, and Arch are supported."
            ;;
    esac
}
# Show current network information
netinfo ()
{
	echo "--------------- Network Information --------------------------"
	nmcli
	echo "--------------------------------------------------------------"
}
# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip () {
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
# Edit the PHP configuration file
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
# Set the command prompt
#######################################################
alias cpu="grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}' | awk '{printf(\"%.1f\n\", \$1)}'"
function __setprompt
{
	local LAST_COMMAND=$? # Must come first!

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
		# PS1="\[${RED}\](\[${LIGHTRED}\]ERROR\[${RED}\])-(\[${LIGHTRED}\]Exit Code \[${WHITE}\]${LAST_COMMAND}\[${RED}\])-(\[${LIGHTRED}\]"
		PS1="\[${DARKGRAY}\](\[${LIGHTRED}\]ERROR\[${DARKGRAY}\])-(\[${RED}\]Exit Code \[${LIGHTRED}\]${LAST_COMMAND}\[${DARKGRAY}\])-(\[${RED}\]"
		if [[ $LAST_COMMAND == 1 ]]; then
			PS1+="General error"
		elif [ $LAST_COMMAND == 2 ]; then
			PS1+="Missing keyword, command, or permission problem"
		elif [ $LAST_COMMAND == 126 ]; then
			PS1+="Permission problem or command is not an executable"
		elif [ $LAST_COMMAND == 127 ]; then
			PS1+="Command not found"
		elif [ $LAST_COMMAND == 128 ]; then
			PS1+="Invalid argument to exit"
		elif [ $LAST_COMMAND == 129 ]; then
			PS1+="Fatal error signal 1"
		elif [ $LAST_COMMAND == 130 ]; then
			PS1+="Script terminated by Control-C"
		elif [ $LAST_COMMAND == 131 ]; then
			PS1+="Fatal error signal 3"
		elif [ $LAST_COMMAND == 132 ]; then
			PS1+="Fatal error signal 4"
		elif [ $LAST_COMMAND == 133 ]; then
			PS1+="Fatal error signal 5"
		elif [ $LAST_COMMAND == 134 ]; then
			PS1+="Fatal error signal 6"
		elif [ $LAST_COMMAND == 135 ]; then
			PS1+="Fatal error signal 7"
		elif [ $LAST_COMMAND == 136 ]; then
			PS1+="Fatal error signal 8"
		elif [ $LAST_COMMAND == 137 ]; then
			PS1+="Fatal error signal 9"
		elif [ $LAST_COMMAND -gt 255 ]; then
			PS1+="Exit status out of range"
		else
			PS1+="Unknown error code"
		fi
		PS1+="\[${DARKGRAY}\])\[${NOCOLOR}\]\n"
	else
		PS1=""
	fi

	# Date
	PS1+="\[${DARKGRAY}\](\[${CYAN}\]\$(date +%a) $(date +%b-'%-m')" # Date
	PS1+="${BLUE} $(date +'%-I':%M:%S%P)\[${DARKGRAY}\])-" # Time

	# CPU
	PS1+="(\[${MAGENTA}\]CPU $(cpu)%"

	# Jobs
	PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]\j"

	# Network Connections (for a server - comment out for non-server)
	PS1+="\[${DARKGRAY}\]:\[${MAGENTA}\]Net $(awk 'END {print NR}' /proc/net/tcp)"

	PS1+="\[${DARKGRAY}\])-"

	# User and server
	local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
	local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
	if [ $SSH2_IP ] || [ $SSH_IP ] ; then
		PS1+="(\[${RED}\]\u@\h"
	else
		PS1+="(\[${RED}\]\u"
	fi

	# Current directory
	PS1+="\[${DARKGRAY}\]:\[${BROWN}\]\w\[${DARKGRAY}\])-"

	# Total size of files in current directory
	PS1+="(\[${GREEN}\]$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')\[${DARKGRAY}\]:"

	# Number of files
	PS1+="\[${GREEN}\]\$(/bin/ls -A -1 | /usr/bin/wc -l)\[${DARKGRAY}\])"

	# Skip to the next line
	PS1+="\n"

	if [[ $EUID -ne 0 ]]; then
		PS1+="\[${GREEN}\]>\[${NOCOLOR}\] " # Normal user
	else
		PS1+="\[${RED}\]>\[${NOCOLOR}\] " # Root user
	fi

	# PS2 is used to continue a command using the \ character
	PS2="\[${DARKGRAY}\]>\[${NOCOLOR}\] "

	# PS3 is used to enter a number choice in a script
	PS3='Please enter a number from above list: '

	# PS4 is used for tracing a script in debug mode
	PS4='\[${DARKGRAY}\]+\[${NOCOLOR}\] '
}
##################################################################
PROMPT_COMMAND='__setprompt'
export PATH=/usr/sbin:$PATH
export PATH=/snap/bin:$PATH
export PATH="$PATH:$HOME/.composer/vendor/bin"

# Check if the shell is interactive
if [[ $- == *i* ]]; then
    # Bind Ctrl+f to insert 'zi' followed by a newline
    bind '"\C-f":"zi\n"'
fi
##################################################################
# IF YOU WANT TO USE ALTERNATIVE THEME COMMENT THE NEXT LINE
eval "$(starship init bash)"
##################################################################
eval "$(zoxide init bash)"
##################################################################
