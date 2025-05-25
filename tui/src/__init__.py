# src/__init__.py
"""DXSBash Configuration TUI Package."""

__version__ = "0.1.0"
__author__ = "Luis Miguel P. Freitas"
__email__ = "luis@digitalxs.ca"


# src/config/__init__.py (already exists but here's the content)
"""Configuration management package."""

from .models import DXSBashConfig, ShellType, FeatureStatus
from .manager import ConfigManager

__all__ = ["DXSBashConfig", "ShellType", "FeatureStatus", "ConfigManager"]


# src/ui/__init__.py (already exists but here's the content)
"""User interface package."""

from .app import DXSBashConfigApp

__all__ = ["DXSBashConfigApp"]


# src/utils/__init__.py (already exists but here's the content)
"""Utility functions package."""

from .helpers import (
    check_command_exists,
    get_shell_path,
    run_command,
    validate_dxsbash_installation,
    create_symlink,
    backup_file
)

__all__ = [
    "check_command_exists",
    "get_shell_path", 
    "run_command",
    "validate_dxsbash_installation",
    "create_symlink",
    "backup_file"
]