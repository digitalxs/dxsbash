#!/usr/bin/env python3
"""Main entry point for DXSBash Configuration TUI."""

import sys
import argparse
from pathlib import Path

# Add current directory to path for imports
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

# Fix imports to work with the current structure
from ui.app import DXSBashConfigApp
from config.manager import ConfigManager


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
        """
    )
    
    parser.add_argument(
        "--dxsbash-root",
        help="DXSBash repository root directory",
        default=None,
        type=str
    )
    
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug mode"
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="DXSBash Configuration TUI v0.1.0"
    )
    
    args = parser.parse_args()
    
    # Validate DXSBash installation if path provided
    if args.dxsbash_root:
        dxsbash_path = Path(args.dxsbash_root).expanduser()
        if not dxsbash_path.exists():
            print(f"❌ Error: DXSBash directory not found: {dxsbash_path}")
            sys.exit(1)
        
        # Quick validation
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
                sys.exit(1)
    
    # Create and run the app
    try:
        app = DXSBashConfigApp(dxsbash_root=args.dxsbash_root)
        
        if args.debug:
            app.run(debug=True)
        else:
            app.run()
    
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Error: {e}")
        if args.debug:
            raise
        sys.exit(1)


if __name__ == "__main__":
    main()