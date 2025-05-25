#!/usr/bin/env python3
"""Main entry point for DXSBash Configuration TUI - Fixed version."""

import sys
import argparse
from pathlib import Path

# Add current directory to path for imports
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

try:
    from ui.app import DXSBashConfigApp
    from config.manager import ConfigManager
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure you're running from the correct directory and all dependencies are installed.")
    sys.exit(1)


def validate_dxsbash_path(path_str: str) -> Path:
    """Validate and return DXSBash path."""
    dxsbash_path = Path(path_str).expanduser().absolute()
    
    if not dxsbash_path.exists():
        raise FileNotFoundError(f"DXSBash directory not found: {dxsbash_path}")
    
    if not dxsbash_path.is_dir():
        raise NotADirectoryError(f"Path is not a directory: {dxsbash_path}")
    
    # Check for essential files
    essential_files = [".bashrc", ".zshrc", "config.fish"]
    missing_files = []
    
    for file in essential_files:
        if not (dxsbash_path / file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(f"⚠️ Warning: Missing essential files in {dxsbash_path}:")
        for file in missing_files:
            print(f"  • {file}")
        
        response = input("Continue anyway? (y/N): ")
        if response.lower() != 'y':
            raise ValueError("Essential files missing, aborting")
    
    return dxsbash_path


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="DXSBash Configuration TUI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Run with auto-detected DXSBash path
  %(prog)s --dxsbash-root ~/my-dxs  # Use custom DXSBash directory
  %(prog)s --debug                  # Enable debug mode

Features:
  • Configure shell preferences (Bash, Zsh, Fish)
  • Enable/disable feature modules
  • Customize appearance settings
  • Apply changes directly to DXSBash files
  • Create configuration backups

Keyboard Shortcuts:
  Ctrl+S  - Save configuration
  Ctrl+A  - Apply changes
  Ctrl+R  - Reset to defaults
  F1      - Show help
  F5      - Refresh
  Q       - Quit
        """
    )
    
    parser.add_argument(
        "--dxsbash-root",
        help="DXSBash repository root directory (default: ~/linuxtoolbox/dxsbash)",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug mode with detailed error output"
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="DXSBash Configuration TUI v0.1.0"
    )
    
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Only validate DXSBash installation, don't run TUI"
    )
    
    args = parser.parse_args()
    
    # Determine DXSBash path
    dxsbash_path = None
    if args.dxsbash_root:
        try:
            dxsbash_path = validate_dxsbash_path(args.dxsbash_root)
            print(f"✅ Using DXSBash directory: {dxsbash_path}")
        except (FileNotFoundError, NotADirectoryError, ValueError) as e:
            print(f"❌ Error: {e}")
            sys.exit(1)
    else:
        # Auto-detect DXSBash path
        default_path = Path.home() / "linuxtoolbox" / "dxsbash"
        if default_path.exists():
            try:
                dxsbash_path = validate_dxsbash_path(str(default_path))
                print(f"✅ Auto-detected DXSBash directory: {dxsbash_path}")
            except (FileNotFoundError, NotADirectoryError, ValueError) as e:
                print(f"⚠️ Warning: {e}")
                dxsbash_path = default_path  # Use anyway for TUI to handle
        else:
            print(f"⚠️ Warning: Default DXSBash directory not found: {default_path}")
            print("You can specify a custom path with --dxsbash-root")
    
    # Validation-only mode
    if args.validate_only:
        try:
            config_manager = ConfigManager(str(dxsbash_path) if dxsbash_path else None)
            if config_manager.validate_dxsbash_installation():
                print("✅ DXSBash installation is valid")
                sys.exit(0)
            else:
                print("❌ DXSBash installation validation failed")
                sys.exit(1)
        except Exception as e:
            print(f"❌ Validation error: {e}")
            if args.debug:
                raise
            sys.exit(1)
    
    # Check for required dependencies
    try:
        import textual
        import yaml
    except ImportError as e:
        print(f"❌ Missing required dependency: {e}")
        print("Please install requirements: pip install -r requirements.txt")
        sys.exit(1)
    
    # Create and run the app
    try:
        print("🚀 Starting DXSBash Configuration TUI...")
        app = DXSBashConfigApp(dxsbash_root=str(dxsbash_path) if dxsbash_path else None)
        
        if args.debug:
            print("🐛 Debug mode enabled")
            app.run(debug=True)
        else:
            app.run()
    
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Application error: {e}")
        if args.debug:
            import traceback
            traceback.print_exc()
        else:
            print("Use --debug flag for detailed error information")
        sys.exit(1)


if __name__ == "__main__":
    main()
