# DXSBash Repository Changelog

All notable changes to the DXSBash project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [3.3.1] - 2026-07-10

### Fixed
- **Installer no longer dies on unrelated repository errors**: a broken
  third-party repo (dead PPA, changed label, expired key) made
  `apt update` exit non-zero, which aborted the whole install under
  `set -e`. Update failures are now tolerated with a warning — package
  installation proceeds from the existing lists. (Found by running the
  installer end-to-end on a machine with a stale PPA.)
- **Broken nala no longer breaks the install**: nala is only preferred
  when it actually runs (`nala --version`) — a non-default python3 can
  leave the binary present but unusable (`ModuleNotFoundError:
  apt_pkg`); if nala still fails mid-install, the installer retries
  with apt.
- **doctor.sh dependency checks**: looked for a `ripgrep` command (the
  binary is `rg`) and warned about `bat` on Debian/Ubuntu where it is
  named `batcat` — both produced permanent false warnings on healthy
  installs.

## [3.3.0] - 2026-07-10

### Added
- **`dxsbash` umbrella command** (`/usr/local/bin/dxsbash`): one entry
  point for `update`, `config`, `doctor`, `repair`, `uninstall`,
  `version` and `help`. Installed by setup, re-linked by the updater and
  `dxsbash-repair`, and checked (warn-only) by `dxsbash-doctor`. The
  individual commands keep working unchanged.
- **`update-dxsbash --check`**: reports whether an update exists without
  installing anything (exit 0 = up to date, 10 = update available,
  1 = could not check) — suitable for cron jobs and prompt integrations.
  `--help` is now supported too.
- **Fish support for `dxsbash-config`**: the config tool now also writes
  `~/.dxsbash/user.fish`, which `config.fish` sources — editor choice and
  the fastfetch startup toggle finally apply to fish sessions.
- **Container-based install CI**: every push/PR now runs a full
  non-interactive install (`setup.sh --install --yes --shell bash`)
  inside Debian 13, Debian 12 and Ubuntu 24.04 containers, validated
  with `doctor.sh` plus a config-load smoke test. The lint job enforces
  `shellcheck -S warning` on all scripts.
- **`DXSBASH_SKIP_FONT=1`** environment variable for `setup.sh` to skip
  the ~30 MB Nerd Font download (documented in `--help`; used in CI).
- **`CONTRIBUTING.md`** with development guidelines, the exact checks CI
  runs, and a one-liner to reproduce the container install test locally;
  **`.editorconfig`** for consistent formatting.

### Changed
- **Resilient dependency installation**: `setup.sh` now falls back to
  apt when nala cannot be installed, and skips packages that don't exist
  on the running release (e.g. fastfetch on Debian 12) with a warning
  instead of aborting the whole install under `set -e`.
- **Starship installer** receives `-y` during non-interactive installs,
  so it no longer fails silently when there is no terminal to answer its
  confirmation prompt.
- All lifecycle scripts are now clean under `shellcheck -S warning`
  (declare/assign splits, eval string form, removed unused variables).

## [3.2.0] - 2026-07-10

### Added
- **`aliases [pattern]` helper**: Shell function that lists all active aliases
  and user-defined functions, optionally filtered by a substring pattern
  (matched against name or definition). Shipped for Bash, Zsh, and Fish.
  Complements `commands.md` with live, shell-aware discovery.
- **Interactive `aliases` picker**: When called with no args in a TTY and `fzf`
  is available, `aliases` opens a fuzzy-filter list with a preview pane that
  shows the full definition of the selected alias or function. Falls back to
  the plain sorted listing when `fzf` is missing or output is piped.

### Fixed
- **updater.sh crash on success**: `${WHITE}` was used in the completion
  message but never defined; under `set -u` the updater died with
  "WHITE: unbound variable" at the end of every successful update.
- **updater.sh backup/rollback**: `create_backup` printed INFO/SUCCESS log
  lines to stdout, polluting the captured backup path — the failure check
  could never trigger and `restore_backup` could never find the directory.
  Log output inside the function now goes to stderr.
- **Fish TTY detection and console lockout**: `string match` glob patterns
  don't support `[1-9]` bracket classes, so the console branch never
  matched; and the branch ended with `exit`, which would have terminated
  login shells on a real console. Now uses a regex match and `return`.
- **Zsh `edit`/`sedit` broken**: `type -p` in zsh prints "not found" to
  stdout, so the editor detection always tried the rarely-installed
  `jpico` and failed. Replaced with `command -v` checks.
- **`grep` aliased to `rg`**: removed in bash/zsh/fish — ripgrep's flags
  are incompatible with GNU grep (`rg -r` means `--replace`), which made
  `ftext` silently replace matched text with the letter "n" and broke
  standard `grep -r` habits. ripgrep remains available as `rg`.
- **Oh My Zsh overwrote the dxsbash zsh config**: the OMZ installer
  replaces `~/.zshrc` with its own template even with `--unattended`;
  setup.sh and install_zshrc_support now pass `KEEP_ZSHRC=yes`.
- **setup.sh rejected root/sudo invocations**: the sudo-group check failed
  for root (and wheel-group users); root now passes outright and
  wheel/admin membership is accepted.
- **Bash history flush disabled**: `PROMPT_COMMAND='__setprompt'`
  overwrote the earlier `history -a` hook; both now run per prompt.
- **Unguarded duplicate `zoxide init`** at the end of `.bashrc` printed
  "command not found" on every shell start when zoxide was missing.
- **Prompt date showed month number instead of day** (`Jul-7` all of
  July) in the bash and zsh custom prompts; now uses the day of month.
- **Fish `cat`/package aliases unguarded**: `cat` was aliased to `batcat`
  without checking it exists (breaking `cat` entirely without bat), and
  `install`/`update` hardcoded nala; both now fall back gracefully.
- **Fish `install_fish_support`**: dropped `sudo` from `paru` (AUR
  helpers refuse to run as root) and replaced the dead `git.io/fisher`
  URL with Fisher's canonical install location.
- **fish_help unparseable**: the file used a bash heredoc, which fish
  cannot parse; converted to a fish-native multi-line echo and the fish
  `help` command now executes it (with topic support) instead of paging
  the raw source.
- **Zsh `cpp()` leaked `set -e`** into the interactive shell, killing the
  session on the next failing command.
- **Zsh distro detection**: now recognises Fedora/RHEL and openSUSE
  families instead of warning "unsupported distribution" on every
  startup; bash only warns for genuinely unknown distributions.
- **Removed recursive `000/644/666/755/777` chmod aliases** from zsh and
  fish, matching the removal already done for bash.
- **Self-shadowing aliases**: `black`, `mypy` and `mkdocs` were aliased
  to themselves plus an argument (`black .`, `mkdocs serve`), corrupting
  normal invocations; renamed to `blackall`, `mypyall`, `mkserve`.
- **check_dependencies.sh**: checked for a `ripgrep` command — the binary
  is `rg`, so the check always reported missing.
- **clean.sh**: looked for backups named `dxsbash_backup_*` while the
  updater creates `dxsbash-backup-*`; listed the obsolete `upbashdxs`
  command instead of the helpers actually installed today.
- **`forcerestart`** used `shutdown -n`, which systemd's shutdown does
  not support; now uses `systemctl reboot --force`.
- **CI workflow**: removed the unused `os` matrix (including the invalid
  `debian-latest` runner label) that tripled every job, and removed the
  `|| true` suffixes that made the zsh/fish syntax checks unfailable.
- Guarded the Ctrl+F zoxide keybinding (bash/zsh) and the `vim`→`nvim`
  alias (zsh/fish) behind availability checks.

## [3.1.2] - 2026-04-19

### Added
- **`dxsbash-config` command**: Documented the interactive configuration tool
  installed at `/usr/local/bin/dxsbash-config`. Users can now tune editor,
  shell history, prompt style, Starship theme, and fastfetch-on-startup from
  a single menu. Settings persist in `~/.dxsbash/user.conf`.

### Changed
- **README**: Added a dedicated *Configuration* section explaining
  `dxsbash-config` and what it manages.
- **Commands reference**: Added entries for `dxsbash-config`, `dxsbash-repair`,
  `dxsbash-doctor`, and `dxsbash-uninstall` under System Management.

## [3.0.5] - 2025-12-02

### Fixed
- **Bash fastfetch**: Added missing fastfetch execution at startup in `.bashrc` to match `.zshrc` behavior
- Fastfetch now displays system info on terminal startup for Bash users (skipped in SSH sessions)

## [3.0.4] - 2025-01-20

### Corrected permissions
- Corrected permissions and PATH so it's easier for a administrative user to mantain the system

## [3.0.3] - 2025-01-18

### Added
- Cross-distribution compatibility improvements for Debian 13, Fedora 42, and Arch Linux
- Enhanced updater script with better error handling and logging
- Backup system with automatic cleanup (keeps last 5 backups)

### Changed
- Improved version comparison logic in updater
- Better network connectivity checks with fallback methods
- Enhanced shell detection with symlink analysis

### Fixed
- Git branch detection for both 'main' and 'master' branches
- Race conditions in backup creation with process ID naming

## [3.0.2] - 2025-01-16

### Added
- Comprehensive test suite for updater validation
- Multiple network connectivity testing methods

### Fixed
- Repository consistency issues during updates
- Shell configuration detection and management

## [3.0.1] - 2025-01-15

### Fixed
- Minor bug fixes in setup script
- Improved error messages during installation

## [3.0.0] - 2025-01-15

### Added
- **Major Version Release**: Complete rewrite of core components
- **Enhanced Help System**: Complete rewrite of help documentation with interactive search and topic-based navigation
- **Comprehensive Commands Reference**: New `commands.md` file with detailed command documentation and examples
- **Advanced Bash Aliases**: Extensive `.bash_aliases` file with 200+ professional-grade aliases and functions
- **Conditional Loading**: Smart loading of tool-specific aliases only when tools are installed
- **Python Development Suite**: Complete Python workflow support with virtual environments, testing, and project management
- **Docker & Kubernetes Integration**: Full container orchestration support with intelligent command detection
- **Network Diagnostics**: Advanced network troubleshooting and monitoring commands
- **File Operations**: Safer file permission management with confirmation prompts
- **Enhanced Security**: Replaced dangerous recursive chmod operations with safer confirmation-based functions

### Changed
- **Repository Structure**: Reorganized files for better maintainability and clearer separation of concerns
- **Help System**: Migrated from simple text files to interactive help system with search capabilities
- **Alias Organization**: Categorized aliases by functionality with conditional loading for better performance
- **Error Handling**: Improved error messages and fallback mechanisms throughout all scripts
- **Documentation**: Enhanced README with better installation instructions and compatibility information

### Fixed
- **Critical Updater Bugs**: Fixed version comparison logic and git branch detection issues
- **Shell Compatibility**: Resolved shell-specific configuration conflicts and improved detection
- **Permission Issues**: Fixed file permission problems during installation and updates
- **Network Connectivity**: Enhanced network checks with multiple fallback methods
- **Backup System**: Improved backup creation and cleanup processes

### Security
- **Safer Permissions**: Replaced dangerous permission aliases with confirmation-based functions
- **Input Validation**: Added comprehensive input validation for all user-facing functions
- **Privilege Escalation**: Enhanced detection and handling of sudo/doas/su methods
- **File Operations**: Atomic operations for critical file updates and symlink creation

## [2.2.9] - 2025-01-10

### Fixed
- **CRITICAL**: Fixed inverted version comparison logic in updater script
- **CRITICAL**: Corrected git branch detection for both 'main' and 'master' branches
- Fixed race conditions in backup creation with process ID naming
- Resolved network connectivity issues in restricted environments
- Fixed git operation error handling and repository consistency

### Added
- Comprehensive error trapping with automatic recovery in updater
- Enhanced logging system with rotation and structured timestamps
- Multiple network connectivity testing methods
- Automatic backup cleanup maintaining 3 most recent backups
- Better shell detection with symlink analysis
- Comprehensive test suite for updater validation

### Changed
- Improved backup strategy with unique timestamp and PID naming
- Enhanced git operations with proper stashing and recovery
- Better shell configuration detection and management
- Refactored network connectivity checks for reliability
- Updated logging format with structured error levels

### Security
- Added safer file operations with atomic symlink creation
- Improved backup verification before destructive operations
- Better privilege escalation handling with multiple method support

## [2.2.8] - 2025-01-05

### Added
- Enhanced setup script with better distribution detection
- Improved error handling in installation process
- Better terminal configuration for KDE environments
- Support for additional Linux distributions

### Changed
- Updated font installation with newer Nerd Font versions
- Improved dependency management across distributions
- Enhanced terminal profile management

### Fixed
- Terminal profile configuration issues in KDE setups
- Package installation errors on Ubuntu-based systems
- Font rendering problems in some terminal emulators

## [2.2.7] - 2024-12-20

### Added
- Docker cleanup aliases for container management
- Auto-detection of Linux distributions
- Fastfetch configuration with customized system information layout
- SSH connection aliases for remote server management
- Enhanced archive extraction with better format support

### Changed
- Improved TTY detection for console-only sessions
- Enhanced Starship prompt with better git integration
- Updated installation script with more descriptive error messages
- Refined cleanup script with better backup preservation

### Fixed
- Package installation compatibility for Arch Linux systems
- Symlink handling in non-standard directory structures
- Fish shell compatibility with certain utility functions
- Path resolution issues in updater script

## [2.2.6] - 2024-12-10

### Added
- Support for additional package managers (yay/paru for Arch)
- Extended Git aliases and workflow shortcuts
- Fish shell configuration files and comprehensive help documentation
- Development environment support for Python and Node.js projects
- Enhanced file search and text manipulation tools

### Changed
- Updated font installation to use Nerd Fonts v3.3.0
- Improved Zoxide integration across all supported shells
- Better terminal detection and configuration management
- Enhanced command completion and suggestion systems

### Fixed
- Reset scripts for accurate profile restoration to system defaults
- Starship prompt rendering issues in various terminal emulators
- Command history preservation during shell configuration resets
- Cross-shell compatibility for core navigation functions

## [2.2.0] - 2024-11-25

### Added
- **Multi-Shell Support**: Complete Fish shell support with equivalent functionality
- **Interactive Help**: Comprehensive help documentation system for each shell
- **Reset Utilities**: Individual reset scripts for Bash, Zsh, and Fish configurations
- **Auto-Updater**: Repository synchronization script with version management
- **Development Workflows**: Extended aliases for modern development practices

### Changed
- **Modular Architecture**: Refactored configuration structure for maintainability
- **KDE Integration**: Improved terminal integration with custom Konsole profiles
- **Setup Process**: Enhanced installation script with interactive shell selection
- **Documentation**: Comprehensive help files for each supported shell

### Fixed
- Font rendering issues with shell prompts and special characters
- Cross-shell compatibility for core utility functions
- Multi-user environment path handling and permissions

## [2.1.0] - 2024-11-15

### Added
- **Zsh Support**: Full Zsh shell configuration with Oh-My-Zsh integration
- **Smart Navigation**: Zoxide integration for intelligent directory jumping
- **Fuzzy Finding**: FZF integration for file and history searching
- **Visual Enhancement**: Starship prompt with rich information display
- **System Information**: Extended commands for system monitoring and diagnostics

### Changed
- **Configuration Structure**: Reorganized Bash configuration for modularity
- **Alias Organization**: Categorized aliases by functionality and use case
- **Installation Process**: Enhanced setup with automatic dependency detection
- **Terminal Integration**: Better support for various terminal emulators

### Fixed
- Permission issues during initial installation and updates
- Command execution problems in restrictive shell environments
- Package installation compatibility across Debian derivatives

## [2.0.0] - 2024-11-01

### Added
- **Complete Rewrite**: Modular configuration system from ground up
- **Multi-Shell Architecture**: Foundation for supporting multiple shells
- **System Information**: Fastfetch integration for boot-time system display
- **Utility Library**: Comprehensive set of productivity functions
- **Archive Management**: Intelligent archive extraction and creation tools
- **Network Diagnostics**: Advanced network troubleshooting commands

### Changed
- **File Structure**: Migrated from monolithic script to modular files
- **Installation Workflow**: Improved setup with comprehensive error handling
- **Documentation**: Enhanced with usage examples and troubleshooting guides
- **Terminal Compatibility**: Better support across different terminal emulators

### Fixed
- Special character handling in shell prompts
- Terminal color compatibility across different systems
- Command execution reliability in various environments

### Breaking Changes
- Configuration file locations changed
- Some aliases renamed for consistency
- Installation process requires re-running setup

## [1.9.0] - 2024-10-20

### Added
- Git workflow optimization with additional aliases
- Enhanced file permission management
- System monitoring and performance tools
- Network connectivity diagnostics

### Changed
- Improved alias organization and naming consistency
- Better error messages and user feedback
- Enhanced bash completion support

### Fixed
- Path resolution issues in complex directory structures
- Command history handling improvements
- Terminal session management fixes

## [1.8.0] - 2024-10-10

### Added
- Advanced text search and file manipulation tools
- System backup and restoration utilities
- Enhanced directory navigation shortcuts
- Improved development environment support

### Changed
- Optimized shell startup performance
- Better handling of large command histories
- Improved cross-platform compatibility

### Fixed
- Memory usage optimization for large file operations
- Command substitution reliability improvements
- Terminal color scheme consistency

## [1.0.0] - 2024-10-01

### Added
- **Initial Release**: Core DXSBash functionality
- **Enhanced Bash Configuration**: Rich prompt with system information
- **Navigation Shortcuts**: Essential directory and file management commands
- **System Management**: Package management and system control aliases
- **Productivity Tools**: Core utility functions for daily workflows
- **Debian Integration**: Optimized for Debian package management
- **Basic Installation**: Simple setup script for initial deployment

### Features
- Custom Bash prompt with git integration
- 100+ useful aliases and functions
- Directory navigation enhancements
- File operation shortcuts
- System information display
- Package management integration
- Basic help system

### Known Issues
- Limited cross-distribution compatibility
- No support for alternative shells
- Manual font installation required
- No automated update mechanism
- Basic error handling

---

## Development Roadmap

### Planned Features
- **Enhanced IDE Integration**: VSCode and Vim/Neovim configuration profiles
- **Container Development**: Improved Docker and Kubernetes workflows
- **Cloud Integration**: AWS, GCP, and Azure CLI enhancements
- **Performance Monitoring**: Advanced system profiling tools
- **Automation Scripts**: Common administrative task automation

### Compatibility Goals
- **Distribution Support**: Expand to Fedora, CentOS, and openSUSE
- **Shell Support**: Possible PowerShell Core integration
- **Terminal Support**: Enhanced profiles for Alacritty, WezTerm
- **Platform Support**: macOS compatibility layer

### Long-term Vision
- Plugin system for extensible functionality
- GUI configuration tool
- Community contribution framework
- Professional development profiles
- Enterprise deployment tools

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- How to report bugs and request features
- Development setup and testing procedures
- Code style guidelines and standards
- Pull request process and review criteria

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **GitHub Issues**: [Report bugs and request features](https://github.com/digitalxs/dxsbash/issues)
- **Email**: luis@digitalxs.ca
- **Website**: [https://digitalxs.ca](https://digitalxs.ca)
- **Funding**: [Buy Me A Coffee](https://www.buymeacoffee.com/digitalxs)
