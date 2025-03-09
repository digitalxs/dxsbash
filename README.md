# dxsbash
## bash unleashed. for pros. 

* [Documentation](https://github.com/digitalxs/dxsbash/wiki/)

The `.bashrc` file is a script that runs every time a new terminal session is started in Unix-like operating systems. It is used to configure the shell session, set up aliases, define functions, and more, making the terminal easier to use and more powerful. Below is a summary of the key sections and functionalities defined in the provided `.bashrc` file.

## How to install automatically
```
git clone --depth=1 https://github.com/digitalxs/dxsbash.git
cd dxsbash
chmod +x setup.sh
./setup.sh
```
Note: also use command install_bashrc_support to check for any dependecy missing.

## How to install manually
1. Copy and/or create file .bashrc and replace on users home folder.
2. Log off or use command `source .bashrc` to activate new customized shell.
3. Use command `install_bashrc_support` to install all necessary software to run with this shell

### Initial Setup and System Checks

- **Environment Checks**: The script checks if it is running in an interactive mode and sets up the environment accordingly.
- **System Utilities**: It checks for the presence of utilities like `fastfetch`, `bash-completion`, and system-specific configurations (`/etc/bashrc`).

### Aliases and Functions

- **Aliases**: Shortcuts for common commands are set up to enhance productivity. For example, `alias cp='cp -i'` makes the `cp` command interactive, asking for confirmation before overwriting files.
- **Functions**: Custom functions for complex operations like `extract()` for extracting various archive types, and `cpp()` for copying files with a progress bar.

### Prompt Customization and History Management

- **Prompt Command**: The `PROMPT_COMMAND` variable is set to automatically save the command history after each command.
- **History Control**: Settings to manage the size of the history file and how duplicates are handled.

### System-Specific Aliases and Settings

- **Editor Settings**: Sets `nvim` (NeoVim) as the default editor.
- **Conditional Aliases**: Depending on the system type (like Fedora), it sets specific aliases, e.g., replacing `cat` with `bat`.

### Enhancements and Utilities

- **Color and Formatting**: Enhancements for command output readability using colors and formatting for tools like `ls`, `grep`, and `man`.
- **Navigation Shortcuts**: Aliases to simplify directory navigation, e.g., `alias ..='cd ..'` to go up one directory.
- **Safety Features**: Aliases for safer file operations, like using `trash` instead of `rm` for deleting files, to prevent accidental data loss.
- **Extensive Zoxide support**: Easily navigate with `z`, `zi`, or pressing Ctrl+f to launch zi to see frequently used navigation directories.

### Advanced Functions

- **System Information**: Functions to display system information like `distribution()` to identify the Linux distribution.
- **Networking Utilities**: Tools to check internal and external IP addresses.
- **Resource Monitoring**: Commands to monitor system resources like disk usage and open ports.

### Installation and Configuration Helpers

- **Auto-Install**: A function `install_bashrc_support()` to automatically install necessary utilities based on the system type.
- **Configuration Editors**: Functions to edit important configuration files directly, e.g., `apacheconfig()` for Apache server configurations.

**Alias's for SSH**
alias SERVERNAME='ssh YOURWEBSITE.com -l USERNAME -p PORTNUMBERHERE'

Commands +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

### Update system

`install [package]` - updates all repositories and software
`update` - updates all repositories and software
`upgrade` - upgrade distro
`remove` [package name] - remove specified package
`removeall` [package name] - purge specified package (removes config files too)
`historypkg` - show history of installs
`searchpkg` - search packages


### General Alias
`alert [text]` - Add an "alert" alias for long running commands. Use like so: sleep 10; alert
`ebrc` - edit this .bashrc
`hlp` - Show help for this .bashrc file - UNDER development
`da` - Show date
`password` - generate list of random passwords


### Alias to modified commands
cp='cp -i' - copy 
mv='mv -i' - move
rm='rm -iv' - remove
delete='rm -rfi' - remove with options
mkdir='mkdir -p' - create directory
ps='ps auxf'
ping='ping -c 10'
less='less -R'
cls='clear'
apt-get='sudo apt-get' - escalates privileges
multitail='multitail --no-repeat -c'
freshclam='sudo freshclam' - update anti-virus
vi='vim' - editor vim
svi='sudo vi'
vis='vim "+set si"'

### Git related commands
gs='git status'
gc='git commit'
ga='git add'
gd='git diff'
gb='git branch'
gl='git log'
gsb='git show-branch'
gco='git checkout'
gg='git grep'
gk='gitk --all'
gr='git rebase'
gri='git rebase --interactive'
gcp='git cherry-pick'
grm='git rm'

### Change directory aliases
home='cd ~'
cd..='cd ..'
..='cd ..'
...='cd ../..'
....='cd ../../..'
.....='cd ../../../..'

### cd into the old directory
 bd='cd "$OLDPWD"'

### Remove a directory and all files
 rmd='/bin/rm  --recursive --force --verbose '

### Alias's for multiple directory listing commands
 la='ls -Alh' # show hidden files
 ls='ls -aFh --color=always' # add colors and file type extensions
 lx='ls -lXBh' # sort by extension
 lk='ls -lSrh' # sort by size
 lc='ls -lcrh' # sort by change time
 lu='ls -lurh' # sort by access time
 lr='ls -lRh' # recursive ls
 lt='ls -ltrh' # sort by date
 lm='ls -alh |more' # pipe through 'more'
 lw='ls -xAh' # wide listing format
 ll='ls -Fls' # long listing format
 labc='ls -lap' #alphabetical sort
 lf="ls -l | egrep -v '^d'" # files only
 ldir="ls -l | egrep '^d'" # directories only

### alias chmod commands
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

### Search command line history
 h="history | grep "

#Use this for when the boss comes around to look busy.
 busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"

#Show active ports
 ports='netstat -tulanp'

### Search running processes
alias p="ps aux | grep "
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

### Search files in the current folder
alias f="find . | grep "

### Count all files (recursively) in the current folder
 countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

### To see if a command is aliased, a file, or a built-in command
 checkcommand="type -t"

### Show open ports
 openports='netstat -nape --inet'

### Alias's for safe and forced reboots
 restart='sudo shutdown -r now'
 forcerestart='sudo shutdown -r -n now'

### Alias's to show disk space and space used in a folder
 diskspace="du -S | sort -n -r |more"
 folders='du -h --max-depth=1'
 folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
 tree='tree -CAhF --dirsfirst'
 treed='tree -CAFd'
 mountedinfo='df -hT'

### Alias's for archives
 mktar='tar -cvf'
 mkbz2='tar -cvjf'
 mkgz='tar -cvzf'
 untar='tar -xvf'
 unbz2='tar -xvjf'
 ungz='tar -xvzf'

### Show all logs in /var/log

### SHA1
 ungz='tar -xvzf'

### Special functions
edit - Use the best version of pico installed
sedit - 
extract - Extracts any archive(s)
ftext - Searches for text in all files in the current folder 
cpp - copy file with a progress bar
cpg - copy and go to the directory
mvg - move and go to the directory
mkdirg - create and go to the directory
up - Goes up a specified number of directories  (i.e. up 4)
pwdtail - Returns the last 2 fields of the working directory
distribution - Show the current distribution (ERROR)
ver - version (ERROR)
install_bashrc_support - Automatically install the needed support files for this .bashrc file
netinfo - show current network information (ERROR)
whatismyip - show my IP address (ERROR)
apachelog - view apache logs
apacheconfig - edit apache configuration
phpconfig - edit php configuration file (ERROR)
mysqlconfig - edit MySQL configuration
trim - Trim leading and trailing spaces (for scripts)

### Uninstall and Reset Bash to Defaults

Use the script at:

https://github.com/digitalxs/BashProfileReset




### dxsbash - DigitalXS - Programming and Development (2025) by Luis Miguel P. Freitas
