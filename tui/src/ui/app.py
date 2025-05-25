"""Main application class for DXSBash configuration TUI - Fixed version."""

import sys
from typing import Optional, Dict, Any
from pathlib import Path

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical, ScrollableContainer
from textual.widgets import (
    Header, Footer, Button, Static, RadioSet, RadioButton,
    Checkbox, Select, Input, Switch, Label, Rule
)
from textual.binding import Binding
from textual.message import Message
from textual.screen import Screen

# Fixed imports with proper path handling
sys.path.insert(0, str(Path(__file__).parent.parent))

from config.manager import ConfigManager
from config.models import DXSBashConfig, ShellType, FeatureStatus


class DXSBashConfigApp(App):
    """DXSBash Configuration TUI Application - Fixed version."""
    
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
    """
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("ctrl+s", "save", "Save"),
        Binding("ctrl+r", "reset", "Reset"),
        Binding("ctrl+a", "apply", "Apply"),
        Binding("f1", "help", "Help"),
        Binding("f5", "refresh", "Refresh"),
    ]
    
    def __init__(self, dxsbash_root: str = None):
        """Initialize the application."""
        super().__init__()
        self.dxsbash_root = dxsbash_root
        self.config_manager: Optional[ConfigManager] = None
        self.config: Optional[DXSBashConfig] = None
        self.unsaved_changes = False
        self.status_message = ""
        
        # Initialize config manager
        self._initialize_config()
    
    def _initialize_config(self):
        """Initialize configuration manager with error handling."""
        try:
            self.config_manager = ConfigManager(self.dxsbash_root)
            self.config = self.config_manager.load_config()
            self.status_message = "✅ Configuration loaded successfully"
        except Exception as e:
            self.config_manager = None
            self.config = None
            self.status_message = f"❌ Failed to initialize configuration: {str(e)}"
    
    def compose(self) -> ComposeResult:
        """Create the application layout."""
        yield Header()
        
        if not self.config or not self.config_manager:
            with Container(classes="main-container"):
                yield Static("❌ DXSBash Configuration Manager", classes="section-title error")
                yield Static("Configuration could not be loaded. Please check your DXSBash installation.", classes="error")
                yield Rule()
                with Container(classes="actions-section"):
                    yield Button("🔄 Retry", id="retry-btn")
                    yield Button("❓ Help", id="help-btn")
                    yield Button("❌ Quit", id="quit-btn")
        else:
            with ScrollableContainer(classes="main-container"):
                yield Static("🛠️  DXSBash Configuration Manager", classes="section-title")
                yield Static(f"Repository: {self.config.dxsbash_path}", classes="info")
                yield Rule()
                
                # Shell Selection Section
                with Container(classes="config-section shell-selection"):
                    yield Static("🐚 Shell Selection", classes="section-title")
                    with RadioSet(id="shell-radio"):
                        yield RadioButton(
                            "Bash (Traditional shell, most compatible)", 
                            value=self.config.active_shell == ShellType.BASH,
                            id="bash-radio"
                        )
                        yield RadioButton(
                            "Zsh (Enhanced features, Oh-My-Zsh)", 
                            value=self.config.active_shell == ShellType.ZSH,
                            id="zsh-radio"
                        )
                        yield RadioButton(
                            "Fish (Modern, user-friendly)", 
                            value=self.config.active_shell == ShellType.FISH,
                            id="fish-radio"
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
                    yield Button("💾 Save", variant="primary", id="save-btn")
                    yield Button("✅ Apply", variant="success", id="apply-btn") 
                    yield Button("🔄 Reset", variant="warning", id="reset-btn")
                    yield Button("📋 Backup", id="backup-btn")
                    yield Button("❓ Help", id="help-btn")
        
        with Container(classes="status-line"):
            yield Static(self.status_message, id="status")
        
        yield Footer()
    
    def _create_feature_checkboxes(self) -> ComposeResult:
        """Create feature checkboxes."""
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
    
    def _create_appearance_controls(self) -> ComposeResult:
        """Create appearance controls."""
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
    
    def on_mount(self) -> None:
        """Handle application mount."""
        self.title = "DXSBash Configuration Manager"
        
        if self.config and self.config_manager:
            self.sub_title = f"Shell: {self.config.active_shell.value.title()} | Path: {self.config.dxsbash_path}"
            
            # Validate installation
            if not self.config_manager.validate_dxsbash_installation():
                self.update_status("⚠️  Warning: DXSBash installation incomplete", "warning")
            else:
                self.update_status("✅ DXSBash installation validated", "success")
        else:
            self.sub_title = "Configuration Error"
            self.update_status("❌ Failed to initialize configuration", "error")
    
    def update_status(self, message: str, severity: str = "info"):
        """Update status message."""
        self.status_message = message
        try:
            status_widget = self.query_one("#status", Static)
            status_widget.update(message)
            
            # Apply styling
            status_widget.remove_class("success", "warning", "error", "info", "working")  
            status_widget.add_class(severity)
        except Exception:
            pass  # Widget might not exist yet
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        button_id = event.button.id
        
        if button_id == "save-btn":
            self.action_save()
        elif button_id == "apply-btn":
            self.action_apply()
        elif button_id == "reset-btn":
            self.action_reset()
        elif button_id == "backup-btn":
            self.action_backup()
        elif button_id == "help-btn":
            self.action_help()
        elif button_id == "retry-btn":
            self._initialize_config()
            self.refresh()
        elif button_id == "quit-btn":
            self.action_quit()
    
    def on_radio_set_changed(self, event: RadioSet.Changed) -> None:
        """Handle shell selection changes."""
        if event.radio_set.id == "shell-radio" and self.config:
            if event.pressed.id == "bash-radio":
                self.config.active_shell = ShellType.BASH
            elif event.pressed.id == "zsh-radio":
                self.config.active_shell = ShellType.ZSH
            elif event.pressed.id == "fish-radio":
                self.config.active_shell = ShellType.FISH
            
            self.unsaved_changes = True
            self.update_status(f"🐚 Shell changed to {self.config.active_shell.value}", "info")
    
    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        """Handle feature checkbox changes."""
        if self.config and event.checkbox.id and event.checkbox.id.endswith("-check"):
            feature_key = event.checkbox.id.replace("-check", "")
            if feature_key in self.config.features:
                new_status = FeatureStatus.ENABLED if event.value else FeatureStatus.DISABLED
                self.config.features[feature_key] = new_status
                self.unsaved_changes = True
                status = "enabled" if event.value else "disabled"
                self.update_status(f"🔧 Feature {feature_key} {status}", "info")
    
    def on_select_changed(self, event: Select.Changed) -> None:
        """Handle select widget changes."""
        if not self.config:
            return
            
        if event.select.id == "theme-select":
            self.config.starship_theme = str(event.value)
            self.unsaved_changes = True
            self.update_status(f"🎨 Theme changed to {event.value}", "info")
        elif event.select.id == "font-select":
            self.config.terminal_font = str(event.value)
            self.unsaved_changes = True
            self.update_status(f"🔤 Font changed to {event.value}", "info")
    
    def on_switch_changed(self, event: Switch.Changed) -> None:
        """Handle switch changes."""
        if self.config and event.switch.id == "fastfetch-switch":
            self.config.fastfetch_enabled = event.value
            self.unsaved_changes = True
            status = "enabled" if event.value else "disabled"
            self.update_status(f"🚀 Fastfetch {status}", "info")
    
    def action_save(self) -> None:
        """Save configuration to TUI config file."""
        if not self.config_manager or not self.config:
            self.update_status("❌ No configuration to save", "error")
            return
            
        self.update_status("💾 Saving configuration...", "working")
        
        if self.config_manager.save_config(self.config):
            self.unsaved_changes = False
            self.update_status("💾 Configuration saved successfully!", "success")
        else:
            self.update_status("❌ Failed to save configuration!", "error")
    
    def action_apply(self) -> None:
        """Apply configuration changes."""
        if not self.config_manager or not self.config:
            self.update_status("❌ No configuration to apply", "error")
            return
            
        self.update_status("🔄 Applying configuration changes...", "working")
        
        if self.config_manager.apply_configuration(self.config):
            self.unsaved_changes = False
            self.update_status("✅ Configuration applied! Restart your shell to see changes.", "success")
        else:
            self.update_status("❌ Failed to apply configuration changes!", "error")
    
    def action_reset(self) -> None:
        """Reset to default configuration."""
        if not self.config_manager:
            self.update_status("❌ No configuration manager available", "error")
            return
            
        self.config = DXSBashConfig()
        self.config.dxsbash_path = str(self.config_manager.dxsbash_root)
        
        # Refresh the UI
        self.refresh()
        self.unsaved_changes = True
        self.update_status("🔄 Configuration reset to defaults", "warning")
    
    def action_backup(self) -> None:
        """Create configuration backup."""
        if not self.config_manager:
            self.update_status("❌ No configuration manager available", "error")
            return
            
        self.update_status("📋 Creating backup...", "working")
        try:
            self.config_manager._backup_current_shell_config()
            self.update_status("📋 Backup created successfully!", "success")
        except Exception as e:
            self.update_status(f"❌ Backup failed: {str(e)}", "error")
    
    def action_help(self) -> None:
        """Show help information."""
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
    
    def action_refresh(self) -> None:
        """Refresh configuration from files."""
        if not self.config_manager:
            self.update_status("❌ No configuration manager available", "error")
            return
            
        self.update_status("🔄 Refreshing configuration...", "working")
        try:
            self.config = self.config_manager.load_config()
            self.unsaved_changes = False
            self.refresh()
            self.update_status("🔄 Configuration refreshed from files", "success")
        except Exception as e:
            self.update_status(f"❌ Refresh failed: {str(e)}", "error")
    
    def action_quit(self) -> None:
        """Quit the application."""
        if self.unsaved_changes:
            self.update_status("⚠️ You have unsaved changes! Use Ctrl+S to save first.", "warning") 
            return
            
        self.exit()
