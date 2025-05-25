"""Utility functions for DXSBash Configuration TUI."""

import os
import shutil
import subprocess
from pathlib import Path
from typing import Optional, List, Tuple, Dict


def check_command_exists(command: str) -> bool:
    """Check if a command exists in the system."""
    return shutil.which(command) is not None


def get_shell_path(shell_name: str) -> Optional[str]:
    """Get the full path to a shell executable."""
    return shutil.which(shell_name)


def run_command(command: List[str], capture_output: bool = True, timeout: int = 30) -> Tuple[bool, str]:
    """Run a shell command and return success status and output."""
    try:
        result = subprocess.run(
            command,
            capture_output=capture_output,
            text=True,
            timeout=timeout,
            check=False
        )
        return result.returncode == 0, result.stdout or result.stderr
    except subprocess.TimeoutExpired:
        return False, f"Command timed out after {timeout} seconds"
    except Exception as e:
        return False, str(e)


def validate_dxsbash_installation(dxsbash_path: str) -> Dict[str, bool]:
    """Validate DXSBash installation and return detailed results."""
    path = Path(os.path.expanduser(dxsbash_path))
    
    validation_results = {
        "directory_exists": path.exists() and path.is_dir(),
        "bashrc_exists": (path / ".bashrc").exists(),
        "zshrc_exists": (path / ".zshrc").exists(), 
        "fish_config_exists": (path / "config.fish").exists(),
        "starship_config_exists": (path / "starship.toml").exists(),
        "setup_script_exists": (path / "setup.sh").exists(),
        "updater_script_exists": (path / "updater.sh").exists(),
    }
    
    return validation_results


def get_current_shell_from_env() -> str:
    """Get current shell from environment variables."""
    shell = os.environ.get('SHELL', '/bin/bash')
    return Path(shell).name


def detect_installed_shells() -> List[str]:
    """Detect which shells are installed on the system."""
    shells = []
    common_shells = ['bash', 'zsh', 'fish', 'dash', 'ksh']
    
    for shell in common_shells:
        if check_command_exists(shell):
            shells.append(shell)
    
    return shells


def create_symlink(source: Path, target: Path, backup: bool = True) -> bool:
    """Create a symbolic link safely with optional backup."""
    try:
        # Create backup if requested
        if backup and target.exists() and not target.is_symlink():
            backup_path = target.with_suffix(f"{target.suffix}.backup")
            shutil.copy2(target, backup_path)
        
        # Remove existing file/link
        if target.exists() or target.is_symlink():
            target.unlink()
        
        # Create parent directories if needed
        target.parent.mkdir(parents=True, exist_ok=True)
        
        # Create symlink
        target.symlink_to(source)
        return True
    except Exception:
        return False


def backup_file(file_path: Path, backup_dir: Path) -> Optional[Path]:
    """Create a backup of a file and return backup path."""
    try:
        if not file_path.exists():
            return None
        
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate unique backup name with timestamp
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{file_path.name}.{timestamp}.backup"
        backup_path = backup_dir / backup_name
        
        shutil.copy2(file_path, backup_path)
        return backup_path
    except Exception:
        return None


def get_system_info() -> Dict[str, str]:
    """Get basic system information."""
    info = {}
    
    # OS information
    try:
        with open('/etc/os-release', 'r') as f:
            for line in f:
                if line.startswith('PRETTY_NAME='):
                    info['os'] = line.split('=', 1)[1].strip().strip('"')
                    break
    except:
        info['os'] = 'Unknown'
    
    # Shell information
    info['current_shell'] = get_current_shell_from_env()
    info['available_shells'] = ', '.join(detect_installed_shells())
    
    # Terminal information
    info['terminal'] = os.environ.get('TERM', 'Unknown')
    info['terminal_program'] = os.environ.get('TERM_PROGRAM', 'Unknown')
    
    return info


def check_network_connectivity() -> bool:
    """Check if network connectivity is available."""
    import socket
    try:
        # Try to connect to Google's DNS
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        return True
    except:
        return False


def get_dxsbash_version(dxsbash_path: Path) -> Optional[str]:
    """Get DXSBash version from version.txt file."""
    try:
        version_file = dxsbash_path / "version.txt"
        if version_file.exists():
            return version_file.read_text().strip()
    except:
        pass
    return None


def format_file_size(size_bytes: int) -> str:
    """Format file size in human readable format."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"


def get_directory_size(path: Path) -> int:
    """Get total size of directory in bytes."""
    total = 0
    try:
        for item in path.rglob('*'):
            if item.is_file():
                total += item.stat().st_size
    except:
        pass
    return total