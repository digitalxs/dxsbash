# DXSBash - Enhanced Shell Environment

> **A feature-rich, cross-shell environment for developers and power users**

DXSBash is a comprehensive shell environment that enhances your terminal experience with productivity features, visual improvements, and useful utilities. It supports Bash, Zsh, and Fish shells on multiple Linux distributions.

![DXSBash](images/dxsbash-demo.png)

## Features

- **Multi-shell support**: Choose between Bash, Zsh, or Fish shell with consistent features
- **Visual enhancements**: Modern prompt with Starship, system information with Fastfetch
- **Productivity tools**: Smart directory navigation, enhanced history, improved command completion
- **Development utilities**: Git integration, programming language version detection
- **Cross-distribution compatibility**: Works on Debian, Ubuntu, Fedora, RHEL, Arch and more
- **KDE integration**: Automatic Konsole and Yakuake configuration with FiraCode Nerd Font

## Installation

### Manual installation

```bash
git clone --depth=1 https://github.com/digitalxs/dxsbash.git
cd dxsbash
chmod +x setup.sh
./setup.sh
```

The installation script will:
1. Detect your Linux distribution
2. Let you choose your preferred shell (Bash, Zsh, or Fish)
3. Install all necessary dependencies
4. Configure your shell with enhanced features
5. Set your chosen shell as the default
6. Configure KDE terminal emulators (if detected)

## Key Components

### Shell Configurations
- `.bashrc` - Enhanced Bash configuration
- `.zshrc` - Zsh configuration with similar functionality
- `config.fish` - Fish shell configuration

### Visual Enhancements
- **Starship prompt**: Cross-shell prompt with git status, command duration, etc.
- **Fastfetch**: System information display
- **FiraCode Nerd Font**: Font with programming ligatures and icons

### Navigation Tools
- **Zoxide**: Smart directory jumping (`z`, `zi`)
- **FZF**: Fuzzy finder for files, history, and more

### Keyboard Shortcuts
- `Ctrl+R`: Search command history
- `Ctrl+F`: Open interactive directory selector
- `Alt+C`: Change to selected directory (with FZF)

### Shell-specific Enhancements
- **Zsh**: Oh My Zsh, syntax highlighting, autosuggestions
- **Fish**: Fisher plugin manager, tide prompt

## Commands and Aliases

### System Management
- `update`: Update system packages
- `install [package]`: Install packages
- `cleanup`: Clean package caches
- `whatsmyip`: Show internal and external IP addresses

### File Operations
- `extract <file>`: Extract archives of any type
- `mkdirg <dir>`: Create and navigate to directory
- `cpg <src> <dest>`: Copy and go to destination
- `mvg <src> <dest>`: Move and go to destination

### Directory Navigation
- `..`, `...`, `....`: Go up 1, 2, or 3 directories
- `bd`: Go back to previous directory
- `up <n>`: Go up n directories

### Directory Listing
- `la`: List all files (including hidden)
- `ll`: Long listing format
- `lt`: Sort by modification time
- `lk`: Sort by size
- `lf`: List only files
- `ldir`: List only directories

### Git Commands
- `gs`: Git status
- `ga`: Git add
- `gc`: Git commit
- `gp`: Git push
- `gl`: Git log
- `gb`: Git branch
- `gco`: Git checkout

### Search Commands
- `h <pattern>`: Search command history
- `f <pattern>`: Find files by pattern
- `ftext <pattern>`: Search text in files

### System Information
- `diskspace`: Show disk usage
- `folders`: Show size of directories
- `netinfo`: Show network information
- `topcpu`: Show top CPU-consuming processes

## Supported Linux Distributions

- Debian and derivatives (Ubuntu, Linux Mint, etc.)
- Fedora, RHEL, and CentOS
- Arch Linux and derivatives
- OpenSUSE
- Other distributions with compatible package managers

## Customization

You can customize your environment by editing the following files:

- Shell configuration: `.bashrc`, `.zshrc`, or `~/.config/fish/config.fish`
- Prompt: `~/.config/starship.toml`
- Fastfetch: `~/.config/fastfetch/config.jsonc`

## Updating

To update DXSBash to the latest version:

```bash
~/update-dxsbash.sh
```

Or use the global command:

```bash
upbashdxs
```

## Uninstalling

To revert to the default shell configuration:

```bash
sudo reset-shell-profile [username]
```

This will:
- Create a backup of your current configuration
- Restore the default shell configuration files
- Preserve your custom files in the backup directory

## Acknowledgements

This project builds upon many excellent open-source tools:

- [Starship](https://starship.rs/) - Cross-shell prompt
- [Zoxide](https://github.com/ajeetdsouza/zoxide) - Smart directory jumper
- [FZF](https://github.com/junegunn/fzf) - Fuzzy finder
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Fish shell](https://fishshell.com/) and its ecosystem
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch) - System information tool
- [FiraCode Nerd Font](https://www.nerdfonts.com/) - Programming font with icons

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## Contact

For questions, suggestions, or issues:
- GitHub: [digitalxs/dxsbash](https://github.com/digitalxs/dxsbash)
- Email: luis@digitalxs.ca
- Website: https://digitalxs.ca
