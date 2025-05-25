"""Configuration management for DXSBash TUI - Integrated with existing files."""

import os
import yaml
import shutil
from pathlib import Path
from typing import Optional, Dict, List
from datetime import datetime

from .models import DXSBashConfig, ShellType, FeatureStatus


class ConfigManager:
    """Manages DXSBash configuration with integration to existing files."""
    
    def __init__(self, dxsbash_root: Optional[str] = None):
        """Initialize configuration manager."""
        self.dxsbash_root = Path(dxsbash_root or Path.home() / "linuxtoolbox" / "dxsbash")
        self.config_dir = Path.home() / ".config" / "dxsbash"
        self.config_file = self.config_dir / "tui-config.yaml"
        self.backup_dir = self.config_dir / "backups"
        
        # Ensure directories exist
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        self._config: Optional[DXSBashConfig] = None
    
    def load_config(self) -> DXSBashConfig:
        """Load configuration from file or detect from existing DXSBash setup."""
        if self._config is not None:
            return self._config
        
        # Try to load TUI config first
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    data = yaml.safe_load(f)
                self._config = DXSBashConfig.from_dict(data or {})
            except Exception:
                # If config is corrupted, detect from existing setup
                self._config = self._detect_existing_config()
        else:
            # No TUI config exists, detect from existing DXSBash setup
            self._config = self._detect_existing_config()
            self.save_config()  # Save detected config
        
        return self._config
    
    def _detect_existing_config(self) -> DXSBashConfig:
        """Detect configuration from existing DXSBash installation."""
        config = DXSBashConfig()
        
        # Detect active shell
        config.active_shell = self._detect_current_shell()
        
        # Detect available features
        config.features.update(self._detect_available_features())
        
        # Set correct paths
        config.dxsbash_path = str(self.dxsbash_root)
        
        return config
    
    def _detect_current_shell(self) -> ShellType:
        """Detect currently active DXSBash shell from symlinks."""
        home = Path.home()
        
        # Check for symlinks to determine active shell
        bashrc = home / ".bashrc"
        zshrc = home / ".zshrc"
        fish_config = home / ".config/fish/config.fish"
        
        if fish_config.is_symlink():
            try:
                target = fish_config.readlink()
                if "dxsbash" in str(target) or str(self.dxsbash_root) in str(target):
                    return ShellType.FISH
            except:
                pass
        
        if zshrc.is_symlink():
            try:
                target = zshrc.readlink()
                if "dxsbash" in str(target) or str(self.dxsbash_root) in str(target):
                    return ShellType.ZSH
            except:
                pass
        
        if bashrc.is_symlink():
            try:
                target = bashrc.readlink()
                if "dxsbash" in str(target) or str(self.dxsbash_root) in str(target):
                    return ShellType.BASH
            except:
                pass
        
        # Fallback to environment variable
        shell = os.environ.get('SHELL', '/bin/bash')
        if 'zsh' in shell:
            return ShellType.ZSH
        elif 'fish' in shell:
            return ShellType.FISH
        else:
            return ShellType.BASH
    
    def _detect_available_features(self) -> Dict[str, FeatureStatus]:
        """Detect which features are available based on installed tools."""
        features = {}
        
        # Tool detection map
        tools = {
            "docker": ["docker"],
            "kubernetes": ["kubectl"],
            "python": ["python3", "pip3"],
            "nodejs": ["node", "npm"],
            "git_extended": ["git"],
            "network_tools": ["netstat", "ss", "curl"],
            "system_monitoring": ["ps", "top", "htop"],
            "archive_tools": ["tar", "unzip"],
            "development_tools": ["vim", "nano", "code"],
        }
        
        for feature, commands in tools.items():
            # Check if at least one command is available
            available = any(shutil.which(cmd) for cmd in commands)
            features[feature] = FeatureStatus.ENABLED if available else FeatureStatus.UNAVAILABLE
        
        return features
    
    def save_config(self, config: Optional[DXSBashConfig] = None) -> bool:
        """Save TUI configuration to file."""
        if config is not None:
            self._config = config
        
        if self._config is None:
            return False
        
        try:
            # Create backup before saving
            if self.config_file.exists():
                self._create_backup()
            
            with open(self.config_file, 'w') as f:
                yaml.dump(self._config.to_dict(), f, default_flow_style=False, indent=2)
            
            return True
        except Exception:
            return False
    
    def apply_configuration(self, config: DXSBashConfig) -> bool:
        """Apply configuration changes to actual DXSBash files."""
        try:
            # Create backup of current configuration
            self._backup_current_shell_config()
            
            # Switch shell if needed
            if not self._switch_shell(config.active_shell):
                return False
            
            # Update starship configuration
            if not self._update_starship_config(config.starship_theme):
                return False
            
            # Update fastfetch configuration
            if not self._update_fastfetch_config(config.fastfetch_enabled):
                return False
            
            # Save TUI config
            return self.save_config(config)
            
        except Exception:
            return False
    
    def _switch_shell(self, shell: ShellType) -> bool:
        """Switch to the specified shell by updating symlinks."""
        home = Path.home()
        
        try:
            if shell == ShellType.BASH:
                self._create_shell_symlink(self.dxsbash_root / ".bashrc", home / ".bashrc")
                if (self.dxsbash_root / ".bash_aliases").exists():
                    self._create_shell_symlink(self.dxsbash_root / ".bash_aliases", home / ".bash_aliases")
                if (self.dxsbash_root / ".bashrc_help").exists():
                    self._create_shell_symlink(self.dxsbash_root / ".bashrc_help", home / ".bashrc_help")
            
            elif shell == ShellType.ZSH:
                self._create_shell_symlink(self.dxsbash_root / ".zshrc", home / ".zshrc")
                if (self.dxsbash_root / ".zshrc_help").exists():
                    self._create_shell_symlink(self.dxsbash_root / ".zshrc_help", home / ".zshrc_help")
            
            elif shell == ShellType.FISH:
                fish_dir = home / ".config" / "fish"
                fish_dir.mkdir(parents=True, exist_ok=True)
                self._create_shell_symlink(self.dxsbash_root / "config.fish", fish_dir / "config.fish")
                if (self.dxsbash_root / "fish_help").exists():
                    self._create_shell_symlink(self.dxsbash_root / "fish_help", fish_dir / "fish_help")
            
            return True
        except Exception:
            return False
    
    def _create_shell_symlink(self, source: Path, target: Path) -> bool:
        """Create a symlink for shell configuration files."""
        try:
            # Remove existing file/link
            if target.exists() or target.is_symlink():
                target.unlink()
            
            # Create symlink
            target.symlink_to(source)
            return True
        except Exception:
            return False
    
    def _update_starship_config(self, theme: str) -> bool:
        """Update Starship configuration."""
        try:
            starship_config = Path.home() / ".config" / "starship.toml"
            dxsbash_starship = self.dxsbash_root / "starship.toml"
            
            if dxsbash_starship.exists():
                # Create symlink to DXSBash starship config
                if startship_config.exists() or starship_config.is_symlink():
                    starship_config.unlink()
                starship_config.symlink_to(dxsbash_starship)
            
            return True
        except Exception:
            return False
    
    def _update_fastfetch_config(self, enabled: bool) -> bool:
        """Update Fastfetch configuration."""
        try:
            fastfetch_dir = Path.home() / ".config" / "fastfetch"
            fastfetch_config = fastfetch_dir / "config.jsonc"
            dxsbash_fastfetch = self.dxsbash_root / "config.jsonc"
            
            if enabled and dxsbash_fastfetch.exists():
                fastfetch_dir.mkdir(parents=True, exist_ok=True)
                if fastfetch_config.exists() or fastfetch_config.is_symlink():
                    fastfetch_config.unlink()
                fastfetch_config.symlink_to(dxsbash_fastfetch)
            elif not enabled and fastfetch_config.is_symlink():
                fastfetch_config.unlink()
            
            return True
        except Exception:
            return False
    
    def _backup_current_shell_config(self):
        """Backup current shell configuration before changes."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_subdir = self.backup_dir / f"shell_config_{timestamp}"
        backup_subdir.mkdir(exist_ok=True)
        
        home = Path.home()
        files_to_backup = [
            home / ".bashrc",
            home / ".zshrc", 
            home / ".config" / "fish" / "config.fish",
            home / ".config" / "starship.toml",
            home / ".config" / "fastfetch" / "config.jsonc",
        ]
        
        for file_path in files_to_backup:
            if file_path.exists():
                try:
                    shutil.copy2(file_path, backup_subdir / file_path.name)
                except Exception:
                    pass  # Continue with other files
    
    def _create_backup(self):
        """Create backup of TUI configuration."""
        if not self.config_file.exists():
            return
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = self.backup_dir / f"tui_config_{timestamp}.yaml"
        
        shutil.copy2(self.config_file, backup_file)
        
        # Clean old backups (keep only last 5)
        backups = sorted(self.backup_dir.glob("tui_config_*.yaml"))
        if len(backups) > 5:
            for old_backup in backups[:-5]:
                old_backup.unlink()
    
    def get_config(self) -> DXSBashConfig:
        """Get current configuration."""
        return self.load_config()
    
    def validate_dxsbash_installation(self) -> bool:
        """Validate that DXSBash is properly installed."""
        essential_files = [".bashrc", ".zshrc", "config.fish", "starship.toml"]
        
        return all((self.dxsbash_root / file).exists() for file in essential_files)