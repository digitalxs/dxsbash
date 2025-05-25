"""Configuration data models for DXSBash TUI."""

from dataclasses import dataclass, field
from typing import Dict, List, Optional
from enum import Enum
import os
from pathlib import Path


class ShellType(Enum):
    """Supported shell types."""
    BASH = "bash"
    ZSH = "zsh"
    FISH = "fish"


class FeatureStatus(Enum):
    """Feature enablement status."""
    ENABLED = "enabled"
    DISABLED = "disabled"
    UNAVAILABLE = "unavailable"


@dataclass
class DXSBashConfig:
    """Main configuration model for DXSBash."""
    
    # Shell configuration
    active_shell: ShellType = ShellType.BASH
    
    # Feature toggles - based on your existing aliases and functions
    features: Dict[str, FeatureStatus] = field(default_factory=lambda: {
        "docker": FeatureStatus.DISABLED,
        "kubernetes": FeatureStatus.DISABLED,
        "python": FeatureStatus.ENABLED,
        "nodejs": FeatureStatus.DISABLED,
        "git_extended": FeatureStatus.ENABLED,
        "network_tools": FeatureStatus.ENABLED,
        "system_monitoring": FeatureStatus.ENABLED,
        "archive_tools": FeatureStatus.ENABLED,
        "development_tools": FeatureStatus.ENABLED,
    })
    
    # Appearance settings
    starship_theme: str = "default"
    terminal_font: str = "FiraCode Nerd Font"
    color_scheme: str = "auto"
    fastfetch_enabled: bool = True
    
    # Custom aliases (from your .bash_aliases)
    custom_aliases: List[Dict[str, str]] = field(default_factory=list)
    
    # System paths - integrate with your existing structure
    dxsbash_path: str = field(default_factory=lambda: str(Path.home() / "linuxtoolbox" / "dxsbash"))
    config_path: str = field(default_factory=lambda: str(Path.home() / ".config" / "dxsbash"))
    
    # Backup settings
    auto_backup: bool = True
    backup_count: int = 5
    
    def get_repository_root(self) -> Path:
        """Get the DXSBash repository root directory."""
        return Path(self.dxsbash_path)
    
    def get_shell_config_path(self) -> Path:
        """Get the path to the active shell configuration file."""
        home = Path.home()
        if self.active_shell == ShellType.BASH:
            return home / ".bashrc"
        elif self.active_shell == ShellType.ZSH:
            return home / ".zshrc"
        elif self.active_shell == ShellType.FISH:
            return home / ".config" / "fish" / "config.fish"
        return home / ".bashrc"  # fallback
    
    def to_dict(self) -> Dict:
        """Convert configuration to dictionary."""
        return {
            "active_shell": self.active_shell.value,
            "features": {k: v.value for k, v in self.features.items()},
            "starship_theme": self.starship_theme,
            "terminal_font": self.terminal_font,
            "color_scheme": self.color_scheme,
            "fastfetch_enabled": self.fastfetch_enabled,
            "custom_aliases": self.custom_aliases,
            "dxsbash_path": self.dxsbash_path,
            "config_path": self.config_path,
            "auto_backup": self.auto_backup,
            "backup_count": self.backup_count,
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "DXSBashConfig":
        """Create configuration from dictionary."""
        config = cls()
        
        if "active_shell" in data:
            config.active_shell = ShellType(data["active_shell"])
        
        if "features" in data:
            config.features = {
                k: FeatureStatus(v) for k, v in data["features"].items()
            }
        
        # Set other attributes
        for attr in ["starship_theme", "terminal_font", "color_scheme", 
                    "fastfetch_enabled", "custom_aliases", "dxsbash_path", 
                    "config_path", "auto_backup", "backup_count"]:
            if attr in data:
                setattr(config, attr, data[attr])
        
        return config