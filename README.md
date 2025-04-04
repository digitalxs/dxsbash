# DXSBash - Enhanced Shell Environment
v2.1.5
<div align="center">
    <a href="https://digitalxs.ca">
        <img src="https://blog.digitalxs.ca/wp-content/uploads/2023/11/cropped-logo300_1-1.png" alt="DXSBash Logo" width="100">
    </a>
    <h3>Professional Shell Environment for Linux Power Users</h3>

[![GPL License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Zsh](https://img.shields.io/badge/Shell-Zsh-071D49?logo=zsh&logoColor=white)](https://www.zsh.org/)
[![Fish](https://img.shields.io/badge/Shell-Fish-394655?logo=fish&logoColor=white)](https://fishshell.com/)

<a href="https://www.buymeacoffee.com/digitalxs" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45"></a>

</div>

DXSBash is a shell enhancement suite designed for developers, system administrators, and Linux power users. It provides a consistent, feature-rich experience across multiple shells and distributions, combining productivity tools, visual improvements, and optimized workflows.

Tested extensively on Debian 12. Please test on any system and send e-mail with detailed info with results, bugs, etc...

## Key Features

- **Cross-shell compatibility** - Works seamlessly with Bash, Zsh, and Fish
- **Distribution-quasi-agnostic** - Made for Debian 12,but working on Ubuntu, Fedora, RHEL, Arch, and more
- **Smart navigation** - Enhanced directory jumping, fuzzy search, and history management
- **Beautiful interface** - Modern prompt, system information display, and optimized typography
- **Development tools** - Git integration, language version detection, and shortcuts
- **KDE integration** - Custom Konsole and Yakuake profiles with optimized settings

## Installation

```bash
git clone --depth=1 https://github.com/digitalxs/dxsbash.git
cd dxsbash
chmod +x setup.sh
./setup.sh
```
## Installation with one command
```
curl -fsSL https://raw.githubusercontent.com/digitalxs/dxsbash/refs/heads/main/install.sh | bash
```

The installer provides an interactive experience:
1. Detects your Linux distribution automatically
2. Lets you choose your preferred shell (Bash, Zsh, or Fish)
3. Installs all required dependencies
4. Configures your chosen shell with enhanced features
5. Sets up visual elements and productivity tools
6. Configures KDE terminal emulators when available

## Core Components

### Shell Configurations
- `.bashrc` - Enhanced Bash configuration
- `.zshrc` - Zsh configuration with plugins
- `config.fish` - Fish shell configuration

### Tools Included
- **Starship** - Cross-shell prompt with rich information
- **Zoxide** - Smarter directory navigation
- **FZF** - Fuzzy finder for files and history
- **Fastfetch** - Optimized system information display
- **FiraCode Nerd Font** - Programming font with ligatures and icons

### Keyboard Shortcuts
- `Ctrl+R` - Search command history with fuzzy matching
- `Ctrl+F` - Launch interactive directory navigator
- `Alt+C` - Change to selected directory via fuzzy finder

## Command Reference

### System Management
- `update` - Update system packages
- `install [package]` - Install packages with updates
- `whatsmyip` - Show internal and external IP addresses

### File Operations
- `extract <file>` - Extract any archive type automatically
- `mkdirg <dir>` - Create and navigate to directory
- `cpg <src> <dest>` - Copy and go to destination
- `mvg <src> <dest>` - Move and go to destination

### Directory Navigation
- `..`, `...`, `....` - Go up 1, 2, or 3 directories
- `bd` - Go back to previous directory
- `up <n>` - Go up n directories

### Git Operations
- `gs` - Git status
- `ga` - Git add
- `gc` - Git commit
- `gp` - Git push
- `gl` - Git log
- `gb` - Git branch
- `gco` - Git checkout

## Customization

You can customize your environment by editing:

- Shell configuration: `.bashrc`, `.zshrc`, or `~/.config/fish/config.fish`
- Prompt: `~/.config/starship.toml`
- System info: `~/.config/fastfetch/config.jsonc`

## Updating

Update to the latest version:

```bash
upbashdxs
```
## Cross-Platform Compatibility Issues
- Linux-specific Commands: Some commands (like netstat-based aliases) might not work correctly on all Linux distributions or might have different output formats.
- X11-dependent Features: Commands like clickpaste rely on X11 utilities (xdotool) which won't work in Wayland or headless environments.
- Hardware-dependent Commands: The cpu function assumes a specific format in /proc/stat, which might not be consistent across all Linux kernels.
- Terminal-specific Features: The Konsole and Yakuake configurations might not translate well to other terminal emulators.

## Uninstalling

Revert to default shell configuration:

```bash
sudo reset-shell-profile [username]
```

## Tested compatibility
DXSBash was successfully compatibility tested with:
- Debian 12.9
- Konsole  22.12.3
- Yakuake 22.12.3
- XFce Terminal 1.0.4 (Need to change font settings to Firacode Nerd Font Regular)
- Kitty 0.26.5


## Support Development

If you find DXSBash valuable for your workflow, consider supporting its development:

<div align="center">
<a href="https://www.buymeacoffee.com/digitalxs" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45"></a>
</div>

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contact

- GitHub: [digitalxs/dxsbash](https://github.com/digitalxs/dxsbash)
- Email: luis@digitalxs.ca
- Website: [https://digitalxs.ca](https://digitalxs.ca)
