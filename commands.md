# DXSBash Commands Reference

<div style="background-color: #E3F2FD; padding: 16px; border-radius: 4px; margin-bottom: 24px; border-left: 4px solid #2196F3;">
  <strong>Note:</strong> This document provides a comprehensive list of all commands and aliases available in the DXSBash environment.
</div>

## 📂 Navigation Commands

| Command | Description |
|:--------|:------------|
| `home` | Go to home directory |
| `cd..` | Go up one directory |
| `..` | Go up one directory |
| `...` | Go up two directories |
| `....` | Go up three directories |
| `.....` | Go up four directories |
| `up N` | Go up N directories |
| `bd` | Go back to previous directory |
| `z DIR` | Jump to frequently used directory matching DIR (using zoxide) |
| `zi` | Interactive directory selection with zoxide |
| `root` | Change to root directory (/) |
| `web` | Change to web server directory (/var/www/html) |

## 📋 Directory Listing Commands

| Command | Description |
|:--------|:------------|
| `la` | List all files including hidden (`ls -Alh`) |
| `ls` | List with colors and file type extensions (`ls -aFh --color=always`) |
| `lx` | Sort files by extension (`ls -lXBh`) |
| `lk` | Sort files by size (`ls -lSrh`) |
| `lc` | Sort files by change time (`ls -ltcrh`) |
| `lu` | Sort files by access time (`ls -lturh`) |
| `lr` | Recursive listing (`ls -lRh`) |
| `lt` | Sort files by date (`ls -ltrh`) |
| `lm` | Pipe listing through 'more' (`ls -alh | more`) |
| `lw` | Wide listing format (`ls -xAh`) |
| `ll` | Long listing format (`ls -Fls`) |
| `labc` | Alphabetical sort (`ls -lap`) |
| `lf` | List files only (no directories) |
| `ldir` | List directories only |
| `lla` | List and show hidden files (`ls -Al`) |
| `las` | List hidden files (`ls -A`) |
| `lls` | List with details (`ls -l`) |

## 📄 File Operations

| Command | Description |
|:--------|:------------|
| `cp` | Copy (interactive mode) |
| `mv` | Move (interactive mode) |
| `rm` | Remove (interactive verbose mode) |
| `delete` | Safer remove with confirmation (`rm -rfi`) |
| `mkdir` | Create directory with parents automatically (`mkdir -p`) |
| `rmd` | Remove directory and all contents (`/bin/rm --recursive --force --verbose`) |
| `cpg SRC DEST` | Copy and change to destination directory |
| `mvg SRC DEST` | Move and change to destination directory |
| `mkdirg DIR` | Create and change to directory |
| `cpp SRC DEST` | Copy with progress bar |
| `extract FILE` | Extract archives of any type automatically |

## 🔒 File Permissions

| Command | Description |
|:--------|:------------|
| `mx FILE` | Make file executable (`chmod a+x`) |
| `000` | Set permissions to 000 (`chmod -R 000`) |
| `644` | Set permissions to 644 (`chmod -R 644`) |
| `666` | Set permissions to 666 (`chmod -R 666`) |
| `755` | Set permissions to 755 (`chmod -R 755`) |
| `777` | Set permissions to 777 (`chmod -R 777`) |

## 🔍 Search Commands

| Command | Description |
|:--------|:------------|
| `f PATTERN` | Find files in current folder matching pattern |
| `h PATTERN` | Search command history for pattern |
| `p PATTERN` | Search running processes for pattern |
| `ftext TEXT` | Search for text in all files in current folder |
| `countfiles` | Count all files, links, and directories in current folder |
| `findtext PATTERN` | Find files containing text (alias for grep) |
| `findf PATTERN` | Find files by name excluding .git |
| `findd PATTERN` | Find directories by name excluding .git |
| `findlarge [SIZE]` | Find large files (default: >100MB) |

## 🖥️ System Information

| Command | Description |
|:--------|:------------|
| `diskspace` | Show disk usage sorted by size |
| `folders` | Show top-level folder sizes |
| `folderssort` | Sort folders by size |
| `mountedinfo` | Show mounted filesystems (`df -hT`) |
| `meminfo` | Show detailed memory information (`free -m -l -t`) |
| `cpuinfo` | Show CPU information (`lscpu`) |
| `topcpu` | Show top CPU-consuming processes |
| `ps` | Enhanced process listing (`ps auxf`) |
| `ver` | Show detailed OS version information |
| `distribution` | Show current Linux distribution |

## 🌐 Network Commands

| Command | Description |
|:--------|:------------|
| `whatsmyip` | Show internal and external IP addresses |
| `whatismyip` | Alias for whatsmyip |
| `netinfo` | Show current network information |
| `ports` | Show active ports (`netstat -tulanp`) |
| `openports` | Show open ports (`netstat -nape --inet`) |
| `listening` | Show only listening connections (`netstat -tlnp`) |
| `ipview` | Show current network connections to the server |
| `path` | Display PATH entries one per line |
| `fastping` | Quick ping for network testing |

## 📦 Package Management

| Command | Description |
|:--------|:------------|
| `install PKG` | Update and install package (`sudo nala update && sudo nala install -y`) |
| `update` | Update system packages (`sudo nala update && sudo nala upgrade -y`) |
| `upgrade` | Perform distribution upgrade (`sudo nala update && sudo apt-get dist-upgrade`) |
| `remove PKG` | Remove packages (`sudo nala update && sudo nala remove`) |
| `removeall PKG` | Purge packages completely (`sudo nala purge`) |
| `historypkg` | Show package installation history (`nala history`) |
| `searchpkg TERM` | Search for packages (`sudo nala search`) |

## 📝 Git Commands

| Command | Description |
|:--------|:------------|
| `gs` | Git status |
| `gc` | Git commit |
| `ga` | Git add |
| `gd` | Git diff |
| `gb` | Git branch |
| `gl` | Git log |
| `gsb` | Git show-branch |
| `gco` | Git checkout |
| `gcob` | Create and checkout branch |
| `gg` | Git grep |
| `gk` | Gitk with all branches |
| `gr` | Git rebase |
| `gri` | Git rebase interactive |
| `gcp` | Git cherry-pick |
| `grm` | Git remove |
| `gca` | Git commit amend |
| `gcm` | Git commit with message |
| `gf` | Git fetch |
| `gt` | Git tag |
| `gm` | Git merge |
| `glog` | Git log with pretty format |
| `gloga` | Git log with pretty format (all branches) |
| `gst` | Git stash |
| `gstp` | Git stash pop |
| `gundo` | Undo last commit preserving changes |

## 🐳 Docker Commands

| Command | Description |
|:--------|:------------|
| `dps` | List running containers (`docker ps`) |
| `dpsa` | List all containers (`docker ps -a`) |
| `di` | List images (`docker images`) |
| `dex` | Execute interactive shell (`docker exec -it`) |
| `drun` | Run interactive container (`docker run -it`) |
| `dip` | Get container IP address |
| `dlogs` | Show container logs (`docker logs`) |
| `dclean` | Clean unused images and containers (`docker system prune -a`) |
| `dstop` | Stop all running containers |
| `docker-clean` | Clean unused docker containers, images, networks, and volumes |

### Docker Compose Commands

| Command | Description |
|:--------|:------------|
| `dc` | Docker compose shortcut |
| `dcup` | Start in background (`docker-compose up -d`) |
| `dcdown` | Stop and remove (`docker-compose down`) |
| `dcrestart` | Restart services (`docker-compose restart`) |
| `dclogs` | Follow logs (`docker-compose logs -f`) |

## ☸️ Kubernetes Commands

| Command | Description |
|:--------|:------------|
| `k` | Kubectl shortcut |
| `kg` | Get resources (`kubectl get`) |
| `kgp` | Get pods (`kubectl get pods`) |
| `kgs` | Get services (`kubectl get services`) |
| `kgn` | Get nodes (`kubectl get nodes`) |
| `kd` | Describe resources (`kubectl describe`) |
| `kdp` | Describe pod (`kubectl describe pod`) |
| `kl` | View logs (`kubectl logs`) |
| `ke` | Execute interactive (`kubectl exec -it`) |
| `kaf` | Apply from file (`kubectl apply -f`) |
| `kdf` | Delete from file (`kubectl delete -f`) |
| `kctx` | Switch context (`kubectl config use-context`) |
| `kns` | Switch namespace (`kubectl config set-context --current --namespace`) |

## 🐍 Python Development

| Command | Description |
|:--------|:------------|
| `py` | Python 3 shortcut (`python3`) |
| `py2` | Python 2 shortcut (`python2`) |
| `pipinstall` | Install requirements (`pip install -r requirements.txt`) |
| `ve` | Create virtual environment (`python3 -m venv ./venv`) |
| `va` | Activate virtual environment (`source ./venv/bin/activate`) |
| `vd` | Deactivate virtual environment |

## 📱 Node.js Development

| Command | Description |
|:--------|:------------|
| `ni` | Install dependencies (`npm install`) |
| `nid` | Install dev dependencies (`npm install --save-dev`) |
| `nig` | Install global package (`npm install -g`) |
| `ns` | Start application (`npm start`) |
| `nt` | Run tests (`npm test`) |
| `nb` | Build application (`npm run build`) |
| `nr` | Run script (`npm run`) |
| `noup` | Update packages (`npm update`) |

## 📝 Text Editors

| Command | Description |
|:--------|:------------|
| `edit` | Auto-select best editor available |
| `sedit` | Auto-select best editor with sudo |
| `vi` | Alias for vim |
| `vim` | Alias for nvim (Neovim) |
| `svi` | Run vim with sudo |
| `vis` | Run nvim with 'set si' |
| `spico` | Run pico with sudo (alias for sedit) |
| `snano` | Run nano with sudo |
| `ebrc` | Edit .bashrc file |
| `ezrc` | Edit .zshrc file |
| `efrc` | Edit fish config file |

## 📦 Archive Operations

| Command | Description |
|:--------|:------------|
| `mktar FILE.tar` | Create tar archive |
| `mkbz2 FILE.tar.bz2` | Create bz2 archive |
| `mkgz FILE.tar.gz` | Create gz archive |
| `untar FILE` | Extract tar archive |
| `unbz2 FILE` | Extract bz2 archive |
| `ungz FILE` | Extract gz archive |
| `extract FILE` | Auto-extract based on extension |

## 🖥️ Server Administration

| Command | Description |
|:--------|:------------|
| `apachelog` | View Apache logs |
| `apacheconfig` | Edit Apache configuration |
| `phpconfig` | Edit PHP configuration |
| `mysqlconfig` | Edit MySQL configuration |
| `logs` | Show all logs in /var/log |
| `port NUMBER` | Find process using a specific port |
| `restart` | Safe reboot (`sudo shutdown -r now`) |
| `forcerestart` | Forced reboot (`sudo shutdown -r -n now`) |
| `turnoff` | Power off system (`sudo poweroff`) |

## 🛠️ Utilities

| Command | Description |
|:--------|:------------|
| `help` | Show help for shell configuration |
| `help TOPIC` | Show help for specific topic |
| `alert` | Alert when command completes |
| `tree` | Directory tree with colors (`tree -CAhF --dirsfirst`) |
| `treed` | Show only directories in tree (`tree -CAFd`) |
| `da` | Show current date and time with timezone |
| `ping` | Enhanced ping with count of 10 |
| `cls` | Clear the screen |
| `checkcommand CMD` | Check if a command is aliased, a file, or built-in |
| `busy` | Look busy for the boss (random hex dump) |
| `look-busy` | Alternative "look busy" script |
| `weather` | Show weather report for current location |
| `weather-short` | Show compact weather report |
| `cpu` | Get CPU usage percentage |
| `pwdtail` | Return last 2 fields of working directory |

### Date and Time Commands

| Command | Description |
|:--------|:------------|
| `cal` | Show 3 months of calendar |
| `now` | Show current time |
| `nowtime` | Show current time |
| `nowdate` | Show current date |

### Security and Random Generation Commands

| Command | Description |
|:--------|:------------|
| `sha1` | Generate SHA1 hash |
| `random-string` | Generate random string |
| `calc` | Command-line calculator |
| `genpass` | Generate secure password |
| `password` | Generate password with pwgen |

## 🔄 Clipboard Operations

| Command | Description |
|:--------|:------------|
| `trim TEXT` | Trim leading and trailing spaces |
| `cat` | Enhanced cat command using bat/batcat |
| `grep` | Enhanced grep with ripgrep if available |
| `clickpaste` | Paste clipboard content after delay |
| `setclip` | Copy to clipboard (with xclip) |
| `getclip` | Paste from clipboard (with xclip) |

## ⏱️ Timers and Counters

| Command | Description |
|:--------|:------------|
| `countdown N` | Countdown timer for N seconds |
| `timer` | Simple timer (press Enter to stop) |

## 🔧 System Management

| Command | Description |
|:--------|:------------|
| `where CMD` | Better alternative to 'which' command |
| `bk CMD` | Run command in background |
| `cheat CMD` | Display cheatsheet for a command |
| `install_bashrc_support` | Install required dependencies for bashrc |
| `install_zshrc_support` | Install required dependencies for zshrc |
| `install_fish_support` | Install required dependencies for fish |
| `upbashdxs` | Update dxsbash to latest version |
| `reset-shell-profile` | Reset to default shell configuration |
| `kssh` | SSH with Kitty terminal features |

<div style="background-color: #FFEBEE; padding: 16px; border-radius: 4px; margin-top: 24px; border-left: 4px solid #F44336;">
  <strong>Warning:</strong> Commands like chmod (000, 644, 666, 755, 777) use recursive flag (-R). Use with caution as they affect all files in the current directory and subdirectories.
</div>

<div style="background-color: #E8F5E9; padding: 16px; border-radius: 4px; margin-top: 24px; border-left: 4px solid #4CAF50;">
  <strong>Tip:</strong> Use <code>help TOPIC</code> to get detailed information about specific command categories. Available topics include: git, zoxide, fzf, nvim, shells, kde, starship, aliases, update, and reset.
</div>
