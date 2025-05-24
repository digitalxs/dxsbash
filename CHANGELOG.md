# Changelog

All notable changes to the DXSBash project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.8] - 2025-05-24

### Fixed
- **CRITICAL**: Fixed version comparison logic in updater script that was causing inverted comparison results
- **CRITICAL**: Corrected git branch detection to support both 'main' and 'master' branches dynamically
- Fixed race conditions in backup creation by adding process ID to backup directory names
- Resolved network connectivity check failures in environments where ping is blocked but HTTPS works
- Fixed error handling in git operations that could leave repository in inconsistent state

### Added
- Comprehensive error trapping with automatic recovery mechanisms in updater script
- Enhanced logging system with log rotation and structured timestamps
- Multiple fallback methods for network connectivity testing (curl → wget → ping)
- Automatic backup cleanup that maintains only the 3 most recent backups
- Enhanced shell detection logic with symlink analysis for better accuracy
- Improved privilege escalation detection supporting sudo, doas, and su
- Better error messages and user feedback throughout update process
- Comprehensive test suite for updater script validation

### Changed
- Improved backup strategy with unique naming using timestamps and process IDs
- Enhanced git operations with proper stashing and recovery of local changes
- Better shell configuration detection and management
- Refactored network connectivity checks for improved reliability
- Updated logging format with structured levels (INFO, WARN, ERROR)
- Improved user prompts and confirmation dialogs
- Enhanced system script updates with better error handling

### Security
- Added safer file operations with atomic symlink creation
- Improved backup verification before performing destructive operations
- Better handling of privilege escalation with multiple method support

## [2.2.7] - 2025-04-15

### Added
- Enhanced setup script with better distribution detection
- Improved error handling in installation process
- Better terminal configuration for KDE environments

### Changed
- Updated font installation process with newer Nerd Font versions
- Improved dependency management across different distributions

### Fixed
- Terminal profile configuration issues in some KDE setups
- Package installation errors on Ubuntu-based systems

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

---

## Notes on Version 2.2.8 Critical Fixes

This release addresses several critical bugs that were discovered in the updater script through comprehensive testing:

### Version Comparison Bug
The most serious issue was in the `version_gt()` function, which had inverted logic that would incorrectly determine whether updates were needed. This could lead to:
- Updates being skipped when they should be applied
- Unnecessary update attempts
- Inconsistent update behavior

### Git Operations Reliability
The previous git operations could fail in several scenarios:
- Repositories using 'master' instead of 'main' branch
- Local modifications not being properly handled
- Network failures during git operations
- Incomplete rollback on update failures

### Backup System Improvements
The backup system now prevents conflicts and maintains better hygiene:
- Unique backup names prevent overwrites
- Automatic cleanup prevents disk space issues
- Better verification before destructive operations

### Testing and Validation
This release includes a comprehensive test suite that validates:
- Version comparison logic with multiple edge cases
- Error handling and recovery mechanisms
- Network connectivity fallbacks
- File operation safety
- Logging functionality

Users are strongly encouraged to update to this version to ensure reliable operation of the DXSBash update system.
