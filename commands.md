# DXSBash Commands Reference

<div style="background-color: #E3F2FD; padding: 16px; border-radius: 4px; margin-bottom: 24px; border-left: 4px solid #2196F3;">
  <strong>📖 Interactive Help System:</strong> Use <code>help &lt;topic&gt;</code> for detailed information, <code>help --search</code> to find commands, or <code>help --examples</code> for practical usage examples.
</div>

## 🎯 Quick Access

### Essential Commands
- `help <topic>` - Interactive help system with detailed guides
- `help --search <keyword>` - Search commands by keyword  
- `help --examples` - Show practical usage examples
- `help --list` - List all available help topics

### Keyboard Shortcuts
- `Ctrl+R` - Fuzzy search command history with FZF
- `Ctrl+F` - Launch interactive directory navigator (zoxide)
- `Alt+C` - Change to selected directory via fuzzy finder
- `Tab` - Enhanced auto-completion with descriptions

## 📂 Navigation Commands

| Command | Description |
|:--------|:------------|
| `z <dir>` | Smart directory jumping (learns your habits) |
| `zi` | Interactive directory selection with preview |
| `home` | Go to home directory |
| `cd..` | Go up one directory |
| `..` | Go up one directory |
| `...` | Go up two directories |
| `....` | Go up three directories |
| `.....` | Go up four directories |
| `up N` | Go up N directories |
| `bd` | Go back to previous directory |
| `root` | Change to root directory (/) |
| `web` | Change to web server directory (/var/www/html) |
| `mkdirg <dir>` | Create directory and change to it |
| `pwdtail` | Show last 2 directories of current path |

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
| `lm` | Pipe listing through 'more' (`ls -alh \| more`) |
| `lw` | Wide listing format (`ls -xAh`) |
| `ll` | Long listing format (`ls -Fls`) |
| `labc` | Alphabetical sort (`ls -lap`) |
| `lf` | List files only (no directories) |
| `ldir` | List directories only |
| `lla` | List and show hidden files (`ls -Al`) |
| `las` | List hidden files (`ls -A`) |
| `lls` | List with details (`ls -l`) |
| `tree` | Directory tree with colors and icons |
| `treed` | Show only directories in tree format |

## 📄 File Operations

| Command | Description |
|:--------|:------------|
| `cp` | Copy (interactive mode with confirmation) |
| `mv` | Move (interactive mode with confirmation) |
| `rm` | Remove (interactive verbose mode) |
| `delete` | Safer remove with confirmation (`rm -rfi`) |
| `mkdir` | Create directory with parents automatically (`mkdir -p`) |
| `rmd` | Remove directory and all contents (verbose) |
| `cpg <src> <dest>` | Copy and change to destination directory |
| `mvg <src> <dest>` | Move and change to destination directory |
| `cpp <src> <dest>` | Copy with progress bar (uses rsync if available) |
| `extract <file>` | Extract archives of any type automatically |
| `mx <file>` | Make file executable (`chmod a+x`) |

## 🔒 File Permissions (Enhanced Safety)

| Command | Description |
|:--------|:------------|
| `mx <file>` | Make file executable |
| `644 [target]` | Set permissions to 644 (with confirmation prompt) |
| `755 [target]` | Set permissions to 755 (with confirmation prompt) |
| `000` | Show warning about 000 permissions |
| `666` | Show info about 666 permissions |
| `777` | Show warning about security risks of 777 permissions |

<div style="background-color: #FFEBEE; padding: 16px; border-radius: 4px; margin: 16px 0; border-left: 4px solid #F44336;">
  <strong>⚠️ Security Improvement:</strong> Dangerous recursive chmod aliases have been replaced with safer functions that require confirmation.
</div>

## 🔍 Search Commands

| Command | Description |
|:--------|:------------|
| `f <pattern>` | Find files in current folder matching pattern |
| `h <pattern>` | Search command history for pattern |
| `p <pattern>` | Search running processes for pattern |
| `ftext <text>` | Search for text in all files in current folder |
| `countfiles` | Count all files, links, and directories in current folder |
| `findtext <pattern>` | Find files containing text (excluding .git) |
| `findf <pattern>` | Find files by name (excluding .git directories) |
| `findd <pattern>` | Find directories by name (excluding .git) |
| `findlarge [size]` | Find files larger than size (default: 100M) |
| `where <command>` | Better alternative to 'which' command |
| `checkcommand <cmd>` | Check if command is alias, file, or builtin |

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
| `cpu` | Show current CPU usage percentage |
| `services` | List all system services (if systemctl available) |

## 🌐 Network Commands

| Command | Description |
|:--------|:------------|
| `whatsmyip` | Show internal and external IP addresses |
| `whatismyip` | Alias for whatsmyip |
| `myip` | Show external IP address only |
| `localip` | Show local IP addresses (simplified) |
| `ips` | List all network interface IP addresses |
| `netinfo` | Show current network information |
| `ports` | Show active ports (`netstat -tulanp`) |
| `openports` | Show open ports (`netstat -nape --inet`) |
| `listening` | Show only listening connections (`netstat -tlnp`) |
| `showport <port>` | Find process using a specific port (renamed from 'port') |
| `ipview` | Show current network connections to the server |
| `fastping <host>` | Quick ping for network testing |
| `path` | Display PATH entries one per line |

## 📦 Package Management

| Command | Description |
|:--------|:------------|
| `install <pkg>` | Update and install package |
| `update` | Update system packages |
| `upgrade` | Perform distribution upgrade |
| `remove <pkg>` | Remove packages |
| `removeall <pkg>` | Purge packages completely |
| `historypkg` | Show package installation history |
| `searchpkg <term>` | Search for packages |

<div style="background-color: #E8F5E9; padding: 16px; border-radius: 4px; margin: 16px 0; border-left: 4px solid #4CAF50;">
  <strong>📦 Smart Package Management:</strong> Commands automatically detect and use the best package manager available (nala, apt, pacman, yay, paru).
</div>

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
| `gcob <branch>` | Create and checkout branch |
| `gg` | Git grep |
| `gk` | Gitk with all branches |
| `gr` | Git rebase |
| `gri` | Git rebase interactive |
| `gcp` | Git cherry-pick |
| `grm` | Git remove |
| `gca` | Git commit amend |
| `gcm <msg>` | Git commit with message |
| `gf` | Git fetch |
| `gt` | Git tag |
| `gm` | Git merge |
| `glog` | Git log with pretty format |
| `gloga` | Git log with pretty format (all branches) |
| `gst` | Git stash |
| `gstp` | Git stash pop |
| `gundo` | Undo last commit preserving changes |

## 🐳 Docker Commands (Conditional Loading)

*These aliases are only available if Docker is installed*

| Command | Description |
|:--------|:------------|
| `dps` | List running containers (`docker ps`) |
| `dpsa` | List all containers (`docker ps -a`) |
| `di` | List images (`docker images`) |
| `dex` | Execute interactive shell (`docker exec -it`) |
| `drun` | Run interactive container (`docker run -it`) |
| `dip` | Get container IP address |
| `dlogs` | Show container logs (`docker logs`) |
| `dclean` | Clean unused images and containers |
| `dstop` | Stop all running containers |
| `docker-clean` | Clean unused containers, images, networks, and volumes |

### Docker Compose Commands (Conditional Loading)

*These aliases are only available if docker-compose is installed*

| Command | Description |
|:--------|:------------|
| `dc` | Docker compose shortcut |
| `dcup` | Start in background (`docker-compose up -d`) |
| `dcdown` | Stop and remove (`docker-compose down`) |
| `dcrestart` | Restart services (`docker-compose restart`) |
| `dclogs` | Follow logs (`docker-compose logs -f`) |

## ☸️ Kubernetes Commands (Conditional Loading)

*These aliases are only available if kubectl is installed*

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
| `kns` | Switch namespace |

## 🐍 Python Development

| Command | Description |
|:--------|:------------|
| `py` | Python 3 shortcut (`python3`) |
| `py2` | Python 2 shortcut (`python2`) |
| `py3` | Explicit Python 3 |
| `pipinstall` | Install requirements (`pip install -r requirements.txt`) |
| `ve <name>` | Create virtual environment |
| `va` | Activate virtual environment (`source ./venv/bin/activate`) |
| `vd` | Deactivate virtual environment |
| `pyvenv <name>` | Create and activate virtual environment in one step |
| `pytime <script>` | Run Python script with timing information |
| `pyprofile <script>` | Profile Python script performance |
| `pyserver [port]` | Start simple HTTP server (default port 8000) |
| `pyjson <file>` | Pretty-print JSON file |
| `pyclean` | Clean all Python cache files (enhanced with feedback) |

### Python Testing & Quality (Conditional Loading)

| Command | Description |
|:--------|:------------|
| `pt` | Run pytest (if available) |
| `ptr` | Run pytest with verbose flags (-xvs) |
| `ptw` | Run pytest-watch (if available) |
| `lint` | Run flake8 linter (if available) |
| `black` | Format code with Black (if available) |
| `mypy` | Run type checking (if available) |
| `ipy` | Launch IPython (if available) |

### Python Web Frameworks

| Command | Description |
|:--------|:------------|
| `djrun` | Run Django development server |
| `djmig` | Run Django migrations |
| `djmm` | Make Django migrations |
| `djsh` | Django shell |
| `djsu` | Create Django superuser |
| `djtest` | Run Django tests |
| `flrun` | Run Flask development server (if available) |
| `flshell` | Flask shell (if available) |

## 📱 Node.js Development (Conditional Loading)

*These aliases are only available if npm is installed*

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
| `spico` | Run pico with sudo |
| `snano` | Run nano with sudo |
| `ebrc` | Edit .bashrc file |

## 📦 Archive Operations

| Command | Description |
|:--------|:------------|
| `mktar <file.tar>` | Create tar archive |
| `mkbz2 <file.tar.bz2>` | Create bzip2 archive |
| `mkgz <file.tar.gz>` | Create gzip archive |
| `untar <file>` | Extract tar archive |
| `unbz2 <file>` | Extract bzip2 archive |
| `ungz <file>` | Extract gzip archive |
| `extract <file>` | Auto-extract based on extension |

## 🖥️ Server Administration

| Command | Description |
|:--------|:------------|
| `apachelog` | View Apache logs |
| `apacheconfig` | Edit Apache configuration |
| `phpconfig` | Edit PHP configuration |
| `mysqlconfig` | Edit MySQL configuration |
| `logs` | Show all logs in /var/log |
| `restart` | Safe reboot (`sudo shutdown -r now`) |
| `forcerestart` | Forced reboot (`sudo shutdown -r -n now`) |
| `turnoff` | Power off system (`sudo poweroff`) |

## 🛠️ Utilities

| Command | Description |
|:--------|:------------|
| `help [topic]` | Enhanced interactive help system |
| `alert` | Alert when command completes |
| `tree` | Directory tree with colors |
| `treed` | Show only directories in tree |
| `da` | Show current date and time with timezone |
| `ping` | Enhanced ping with count of 10 |
| `cls` | Clear the screen |
| `checkcommand <cmd>` | Check if command is aliased, file, or builtin |
| `busy` | Look busy for the boss (random hex dump) |
| `look-busy` | Alternative "look busy" script |
| `weather` | Show weather report (if curl available) |
| `weather-short` | Show compact weather report |
| `bk <command>` | Run command in background with feedback |
| `cheat <command>` | Display cheatsheet for a command (if curl available) |

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

## 🔄 Clipboard Operations (Conditional Loading)

*These aliases are only available if xclip is installed*

| Command | Description |
|:--------|:------------|
| `setclip` | Copy to clipboard (with xclip) |
| `getclip` | Paste from clipboard (with xclip) |
| `clickpaste` | Paste clipboard content after delay |

## ⏱️ Timers and Counters

| Command | Description |
|:--------|:------------|
| `countdown <N>` | Countdown timer for N seconds (with validation) |
| `timer` | Simple timer (press Enter to stop) |

## 🔧 System Management

| Command | Description |
|:--------|:------------|
| `where <cmd>` | Better alternative to 'which' command |
| `bk <cmd>` | Run command in background |
| `cheat <cmd>` | Display cheatsheet for a command |
| `install_bashrc_support` | Install required dependencies for bashrc |
| `upbashdxs` | Update dxsbash to latest version |
| `reset-shell-profile` | Reset to default shell configuration |
| `kssh` | SSH with Kitty terminal features |

## 🎯 Enhanced Functions

### Improved File Operations
- `findlarge [size]` - Now includes input validation and usage examples
- `showport <port>` - Renamed from `port()` to avoid conflicts, includes error checking
- `pyclean` - Enhanced with progress feedback and comprehensive cleanup

### Safer Permission Management
- Permission aliases now require confirmation
- Dangerous operations show warnings with alternatives
- Better error messages and usage guidance

### Conditional Loading
- Tool-specific aliases only load if the tool is installed
- Reduces errors and provides helpful messages when tools are missing
- Improves shell startup performance

<div style="background-color: #FFF3E0; padding: 16px; border-radius: 4px; margin: 24px 0; border-left: 4px solid #FF9800;">
  <strong>🔄 Dynamic Loading:</strong> Many command groups are conditionally loaded based on available tools. If you see missing aliases, install the corresponding tools and reload your shell configuration.
</div>

<div style="background-color: #E8F5E9; padding: 16px; border-radius: 4px; margin-top: 24px; border-left: 4px solid #4CAF50;">
  <strong>💡 Pro Tip:</strong> Use the enhanced help system for detailed guidance:
  <ul>
    <li><code>help navigation</code> - Detailed navigation help</li>
    <li><code>help --search git</code> - Find all git-related commands</li>
    <li><code>help --examples</code> - See practical usage examples</li>
    <li><code>help --list</code> - Browse all available help topics</li>
  </ul>
</div>

<div style="background-color: #FFEBEE; padding: 16px; border-radius: 4px; margin-top: 24px; border-left: 4px solid #F44336;">
  <strong>⚠️ Important Changes:</strong> Dangerous recursive chmod aliases (000, 644, 666, 755, 777) have been replaced with safer functions that require confirmation. The <code>port()</code> function has been renamed to <code>showport()</code> to avoid naming conflicts.
</div>
