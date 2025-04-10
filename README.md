# DXSBash - Enhanced Shell Environment For Debian (but you can try on other distros)
v2.1.5
<div align="center">
    <a href="https://digitalxs.ca">
        <img src="https://blog.digitalxs.ca/wp-content/uploads/2023/11/cropped-logo300_1-1.png" alt="DXSBash Logo" width="100">
    </a>

<h3>Professional Shell Environment for Linux Power Users</h3>

[![Debian](https://img.shields.io/badge/Tested%20on-Debian-D70A53?logo=debian&logoColor=white)](https://www.debian.org/)
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

## Software Dependencies

DXSBash installs and uses the following software packages to enhance the Linux terminal experience and DXSBash would not be possible without them:

### Core Shells
| Software | Description | Project Link |
|----------|-------------|--------------|
| Bash | GNU Bourne Again Shell | [gnu.org/software/bash](https://www.gnu.org/software/bash/) |
| Zsh | Z Shell | [zsh.org](https://www.zsh.org/) |
| Fish | Friendly Interactive Shell | [fishshell.com](https://fishshell.com/) |

### Terminal Enhancement Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| Starship | Cross-shell prompt | [starship.rs](https://starship.rs/) |
| Zoxide | Smart directory navigation | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| FZF | Fuzzy finder | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| Fastfetch | System information display | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Bat/Batcat | Improved cat command | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| Ripgrep | Fast text search | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| Tree | Directory visualization | [mama.indstate.edu/users/ice/tree](http://mama.indstate.edu/users/ice/tree/) |
| Multitail | Enhanced log viewing | [vanheusden.com/multitail](https://www.vanheusden.com/multitail/) |

### Fonts
| Software | Description | Project Link |
|----------|-------------|--------------|
| FiraCode Nerd Font | Programming font with ligatures and icons | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |

### Shell-Specific Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| Oh My Zsh | Zsh framework | [ohmyz.sh](https://ohmyz.sh/) |
| zsh-autosuggestions | Command suggestions for Zsh | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| zsh-syntax-highlighting | Syntax highlighting for Zsh | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |
| Fisher | Plugin manager for Fish | [github.com/jorgebucaran/fisher](https://github.com/jorgebucaran/fisher) |
| fzf.fish | FZF integration for Fish | [github.com/PatrickF1/fzf.fish](https://github.com/PatrickF1/fzf.fish) |
| Tide | Fish prompt | [github.com/IlanCosman/tide](https://github.com/IlanCosman/tide) |

### Development Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| Git | Version control system | [git-scm.com](https://git-scm.com/) |
| Neovim | Text editor | [neovim.io](https://neovim.io/) |
| Nano | Simple text editor | [nano-editor.org](https://www.nano-editor.org/) |
| Joe | Text editor | [joe-editor.sourceforge.net](https://joe-editor.sourceforge.net/) |

### System Utilities
| Software | Description | Project Link |
|----------|-------------|--------------|
| Nala | APT frontend | [github.com/volitank/nala](https://github.com/volitank/nala) |
| Trash-cli | Safer alternative to rm | [github.com/andreafrancia/trash-cli](https://github.com/andreafrancia/trash-cli) |
| Curl | URL transfer tool | [curl.se](https://curl.se/) |
| Wget | File retrieval tool | [gnu.org/software/wget](https://www.gnu.org/software/wget/) |
| Unzip | Archive extraction | [infozip.sourceforge.net/UnZip.html](https://infozip.sourceforge.net/UnZip.html) |
| Pwgen | Password generator | [sourceforge.net/projects/pwgen](https://sourceforge.net/projects/pwgen/) |
| Powerline | Status line | [github.com/powerline/powerline](https://github.com/powerline/powerline) |
| Plocate | Fast file search | [plocate.sesse.net](https://plocate.sesse.net/) |
| Fontconfig | Font management | [freedesktop.org/wiki/Software/fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/) |
| Bash-completion | Improved shell completion | [github.com/scop/bash-completion](https://github.com/scop/bash-completion) |

### Network Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| Nmcli | Network management CLI | [developer.gnome.org/NetworkManager/stable/nmcli.html](https://developer.gnome.org/NetworkManager/stable/nmcli.html) |
| Netstat | Network statistics | [net-tools.sourceforge.net](https://net-tools.sourceforge.net/) |

### UI Automation Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| XDotool | X11 automation tool | [github.com/jordansissel/xdotool](https://github.com/jordansissel/xdotool) |
| XClip | Clipboard management | [github.com/astrand/xclip](https://github.com/astrand/xclip) |

### Container and Orchestration Tools
| Software | Description | Project Link |
|----------|-------------|--------------|
| Docker | Container platform | [docker.com](https://www.docker.com/) |
| Docker Compose | Multi-container Docker | [docs.docker.com/compose](https://docs.docker.com/compose/) |
| Kubectl | Kubernetes CLI | [kubernetes.io/docs/reference/kubectl](https://kubernetes.io/docs/reference/kubectl/) |

### Package Managers
| Software | Description | Project Link |
|----------|-------------|--------------|
| DNF | Fedora package manager | [dnf.readthedocs.io](https://dnf.readthedocs.io/) |
| Zypper | SUSE package manager | [en.opensuse.org/Portal:Zypper](https://en.opensuse.org/Portal:Zypper) |
| Pacman | Arch package manager | [archlinux.org/pacman](https://archlinux.org/pacman/) |
| Emerge | Gentoo package manager | [wiki.gentoo.org/wiki/Portage](https://wiki.gentoo.org/wiki/Portage) |
| XBPS | Void Linux package manager | [voidlinux.org/usage/xbps](https://voidlinux.org/usage/xbps/) |
| Nix | NixOS package manager | [nixos.org/manual/nix](https://nixos.org/manual/nix/stable/) |
| Yay/Paru | AUR helpers | [github.com/Jguer/yay](https://github.com/Jguer/yay) / [github.com/Morganamilo/paru](https://github.com/Morganamilo/paru) |

### Terminal Emulators
| Software | Description | Project Link |
|----------|-------------|--------------|
| Konsole | KDE terminal | [konsole.kde.org](https://konsole.kde.org/) |
| Yakuake | KDE drop-down terminal | [kde.org/applications/system/org.kde.yakuake](https://kde.org/applications/system/org.kde.yakuake) |
| Kitty | GPU-accelerated terminal | [sw.kovidgoyal.net/kitty](https://sw.kovidgoyal.net/kitty/) |

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
