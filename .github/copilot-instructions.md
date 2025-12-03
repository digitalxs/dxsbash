# Copilot Instructions for DXSBash

## Project Overview
DXSBash is a shell enhancement suite for Linux (Debian 13 focus) that provides a unified, feature-rich environment across Bash, Zsh, and Fish. It integrates productivity tools, visual improvements, and optimized workflows for developers and sysadmins.

## Architecture & Key Files
- **Shell configs:** `.bashrc`, `.zshrc`, `config.fish` (core logic, aliases, plugin loading)
- **Scripts:** `setup.sh` (installer), `updater.sh` (update logic), `reset-bash-profile.sh`, `reset-zsh-profile.sh`, `reset-fish-profile.sh` (restore defaults)
- **Config files:** `starship.toml` (prompt), `config.jsonc` (fastfetch/system info)
- **Utilities:** `dxsbash-utils.sh`, `dxsbash-config.sh` (shared functions, config helpers)
- **Commands Reference:** `commands.md` (all commands, aliases, and usage)

## Developer Workflows
- **Install:** Run `./setup.sh` (auto-detects shell, installs dependencies, configures environment)
- **Update:** Run `update-dxsbash` (updates DXSBash to latest version)
- **Reset:** Use `reset-bash-profile.sh`, `reset-zsh-profile.sh`, or `reset-fish-profile.sh` to revert shell config
- **Test compatibility:** Run `test_compatibility.sh` for environment checks
- **Uninstall:** Run `sudo reset-shell-profile [username]`

## Patterns & Conventions
- **Aliases/functions:** Defined in shell config files and documented in `commands.md`. Use the interactive help system (`help <topic>`, `help --search`, `help --examples`).
- **Conditional loading:** Many command groups (Docker, Kubernetes, Python, Node.js, clipboard) only load if the required tool is installed. Check for missing aliases and install dependencies as needed.
- **Safer operations:** Permission-changing commands require confirmation. Dangerous operations show warnings and alternatives.
- **Cross-shell support:** All enhancements are designed to work in Bash, Zsh, and Fish. Some features (Konsole/Yakuake config) are terminal-specific.

## Integration Points
- **External tools:** Starship, Zoxide, FZF, Fastfetch, Bat, Ripgrep, Tree, Multitail, Oh My Zsh, Fisher, Tide, Docker, Kubectl, Nala, Trash-cli, etc. See README.md for full list.
- **Terminal emulators:** Konsole, Yakuake, Kitty, XFce Terminal (font settings may need manual adjustment)
- **Package managers:** Nala, apt, pacman, yay, paru, dnf, zypper, emerge, xbps, nix (auto-detected)

## Examples
- Add a new alias: Edit `.bashrc`, `.zshrc`, or `config.fish` and document in `commands.md`
- Add a new tool integration: Update `setup.sh` to install dependencies, add conditional logic to shell configs
- Update prompt: Edit `starship.toml` and reload shell

## Tips
- Use the enhanced help system for command discovery and usage examples
- Reference `commands.md` for all available commands and their descriptions
- When adding new features, ensure cross-shell compatibility and document changes

---
For questions, see [README.md](../README.md) or contact the maintainer.
