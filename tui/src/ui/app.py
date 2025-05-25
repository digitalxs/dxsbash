"""Main application class for DXSBash configuration TUI with comprehensive error handling."""

import asyncio
import traceback
from typing import Optional, Dict, Any
from pathlib import Path

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical, ScrollableContainer
from textual.widgets import (
    Header, Footer, Button, Static, RadioSet, RadioButton,
    Checkbox, Select, Input, TextArea, Tabs, Tab, Label,
    Rule, Switch, ProgressBar
)
from textual.binding import Binding
from textual.message import Message
from textual import events, work
from textual.worker import get_current_worker
from rich.text import Text

# Fix imports to work with current structure
from config.manager import ConfigManager
from config.models import ShellType, FeatureStatus
from utils.helpers import check_command_exists, run_command


class DXSBashConfigApp(App):
    """DXSBash Configuration TUI Application with comprehensive error handling."""
    
    CSS = """
    Screen {
        layout: vertical;
    }
    
    Header {
        dock: top;
        height: 3;
    }
    
    Footer {
        dock: bottom;
        height: 3;
    }
    
    .main-container {
        padding: 1;
        height: 1fr;
    }
    
    .config-section {
        border: solid $primary;
        margin: 1 0;
        padding: 1;
        height: auto;
    }
    
    .section-title {
        color: $accent;
        text-style: bold;
        margin-bottom: 1;
    }
    
    .shell-selection {
        height: 8;
    }
    
    .features-container {
        layout: grid;
        grid-size: 2;
        grid-gutter: 1 2;
        height: auto;
        min-height: 12;
    }
    
    .feature-item {
        height: 3;
        layout: horizontal;
        align: left middle;
    }
    
    .appearance-section {
        height: 12;
    }
    
    .actions-section {
        layout: horizontal;
        height: 5;
        align: center middle;
    }
    
    .progress-section {
        height: 4;
        margin: 1 0;
    }
    
    Button {
        margin: 0 1;
        min-width: 16;
    }
    
    .status-line {
        dock: bottom;
        height: 1;
        background: $surface;
        color: $text;
        padding: 0 1;
    }
    
    .success {
        color: $success;
    }
    
    .warning {
        color: $warning;
    }
    
    .error {
        color: $error;
    }
    
    .info {
        color: $info;
    }
    
    .working {
        color: $accent;
    }
    
    RadioSet {
        height: 5;
    }
    
    Select {
        margin: 1 0;
    }
    
    ProgressBar {
        margin: 1 0;
    }
    
    .hidden {
        display: none;
    }
    """
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("ctrl+s", "save", "Save"),
        Binding("ctrl+r", "reset", "Reset"),
        Binding("ctrl+a", "apply", "Apply"),
        Binding("f1", "help", "Help"),
        Binding("f5", "refresh", "Refresh"),
        Binding("escape", "cancel_operation", "Cancel"),
    ]
    
    def __init__(self, dxsbash_root: str = None):
        """Initialize the application with proper error handling."""
        super().__init__()
        self.dxsbash_root = dxsbash_root
        self.config_manager: Optional[ConfigManager] = None
        self.config = None
        self.unsaved_changes = False
        self.status_message = ""
        self.operation_in_progress = False
        self.current_worker = None
        
        # Initialize config manager with error handling
        try:
            self.config_manager = ConfigManager(dxsbash_root)
            self.config = self.config_manager.load_config()
        except Exception as e:
            self.config_manager = None
            self.config = None
            self.status_message = f"❌ Failed to initialize configuration: {str(e)}"
    
    def compose(self) -> ComposeResult:
        """Create the application layout with error handling."""
        try:
            yield Header()
            
            with ScrollableContainer(classes="main-container"):
                yield Static("🛠️  DXSBash Configuration Manager", classes="section-title")
                
                if self.config and self.config_manager:
                    yield Static(f"Repository: {self.config.dxsbash_path}", classes="info")
                else:
                    yield Static("❌ Configuration not loaded", classes="error")
                    
                yield Rule()
                
                # Progress bar for operations (initially hidden)
                with Container(classes="progress-section hidden", id="progress-container"):
                    yield Static("Operation in progress...", id="progress-text")
                    yield ProgressBar(id="progress-bar")
                
                # Only show config sections if we have valid config
                if self.config and self.config_manager:
                    yield from self._create_config_sections()
                else:
                    yield Static("❌ Unable to load configuration. Please check your DXSBash installation.", classes="error")
                    with Container(classes="actions-section"):
                        yield Button("🔄 Retry Initialization", id="retry-btn")
                        yield Button("❓ Help", id="help-btn")
            
            with Container(classes="status-line"):
                yield Static(self.status_message, id="status")
            
            yield Footer()
            
        except Exception as e:
            # Fallback UI if compose fails
            yield Header()
            yield Static(f"❌ Failed to create UI: {str(e)}", classes="error")
            yield Footer()
    
    def _create_config_sections(self) -> ComposeResult:
        """Create configuration sections with error handling."""
        try:
            # Shell Selection Section
            with Container(classes="config-section shell-selection"):
                yield Static("🐚 Shell Selection", classes="section-title")
                with RadioSet(id="shell-radio"):
                    yield RadioButton(
                        "Bash (Traditional shell, most compatible)", 
                        value=self.config.active_shell == ShellType.BASH
                    )
                    yield RadioButton(
                        "Zsh (Enhanced features, Oh-My-Zsh)", 
                        value=self.config.active_shell == ShellType.ZSH
                    )
                    yield RadioButton(
                        "Fish (Modern, user-friendly)", 
                        value=self.config.active_shell == ShellType.FISH
                    )
            
            # Features Section
            with Container(classes="config-section"):
                yield Static("🔧 Features & Tools", classes="section-title")
                with Container(classes="features-container"):
                    yield from self._create_feature_checkboxes()
            
            # Appearance Section
            with Container(classes="config-section appearance-section"):
                yield Static("🎨 Appearance", classes="section-title")
                yield from self._create_appearance_controls()
            
            # Action Buttons
            with Container(classes="config-section actions-section"):
                yield Button("💾 Save Configuration", variant="primary", id="save-btn")
                yield Button("✅ Apply Changes", variant="success", id="apply-btn") 
                yield Button("🔄 Reset to Defaults", variant="warning", id="reset-btn")
                yield Button("📋 Create Backup", id="backup-btn")
                yield Button("❓ Help", id="help-btn")
                
        except Exception as e:
            yield Static(f"❌ Error creating configuration sections: {str(e)}", classes="error")
    
    def _create_feature_checkboxes(self) -> ComposeResult:
        """Create feature checkboxes with proper error handling."""
        feature_descriptions = {
            "docker": "🐳 Docker Tools & Aliases",
            "kubernetes": "☸️  Kubernetes (kubectl) Support", 
            "python": "🐍 Python Development Tools",
            "nodejs": "📦 Node.js & NPM Tools",
            "git_extended": "🌿 Extended Git Workflows",
            "network_tools": "🌐 Network Diagnostics",
            "system_monitoring": "📊 System Monitoring",
            "archive_tools": "📦 Archive Management",
            "development_tools": "💻 Development Utilities",
        }
        
        try:
            for feature_key, description in feature_descriptions.items():
                feature_status = self.config.features.get(feature_key, FeatureStatus.DISABLED)
                enabled = feature_status == FeatureStatus.ENABLED
                available = feature_status != FeatureStatus.UNAVAILABLE
                
                with Container(classes="feature-item"):
                    if available:
                        yield Checkbox(
                            description, 
                            value=enabled, 
                            id=f"{feature_key}-check"
                        )
                    else:
                        yield Checkbox(
                            f"{description} (unavailable)", 
                            value=False, 
                            disabled=True,
                            id=f"{feature_key}-check"
                        )
        except Exception as e:
            yield Static(f"❌ Error creating feature controls: {str(e)}", classes="error")
    
    def _create_appearance_controls(self) -> ComposeResult:
        """Create appearance controls with error handling."""
        try:
            yield Label("Starship Theme:")
            yield Select(
                [
                    ("Default", "default"),
                    ("Dracula", "dracula"), 
                    ("Gruvbox", "gruvbox"),
                    ("Nord", "nord"),
                    ("Tokyo Night", "tokyo-night"),
                    ("Pure", "pure"),
                ],
                value=self.config.starship_theme,
                id="theme-select"
            )
            
            yield Label("Terminal Font:")
            yield Select(
                [
                    ("FiraCode Nerd Font", "FiraCode Nerd Font"),
                    ("JetBrains Mono Nerd Font", "JetBrains Mono Nerd Font"),
                    ("Hack Nerd Font", "Hack Nerd Font"),
                    ("Source Code Pro", "Source Code Pro"),
                    ("Cascadia Code", "Cascadia Code"),
                ],
                value=self.config.terminal_font,
                id="font-select"
            )
            
            with Horizontal():
                yield Label("Enable Fastfetch on startup:")
                yield Switch(value=self.config.fastfetch_enabled, id="fastfetch-switch")
                
        except Exception as e:
            yield Static(f"❌ Error creating appearance controls: {str(e)}", classes="error")
    
    def on_mount(self) -> None:
        """Handle application mount with error handling."""
        try:
            self.title = "DXSBash Configuration Manager"
            
            if self.config and self.config_manager:
                self.sub_title = f"Shell: {self.config.active_shell.value.title()} | Path: {self.config.dxsbash_path}"
                
                # Validate DXSBash installation
                if not self.config_manager.validate_dxsbash_installation():
                    self.update_status("⚠️  Warning: DXSBash installation not found or incomplete", "warning")
                else:
                    self.update_status("✅ DXSBash installation validated", "success")
            else:
                self.sub_title = "Configuration Error"
                self.update_status("❌ Failed to initialize configuration manager", "error")
                
        except Exception as e:
            self.update_status(f"❌ Initialization error: {str(e)}", "error")
    
    def update_status(self, message: str, severity: str = "info"):
        """Update status message with error handling."""
        try:
            self.status_message = message
            status_widget = self.query_one("#status", Static)
            status_widget.update(message)
            
            # Apply appropriate styling
            status_widget.remove_class("success", "warning", "error", "info", "working")  
            status_widget.add_class(severity)
            
        except Exception as e:
            # Fallback if status update fails
            self.status_message = f"Status update failed: {str(e)}"
    
    def action_save(self) -> None:
        """Save configuration to TUI config file with error handling."""
        try:
            if not self.config_manager or not self.config:
                self.update_status("❌ No configuration manager available", "error")
                return
                
            self.update_status("💾 Saving configuration...", "working")
            
            if self.config_manager.save_config(self.config):
                self.unsaved_changes = False
                self.update_status("💾 Configuration saved successfully!", "success")
            else:
                self.update_status("❌ Failed to save configuration!", "error")
                
        except Exception as e:
            self.update_status(f"❌ Save error: {str(e)}", "error")
    
    def action_apply(self) -> None:
        """Apply configuration changes - simplified version without async."""
        try:
            if not self.config_manager or not self.config:
                self.update_status("❌ No configuration manager available", "error")
                return
                
            self.update_status("🔄 Applying configuration changes...", "working")
            
            # Apply configuration
            if self.config_manager.apply_configuration(self.config):
                self.unsaved_changes = False
                self.update_status("✅ Configuration applied! Please restart your shell to see changes.", "success")
            else:
                self.update_status("❌ Failed to apply configuration changes!", "error")
                
        except Exception as e:
            self.update_status(f"❌ Apply error: {str(e)}", "error")
    
    def action_reset(self) -> None:
        """Reset to default configuration with error handling."""
        try:
            if not self.config_manager:
                self.update_status("❌ No configuration manager available", "error")
                return
                
            from config.models import DXSBashConfig
            
            self.config = DXSBashConfig()
            self.config.dxsbash_path = str(self.config_manager.dxsbash_root)
            
            # Refresh the UI
            self.refresh()
            self.unsaved_changes = True
            self.update_status("🔄 Configuration reset to defaults", "warning")
            
        except Exception as e:
            self.update_status(f"❌ Reset error: {str(e)}", "error")
    
    def action_backup(self) -> None:
        """Create configuration backup with error handling."""
        try:
            if not self.config_manager:
                self.update_status("❌ No configuration manager available", "error")
                return
                
            self.update_status("📋 Creating backup...", "working")
            self.config_manager._backup_current_shell_config()
            self.update_status("📋 Backup created successfully!", "success")
            
        except Exception as e:
            self.update_status(f"❌ Backup error: {str(e)}", "error")
    
    def action_help(self) -> None:
        """Show help information with error handling."""
        try:
            help_text = """
🛠️ DXSBash Configuration Manager Help

📝 KEYBOARD SHORTCUTS:
- Ctrl+S - Save configuration
- Ctrl+A - Apply changes  
- Ctrl+R - Reset to defaults
- F1 - Show this help
- F5 - Refresh interface
- Q - Quit application

🐚 SHELL SELECTION:
Choose your preferred shell. Each has different features:
- Bash - Most compatible, traditional
- Zsh - Enhanced with Oh-My-Zsh plugins
- Fish - Modern with better autocompletion

💾 SAVE vs APPLY:
- Save - Store settings in TUI config
- Apply - Actually modify DXSBash files

⚠️ IMPORTANT:
Always create backups before applying changes!
"""
            self.update_status("❓ Help information displayed in console", "info")
            print(help_text)
            
        except Exception as e:
            self.update_status(f"❌ Help error: {str(e)}", "error")
    
    def action_refresh(self) -> None:
        """Refresh configuration from files with error handling."""
        try:
            if not self.config_manager:
                self.update_status("❌ No configuration manager available", "error")
                return
                
            self.update_status("🔄 Refreshing configuration...", "working")
            self.config = self.config_manager.load_config()
            self.unsaved_changes = False
            self.refresh()
            self.update_status("🔄 Configuration refreshed from files", "success")
            
        except Exception as e:
            self.update_status(f"❌ Refresh error: {str(e)}", "error")
    
    def action_cancel_operation(self) -> None:
        """Cancel current operation if possible."""
        self.update_status("ℹ️ No operation to cancel", "info")
    
    def action_quit(self) -> None:
        """Quit the application with proper cleanup."""
        try:
            if self.unsaved_changes:
                self.update_status("⚠️ You have unsaved changes! Use Ctrl+S to save first.", "warning") 
                return
                
            self.exit()
            
        except Exception as e:
            print(f"Quit error: {str(e)}")
            self.exit(1)