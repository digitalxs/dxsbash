"""Main application class for DXSBash configuration TUI."""

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical, ScrollableContainer
from textual.widgets import (
    Header, Footer, Button, Static, RadioSet, RadioButton,
    Checkbox, Select, Input, TextArea, Tabs, Tab, Label,
    Rule, Switch
)
from textual.binding import Binding
from textual.message import Message
from textual import events
from rich.text import Text

from ..config.manager import ConfigManager
from ..config.models import ShellType, FeatureStatus


class DXSBashConfigApp(App):
    """DXSBash Configuration TUI Application."""
    
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
        self.config_manager = ConfigManager(dxsbash_root)
        self.config = self.config_manager.load_config()
        self.unsaved_changes = False
        self.status_message = ""
    
    def compose(self) -> ComposeResult:
        """Create the application layout."""
        yield Header()
        
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
                    # Create feature checkboxes dynamically
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
            
            # Appearance Section
            with Container(classes="config-section appearance-section"):
                yield Static("🎨 Appearance", classes="section-title")
                
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
            
            # Action Buttons
            with Container(classes="config-section actions-section"):
                yield Button("💾 Save Configuration", variant="primary", id="save-btn")
                yield Button("✅ Apply Changes", variant="success", id="apply-btn") 
                yield Button("🔄 Reset to Defaults", variant="warning", id="reset-btn")
                yield Button("📋 Create Backup", id="backup-btn")
                yield Button("❓ Help", id="help-btn")
        
        with Container(classes="status-line"):
            yield Static(self.status_message, id="status")
        
        yield Footer()
    
    def on_mount(self) -> None:
        """Handle application mount."""
        self.title = "DXSBash Configuration Manager"
        self.sub_title = f"Shell: {self.config.active_shell.value.title()} | Path: {self.config.dxsbash_path}"
        
        # Check if DXSBash is properly installed
        if not self.config_manager.validate_dxsbash_installation():
            self.update_status("⚠️  Warning: DXSBash installation not found or incomplete", "warning")
        else:
            self.update_status("✅ DXSBash installation validated", "success")
    
    def update_status(self, message: str, severity: str = "info"):
        """Update status message."""
        self.status_message = message
        status_widget = self.query_one("#status", Static)
        status_widget.update(message)
        
        # Apply appropriate styling
        status_widget.remove_class("success", "warning", "error", "info")
        status_widget.add_class(severity)
    
    def on_radio_set_changed(self, event: RadioSet.Changed) -> None:
        """Handle shell selection change."""
        if event.radio_set.id == "shell-radio":
            shell_map = {0: ShellType.BASH, 1: ShellType.ZSH, 2: ShellType.FISH}
            old_shell = self.config.active_shell
            self.config.active_shell = shell_map.get(event.index, ShellType.BASH)
            
            if old_shell != self.config.active_shell:
                self.sub_title = f"Shell: {self.config.active_shell.value.title()} | Path: {self.config.dxsbash_path}"
                self.unsaved_changes = True
                self.update_status(f"🔄 Shell changed to {self.config.active_shell.value.title()}", "info")
    
    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        """Handle feature checkbox changes."""
        feature_map = {
            "docker-check": "docker",
            "kubernetes-check": "kubernetes", 
            "python-check": "python",
            "nodejs-check": "nodejs",
            "git_extended-check": "git_extended",
            "network_tools-check": "network_tools",
            "system_monitoring-check": "system_monitoring",
            "archive_tools-check": "archive_tools",
            "development_tools-check": "development_tools",
        }
        
        if event.checkbox.id in feature_map:
            feature = feature_map[event.checkbox.id]
            old_status = self.config.features.get(feature, FeatureStatus.DISABLED)
            new_status = FeatureStatus.ENABLED if event.value else FeatureStatus.DISABLED
            
            if old_status != new_status:
                self.config.features[feature] = new_status
                self.unsaved_changes = True
                status_text = "enabled" if event.value else "disabled"
                self.update_status(f"🔧 Feature '{feature}' {status_text}", "info")
    
    def on_select_changed(self, event: Select.Changed) -> None:
        """Handle select widget changes."""
        if event.select.id == "theme-select":
            old_theme = self.config.starship_theme
            self.config.starship_theme = str(event.value)
            if old_theme != self.config.starship_theme:
                self.unsaved_changes = True
                self.update_status(f"🎨 Theme changed to {self.config.starship_theme}", "info")
        
        elif event.select.id == "font-select":
            old_font = self.config.terminal_font
            self.config.terminal_font = str(event.value)
            if old_font != self.config.terminal_font:
                self.unsaved_changes = True
                self.update_status(f"🖋️ Font changed to {self.config.terminal_font}", "info")
    
    def on_switch_changed(self, event: Switch.Changed) -> None:
        """Handle switch changes."""
        if event.switch.id == "fastfetch-switch":
            old_value = self.config.fastfetch_enabled
            self.config.fastfetch_enabled = event.value
            if old_value != self.config.fastfetch_enabled:
                self.unsaved_changes = True
                status_text = "enabled" if event.value else "disabled"
                self.update_status(f"🖥️ Fastfetch {status_text}", "info")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "save-btn":
            self.action_save()
        elif event.button.id == "apply-btn":
            self.action_apply()
        elif event.button.id == "reset-btn":
            self.action_reset()
        elif event.button.id == "backup-btn":
            self.action_backup()
        elif event.button.id == "help-btn":
            self.action_help()
    
    def action_save(self) -> None:
        """Save configuration to TUI config file."""
        if self.config_manager.save_config(self.config):
            self.unsaved_changes = False
            self.update_status("💾 Configuration saved successfully!", "success")
        else:
            self.update_status("❌ Failed to save configuration!", "error")
    
    def action_apply(self) -> None:
        """Apply configuration changes to actual DXSBash files."""
        self.update_status("🔄 Applying configuration changes...", "info")
        
        if self.config_manager.apply_configuration(self.config):
            self.unsaved_changes = False
            self.update_status("✅ Configuration applied! Please restart your shell to see changes.", "success")
        else:
            self.update_status("❌ Failed to apply configuration changes!", "error")
    
    def action_reset(self) -> None:
        """Reset to default configuration."""
        # TODO: Add confirmation dialog
        from ..config.models import DXSBashConfig
        self.config = DXSBashConfig()
        self.config.dxsbash_path = self.config_manager.dxsbash_root
        
        # Refresh the UI
        self.refresh()
        self.unsaved_changes = True
        self.update_status("🔄 Configuration reset to defaults", "warning")
    
    def action_backup(self) -> None:
        """Create configuration backup."""
        self.config_manager._backup_current_shell_config()
        self.update_status("📋 Backup created successfully!", "success")
    
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

🔧 FEATURES:
Enable/disable tool-specific aliases and functions.
Unavailable features show when tools aren't installed.

🎨 APPEARANCE:
- Starship Theme - Changes prompt appearance
- Terminal Font - Must be installed separately
- Fastfetch - System info display on shell startup

💾 SAVE vs APPLY:
- Save - Store settings in TUI config
- Apply - Actually modify DXSBash files

⚠️ IMPORTANT:
Always create backups before applying changes!
"""
        # TODO: Show help in a dialog or separate screen
        self.update_status("❓ Help information logged to console", "info")
        print(help_text)
    
    def action_refresh(self) -> None:
        """Refresh configuration from files."""
        self.config = self.config_manager.load_config()
        self.unsaved_changes = False
        self.refresh()
        self.update_status("🔄 Configuration refreshed from files", "info")
    
    def action_quit(self) -> None:
        """Quit the application."""
        if self.unsaved_changes:
            # TODO: Add confirmation dialog
            self.update_status("⚠️ You have unsaved changes! Use Ctrl+S to save first.", "warning") 
            return
        self.exit()