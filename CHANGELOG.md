# Changelog

All notable changes to the DXSBash project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.6] - 2025-04-10

### Added
- Docker cleanup alias for removing unused containers, images, networks, and volumes
- Auto-detection of distribution for better cross-platform compatibility
- Fastfetch configuration with customized layout
- Additional SSH aliases for remote connections

### Changed
- Improved TTY detection for console-only sessions
- Enhanced starship prompt with better formatting
- Updated installation script with more helpful error messages
- Refined cleanup script with better backup handling

### Fixed
- Package installation for Arch Linux-based systems
- Symlink handling in non-standard environments
- Fish shell compatibility issues with certain functions
- Path issues in updater script

## [2.2.5] - 2025-03-22

### Added
- Support for additional package managers (yay/paru for Arch Linux)
- More Git aliases and shortcuts
- Fish shell configuration files and help documentation
- Expanded development environment support for Python, Node.js

### Changed
- Updated font installation to use newer Nerd Font version
- Improved Zoxide integration across all supported shells
- Better terminal detection and configuration

### Fixed
- Reset scripts for accurate profile restoration
- Starship prompt rendering issues in some terminals
- Command history preservation during shell resets

## [2.2.0] - 2025-02-18

### Added
- Complete Fish shell support with equivalent functionality
- Comprehensive help documentation for each shell
- Reset scripts for each supported shell
- Updater script with repository synchronization
- Extended aliases for modern development workflows

### Changed
- Refactored configuration structure for better maintainability
- Improved KDE terminal integration with custom profiles
- Enhanced setup script with interactive shell selection

### Fixed
- Font rendering issues with shell prompts
- Cross-shell compatibility for core functions
- Path handling for multi-user environments

## [2.1.0] - 2025-01-05

### Added
- Zsh shell support with Oh-My-Zsh integration
- Zoxide smart directory navigation
- FZF fuzzy finder integration
- Starship prompt customization
- Extended system information commands

### Changed
- Restructured bash configuration for better organization
- Improved alias organization and categorization
- Enhanced installation process with dependency checks

### Fixed
- Permission issues during installation
- Command execution in restrictive environments
- Package installation on various Debian derivatives

## [2.0.0] - 2024-12-10

### Added
- Complete rewrite with modular configuration
- Multi-shell support architecture
- Fastfetch system information display
- Comprehensive utility functions
- Extended archive management tools
- Network diagnostic commands

### Changed
- Migrated from single script to multiple configuration files
- Improved installation workflow with better error handling
- Enhanced documentation with usage examples

### Fixed
- Issues with special characters in prompts
- Terminal color compatibility problems
- Command execution in various environments

## [1.0.0] - 2024-10-15

### Added
- Initial release of DXSBash
- Basic Bash configuration with enhanced prompt
- Essential navigation commands and aliases
- System management shortcuts
- Core utility functions for productivity
- Debian package management aliases
- Simple installation script

### Known Issues
- Limited cross-distribution compatibility
- No support for alternative shells
- Manual font installation required
- No update mechanism
