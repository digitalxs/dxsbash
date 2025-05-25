"""Configuration data models for DXSBash TUI - Fixed version."""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
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
    
    def to_dict(self) -> Dict[str, Any]:
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
    def from_dict(cls, data: Dict[str, Any]) -> "DXSBashConfig":
        """Create configuration from dictionary."""
        config = cls()
        
        # Handle shell type
        if "active_shell" in data:
            try:
                config.active_shell = ShellType(data["active_shell"])
            except ValueError:
                # Invalid shell type, keep default
                pass
        
        # Handle features
        if "features" in data and isinstance(data["features"], dict):
            config.features = {}
            for k, v in data["features"].items():
                try:
                    config.features[k] = FeatureStatus(v)
                except ValueError:
                    # Invalid feature status, use default
                    config.features[k] = FeatureStatus.DISABLED
        
        # Handle other attributes with type checking
        string_attrs = ["starship_theme", "terminal_font", "color_scheme", 
                       "dxsbash_path", "config_path"]
        for attr in string_attrs:
            if attr in data and isinstance(data[attr], str):
                setattr(config, attr, data[attr])
        
        # Handle boolean attributes
        bool_attrs = ["fastfetch_enabled", "auto_backup"]
        for attr in bool_attrs:
            if attr in data and isinstance(data[attr], bool):
                setattr(config, attr, data[attr])
        
        # Handle integer attributes
        if "backup_count" in data and isinstance(data["backup_count"], int):
            config.backup_count = data["backup_count"]
        
        # Handle custom aliases
        if "custom_aliases" in data and isinstance(data["custom_aliases"], list):
            config.custom_aliases = data["custom_aliases"]
        
        return config
    
    def validate(self) -> List[str]:
        """Validate configuration and return list of issues."""
        issues = []
        
        # Validate paths
        dxsbash_path = Path(self.dxsbash_path)
        if not dxsbash_path.exists():
            issues.append(f"DXSBash path does not exist: {self.dxsbash_path}")
        elif not dxsbash_path.is_dir():
            issues.append(f"DXSBash path is not a directory: {self.dxsbash_path}")
        
        config_path = Path(self.config_path)
        if config_path.exists() and not config_path.is_dir():
            issues.append(f"Config path exists but is not a directory: {self.config_path}")
        
        # Validate backup count
        if self.backup_count < 1:
            issues.append("Backup count must be at least 1")
        elif self.backup_count > 50:
            issues.append("Backup count should not exceed 50")
        
        # Validate custom aliases format
        for i, alias in enumerate(self.custom_aliases):
            if not isinstance(alias, dict):
                issues.append(f"Custom alias {i} is not a dictionary")
                continue
            if "name" not in alias or "command" not in alias:
                issues.append(f"Custom alias {i} missing 'name' or 'command'")
            elif not isinstance(alias["name"], str) or not isinstance(alias["command"], str):
                issues.append(f"Custom alias {i} name and command must be strings")
        
        return issues
    
    def get_shell_executable_path(self) -> Optional[str]:
        """Get the path to the shell executable."""
        import shutil
        
        shell_map = {
            ShellType.BASH: "bash",
            ShellType.ZSH: "zsh", 
            ShellType.FISH: "fish"
        }
        
        shell_name = shell_map.get(self.active_shell)
        if shell_name:
            return shutil.which(shell_name)
        return None
    
    def is_shell_available(self) -> bool:
        """Check if the configured shell is available on the system."""
        return self.get_shell_executable_path() is not None
    
    def get_enabled_features(self) -> List[str]:
        """Get list of enabled features."""
        return [
            feature for feature, status in self.features.items()
            if status == FeatureStatus.ENABLED
        ]
    
    def get_unavailable_features(self) -> List[str]:
        """Get list of unavailable features."""
        return [
            feature for feature, status in self.features.items()
            if status == FeatureStatus.UNAVAILABLE
        ]
