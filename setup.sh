#!/bin/sh -e
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[34m'
CYAN='\033[36m'

# Ensure the .config directory exists
# Check if the home directory and linuxtoolbox folder exist, create them if they don't
CONFIGDIR="$HOME/.config"
if [ ! -d "$CONFIGDIR" ]; then
    echo "${YELLOW}Creating .config directory: $CONFIGDIR${RC}"
    mkdir -p "$CONFIGDIR"
    echo "${GREEN}.config directory created: $CONFIGDIR${RC}"
fi

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"
if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ -d "$LINUXTOOLBOXDIR/dxsbash" ]; then rm -rf "$LINUXTOOLBOXDIR/dxsbash"; fi
echo "${YELLOW}Cloning dxsbash repository into: $LINUXTOOLBOXDIR/dxsbash${RC}"
git clone https://github.com/digitalxs/dxsbash "$LINUXTOOLBOXDIR/dxsbash"
if [ $? -eq 0 ]; then
    echo "${GREEN}Successfully cloned dxsbash repository${RC}"
else
    echo "${RED}Failed to clone dxsbash repository${RC}"
    exit 1
fi

# add variables to top level so can easily be accessed by all functions
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""
SELECTED_SHELL=""

cd "$LINUXTOOLBOXDIR/dxsbash" || exit

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo "Using $pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi
    echo "Using $SUDO_CMD as privilege escalation software"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

installDepend() {
    ## Check for dependencies.
    COMMON_DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nano zoxide fzf pwgen'
    
    # Shell-specific dependencies
    BASH_DEPENDENCIES=""
    ZSH_DEPENDENCIES="zsh"
    FISH_DEPENDENCIES="fish"
    
    # Combine dependencies based on the selected shell and distribution
    DEPENDENCIES="$COMMON_DEPENDENCIES"
    
    # Add distribution-specific packages
    if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
        DEPENDENCIES="$DEPENDENCIES nala plocate trash-cli powerline"
    elif [ "$PACKAGER" = "dnf" ]; then
        DEPENDENCIES="$DEPENDENCIES dnf-plugins-core dnf-utils plocate trash-cli powerline"
    elif [ "$PACKAGER" = "pacman" ]; then
        DEPENDENCIES="$DEPENDENCIES plocate trash-cli powerline"
    fi
    
    # Add shell-specific dependencies
    if [ "$SELECTED_SHELL" = "zsh" ]; then
        DEPENDENCIES="$DEPENDENCIES $ZSH_DEPENDENCIES"
        
        # Add distribution-specific Zsh plugins
        if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
            DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
        elif [ "$PACKAGER" = "dnf" ]; then
            # Fedora/RHEL package names may differ
            if ${SUDO_CMD} dnf list zsh-autosuggestions &>/dev/null; then
                DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions"
            fi
            if ${SUDO_CMD} dnf list zsh-syntax-highlighting &>/dev/null; then
                DEPENDENCIES="$DEPENDENCIES zsh-syntax-highlighting"
            fi
        elif [ "$PACKAGER" = "pacman" ]; then
            DEPENDENCIES="$DEPENDENCIES zsh-autosuggestions zsh-syntax-highlighting"
        fi
    elif [ "$SELECTED_SHELL" = "fish" ]; then
        DEPENDENCIES="$DEPENDENCIES $FISH_DEPENDENCIES"
    fi
    
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi
    
    echo "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            echo "AUR helper already installed"
        fi
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            echo "No AUR helper found. Please install yay or paru."
            exit 1
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nala" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    elif [ "$PACKAGER" = "emerge" ]; then
        ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
        if [ "$SELECTED_SHELL" = "zsh" ]; then
            ${SUDO_CMD} ${PACKAGER} -v app-shells/zsh app-shells/zsh-completions
        elif [ "$SELECTED_SHELL" = "fish" ]; then
            ${SUDO_CMD} ${PACKAGER} -v app-shells/fish
        fi
    elif [ "$PACKAGER" = "xbps-install" ]; then
        ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nix-env" ]; then
        ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship
        if [ "$SELECTED_SHELL" = "zsh" ]; then
            ${SUDO_CMD} ${PACKAGER} -iA nixos.zsh nixos.zsh-completions nixos.zsh-autosuggestions nixos.zsh-syntax-highlighting
        elif [ "$SELECTED_SHELL" = "fish" ]; then
            ${SUDO_CMD} ${PACKAGER} -iA nixos.fish nixos.fishPlugins.done
        fi
    elif [ "$PACKAGER" = "dnf" ]; then
        # Fedora-specific handling
        echo "${YELLOW}Detected Fedora or RHEL-based distribution${RC}"
        
        # Check for EPEL repository if on RHEL/CentOS
        if [ -f /etc/redhat-release ] && ! grep -q "Fedora" /etc/redhat-release; then
            if ! ${SUDO_CMD} ${PACKAGER} list installed epel-release >/dev/null 2>&1; then
                echo "${YELLOW}Installing EPEL repository for additional packages...${RC}"
                ${SUDO_CMD} ${PACKAGER} install -y epel-release
            fi
        fi
        
        # Install RPM Fusion repositories for Fedora
        if grep -q "Fedora" /etc/redhat-release 2>/dev/null; then
            if ! ${SUDO_CMD} ${PACKAGER} list installed rpmfusion-free-release >/dev/null 2>&1; then
                echo "${YELLOW}Installing RPM Fusion repositories...${RC}"
                ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
                ${SUDO_CMD} ${PACKAGER} install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            fi
        fi
        
        # Adjust package names for Fedora/RHEL
        FEDORA_DEPENDENCIES=$(echo "$DEPENDENCIES" | sed 's/batcat/bat/g' | sed 's/nala/dnf-utils/g')
        
        # Install Fedora/RHEL packages
        ${SUDO_CMD} ${PACKAGER} install -y $FEDORA_DEPENDENCIES
    else
        ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
    fi

    # Check to see if the FiraCode Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="FiraCode Nerd Font"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        echo "Installing font '$FONT_NAME'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        # check if the file is accessible
        if wget -q --spider "$FONT_URL"; then
            TEMP_DIR=$(mktemp -d)
            wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
            unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
            mkdir -p "$FONT_DIR"/"$FONT_NAME"
            mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
            # Update the font cache
            fc-cache -fv
            # delete the files created from this
            rm -rf "${TEMP_DIR}"
            echo "'$FONT_NAME' installed successfully."
        else
            echo "Font '$FONT_NAME' not installed. Font URL is not accessible."
        fi
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi
    if ! curl -sS https://starship.rs/install.sh | sh; then
        echo "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
    if command_exists fzf; then
        echo "Fzf already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        echo "Zoxide already installed"
        return
    fi
    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        echo "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

install_additional_dependencies() {
    # Check if Neovim needs to be installed or is already handled
    if command_exists nvim; then
        echo "${GREEN}Neovim already installed${RC}"
        return
    fi
    
    echo "${YELLOW}Installing Neovim...${RC}"
    case "$PACKAGER" in
        *apt)
            if [ ! -d "/opt/neovim" ]; then
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                ./nvim.appimage --appimage-extract
                ${SUDO_CMD} mv squashfs-root /opt/neovim
                ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
            fi
            ;;
        *zypper)
            ${SUDO_CMD} zypper refresh
            ${SUDO_CMD} zypper -n install neovim # -y doesn't work on opensuse -n is short for -non-interactive which is equivalent to -y
            ;;
        *dnf)
            ${SUDO_CMD} dnf check-update
            
            # Check if Neovim is available in standard repositories
            if ${SUDO_CMD} dnf list neovim &>/dev/null; then
                ${SUDO_CMD} dnf install -y neovim
            else
                # Try to install from COPR repository if not available
                echo "${YELLOW}Installing Neovim from COPR repository...${RC}"
                ${SUDO_CMD} dnf copr enable -y agriffis/neovim-nightly
                ${SUDO_CMD} dnf install -y neovim
            fi
            ;;
        *pacman)
            ${SUDO_CMD} pacman -Syu
            ${SUDO_CMD} pacman -S --noconfirm neovim
            ;;
        *)
            echo "No supported package manager found. Please install neovim manually."
            exit 1
            ;;
    esac
}

create_fastfetch_config() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch"
    fi
    # Check if the fastfetch config file exists
    if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
    fi
    ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
        echo "${RED}Failed to create symbolic link for fastfetch config${RC}"
        exit 1
    }
}

init_fedora_zsh_plugins() {
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Handle Fedora/RHEL zsh plugins which might be in different locations
    if [ "$PACKAGER" = "dnf" ] && [ "$SELECTED_SHELL" = "zsh" ]; then
        echo "${YELLOW}Setting up Zsh plugins for Fedora/RHEL...${RC}"
        
        # Add plugin sourcing to .zshrc if files exist
        ZSH_PLUGIN_DIR="/usr/share/zsh/plugins"
        
        # Create plugin loader function
        cat > "$USER_HOME/.zsh_plugins" <<EOL
# Generated by dxsbash setup for Fedora/RHEL
# Load Zsh plugins if available

# Autosuggestions
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
EOL
        
        # Try to install plugins manually if they're not found in standard locations
        if [ ! -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
            echo "${YELLOW}Installing Zsh autosuggestions plugin manually...${RC}"
            PLUGIN_DIR="$USER_HOME/.zsh/plugins"
            mkdir -p "$PLUGIN_DIR"
            git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
            
            # Add to .zsh_plugins
            echo "# Manual installation" >> "$USER_HOME/.zsh_plugins"
            echo "source $PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$USER_HOME/.zsh_plugins"
        fi
        
        if [ ! -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && [ ! -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
            echo "${YELLOW}Installing Zsh syntax highlighting plugin manually...${RC}"
            PLUGIN_DIR="$USER_HOME/.zsh/plugins"
            mkdir -p "$PLUGIN_DIR"
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
            
            # Add to .zsh_plugins
            echo "source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$USER_HOME/.zsh_plugins"
        fi
        
        echo "${GREEN}Zsh plugins configured for Fedora/RHEL${RC}"
    fi
}

setupShellConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Make sure all required directories exist
    mkdir -p "$USER_HOME/.config/fish"
    mkdir -p "$USER_HOME/.zsh"
    
    echo "${YELLOW}Setting up configuration for $SELECTED_SHELL...${RC}"
    
    # Backup existing config files
    if [ "$SELECTED_SHELL" = "bash" ]; then
        if [ -e "$USER_HOME/.bashrc" ]; then
            BACKUP_FILE="$USER_HOME/.bashrc.bak"
            if [ -e "$BACKUP_FILE" ]; then
                TIMESTAMP=$(date +%Y%m%d%H%M%S)
                BACKUP_FILE="$USER_HOME/.bashrc.bak.$TIMESTAMP"
            fi
            echo "${YELLOW}Moving old bash config file to $BACKUP_FILE${RC}"
            if ! mv "$USER_HOME/.bashrc" "$BACKUP_FILE"; then
                echo "${RED}Warning: Can't move the old bash config file!${RC}"
                echo "${YELLOW}Continuing with installation anyway...${RC}"
            fi
        fi
        
        # Link Bash config
        ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
            echo "${RED}Failed to create symbolic link for .bashrc${RC}"
            exit 1
        }
        ln -svf "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help" || {
            echo "${RED}Failed to create symbolic link for .bashrc_help${RC}"
            exit 1
        }
        
elif [ "$SELECTED_SHELL" = "zsh" ]; then
        # Check if .zshrc exists and handle accordingly
        if [ -e "$USER_HOME/.zshrc" ]; then
            # Backup existing .zshrc
            BACKUP_FILE="$USER_HOME/.zshrc.bak"
            if [ -e "$BACKUP_FILE" ]; then
                TIMESTAMP=$(date +%Y%m%d%H%M%S)
                BACKUP_FILE="$USER_HOME/.zshrc.bak.$TIMESTAMP"
            fi
            echo "${YELLOW}Moving old zsh config file to $BACKUP_FILE${RC}"
            if ! mv "$USER_HOME/.zshrc" "$BACKUP_FILE"; then
                echo "${RED}Warning: Can't move the old zsh config file!${RC}"
                echo "${YELLOW}Continuing with installation anyway...${RC}"
            fi
        fi
        
        # Link Zsh config - whether .zshrc existed or not, we'll use the one from dxsbash
        echo "${GREEN}Installing dxsbash .zshrc file${RC}"
        ln -svf "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
            echo "${RED}Failed to create symbolic link for .zshrc${RC}"
            # If symlinking fails, try direct copy
            echo "${YELLOW}Attempting direct copy of .zshrc...${RC}"
            cp -f "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
                echo "${RED}Failed to copy .zshrc file!${RC}"
                exit 1
            }
        }
        
        ln -svf "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
            echo "${RED}Failed to create symbolic link for .zshrc_help${RC}"
            # If symlinking fails, try direct copy
            echo "${YELLOW}Attempting direct copy of .zshrc_help...${RC}"
            cp -f "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
                echo "${RED}Failed to copy .zshrc_help file!${RC}"
                exit 1
            }
        }
        
        # Install Oh My Zsh if not already installed
        if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
            echo "${YELLOW}Installing Oh My Zsh...${RC}"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            echo "${GREEN}Oh My Zsh installed${RC}"
        fi
        
        # Setup Fedora/RHEL specific Zsh plugins
        init_fedora_zsh_plugins
        
        # Add plugin sourcing to .zshrc if it exists
        if [ -f "$USER_HOME/.zsh_plugins" ]; then
            # Add source line to .zshrc if not already present
            if ! grep -q "source ~/.zsh_plugins" "$USER_HOME/.zshrc"; then
                echo "${YELLOW}Adding plugins to .zshrc...${RC}"
                echo "" >> "$USER_HOME/.zshrc"
                echo "# Source plugins" >> "$USER_HOME/.zshrc"
                echo "[ -f ~/.zsh_plugins ] && source ~/.zsh_plugins" >> "$USER_HOME/.zshrc"
            fi
        fi
        
    elif [ "$SELECTED_SHELL" = "fish" ]; then
        if [ -e "$USER_HOME/.config/fish/config.fish" ]; then
            BACKUP_DIR="$USER_HOME/.config/fish/backup"
            mkdir -p "$BACKUP_DIR"
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            BACKUP_FILE="$BACKUP_DIR/config.fish.$TIMESTAMP"
            echo "${YELLOW}Moving old fish config file to $BACKUP_FILE${RC}"
            if ! mv "$USER_HOME/.config/fish/config.fish" "$BACKUP_FILE"; then
                echo "${RED}Warning: Can't move the old fish config file!${RC}"
                echo "${YELLOW}Continuing with installation anyway...${RC}"
            fi
        fi
        
        # Link Fish config
        ln -svf "$GITPATH/config.fish" "$USER_HOME/.config/fish/config.fish" || {
            echo "${RED}Failed to create symbolic link for config.fish${RC}"
            exit 1
        }
        
        # Create help file for fish
        ln -svf "$GITPATH/fish_help" "$USER_HOME/.config/fish/fish_help" || {
            echo "${RED}Failed to create symbolic link for fish_help${RC}"
            exit 1
        }
        
        # Setup Fisher plugin manager if not already installed
        if ! command_exists fisher; then
            echo "${YELLOW}Installing Fisher plugin manager for Fish...${RC}"
            fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
            echo "${GREEN}Fisher installed${RC}"
            
            # Install useful plugins
            echo "${YELLOW}Installing Fish plugins...${RC}"
            fish -c "fisher install PatrickF1/fzf.fish"
            fish -c "fisher install jethrokuan/z"
            fish -c "fisher install IlanCosman/tide@v5"
            echo "${GREEN}Fish plugins installed${RC}"
        fi
    fi
    
    # Link starship.toml for all shells
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        echo "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
}

setDefaultShell() {
    echo "${YELLOW}Setting $SELECTED_SHELL as your default shell...${RC}"
    
    SHELL_PATH=""
    case "$SELECTED_SHELL" in
        bash)
            SHELL_PATH=$(which bash)
            ;;
        zsh)
            SHELL_PATH=$(which zsh)
            ;;
        fish)
            SHELL_PATH=$(which fish)
            ;;
    esac
    
    if [ -z "$SHELL_PATH" ]; then
        echo "${RED}Error: Could not find path to $SELECTED_SHELL. Please set it as your default shell manually.${RC}"
        return 1
    fi
    
    # Check if the shell is in /etc/shells
    if ! grep -q "^$SHELL_PATH$" /etc/shells; then
        echo "${YELLOW}Adding $SHELL_PATH to /etc/shells...${RC}"
        echo "$SHELL_PATH" | ${SUDO_CMD} tee -a /etc/shells > /dev/null
    fi
    
    # Change the default shell
    ${SUDO_CMD} chsh -s "$SHELL_PATH" "$USER"
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}Successfully set $SELECTED_SHELL as your default shell${RC}"
    else
        echo "${RED}Failed to set $SELECTED_SHELL as your default shell. Please do it manually with:${RC}"
        echo "${YELLOW}chsh -s $SHELL_PATH${RC}"
    fi
}

installResetScript() {
    echo "${YELLOW}Installing reset-shell-profile script...${RC}"
    
    # Copy the reset script to the linuxtoolbox directory
    if [ -f "$GITPATH/reset-bash-profile.sh" ]; then
        cp "$GITPATH/reset-bash-profile.sh" "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
        chmod +x "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
        
        # Copy for other shells if available
        if [ -f "$GITPATH/reset-zsh-profile.sh" ]; then
            cp "$GITPATH/reset-zsh-profile.sh" "$LINUXTOOLBOXDIR/reset-zsh-profile.sh"
            chmod +x "$LINUXTOOLBOXDIR/reset-zsh-profile.sh"
        fi
        
        if [ -f "$GITPATH/reset-fish-profile.sh" ]; then
            cp "$GITPATH/reset-fish-profile.sh" "$LINUXTOOLBOXDIR/reset-fish-profile.sh"
            chmod +x "$LINUXTOOLBOXDIR/reset-fish-profile.sh"
        fi
        
        # Create a symbolic link for the appropriate reset script based on selected shell
        case "$SELECTED_SHELL" in
            bash)
                ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                ;;
            zsh)
                if [ -f "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" ]; then
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-zsh-profile.sh" /usr/local/bin/reset-shell-profile
                else
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                    echo "${YELLOW}Note: Using bash reset script as fallback for zsh${RC}"
                fi
                ;;
            fish)
                if [ -f "$LINUXTOOLBOXDIR/reset-fish-profile.sh" ]; then
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-fish-profile.sh" /usr/local/bin/reset-shell-profile
                else
                    ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-shell-profile
                    echo "${YELLOW}Note: Using bash reset script as fallback for fish${RC}"
                fi
                ;;
        esac
        
        echo "${GREEN}Reset script installed successfully at $LINUXTOOLBOXDIR/reset-*-profile.sh${RC}"
        echo "${GREEN}You can run it with: sudo reset-shell-profile [username]${RC}"
    else
        echo "${RED}Reset script not found in $GITPATH${RC}"
        echo "${YELLOW}You will need to manually copy it later${RC}"
    fi
}

installUpdaterCommand() {
    echo "${YELLOW}Installing dxsbash updater script...${RC}"
    
    # Copy the updater script to the linuxtoolbox directory
    if [ -f "$GITPATH/updater.sh" ]; then
        # Use cp -p to preserve permissions from source
        cp -p "$GITPATH/updater.sh" "$LINUXTOOLBOXDIR/"
        # Ensure it's executable regardless of source permissions
        chmod +x "$LINUXTOOLBOXDIR/updater.sh"
        
        # Create a symbolic link to make it available system-wide
        ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/updater.sh" /usr/local/bin/upbashdxs
        
        echo "${GREEN}Updater script installed successfully at $LINUXTOOLBOXDIR/updater.sh${RC}"
        echo "${GREEN}You can update dxsbash anytime by running: upbashdxs${RC}"
    else
        echo "${RED}Updater script not found in $GITPATH${RC}"
        echo "${YELLOW}You will need to update manually${RC}"
    fi
}

detectDistro() {
    # Detect the specific distribution for better handling
    DISTRO="unknown"
    
    if [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
        echo "${BLUE}Detected Fedora Linux${RC}"
    elif [ -f /etc/redhat-release ]; then
        if grep -q "CentOS" /etc/redhat-release; then
            DISTRO="centos"
            echo "${BLUE}Detected CentOS Linux${RC}"
        elif grep -q "Red Hat Enterprise Linux" /etc/redhat-release; then
            DISTRO="rhel"
            echo "${BLUE}Detected Red Hat Enterprise Linux${RC}"
        else
            DISTRO="redhat-based"
            echo "${BLUE}Detected Red Hat-based Linux${RC}"
        fi
    elif [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
        DISTRO="ubuntu"
        echo "${BLUE}Detected Ubuntu Linux${RC}"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        echo "${BLUE}Detected Debian Linux${RC}"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        echo "${BLUE}Detected Arch Linux${RC}"
    elif [ -f /etc/SuSE-release ] || [ -f /etc/opensuse-release ]; then
        DISTRO="suse"
        echo "${BLUE}Detected SUSE Linux${RC}"
    else
        # Generic detection
        if command_exists apt; then
            DISTRO="debian-based"
            echo "${BLUE}Detected Debian-based Linux${RC}"
        elif command_exists dnf; then
            DISTRO="fedora-based"
            echo "${BLUE}Detected Fedora-based Linux${RC}"
        elif command_exists pacman; then
            DISTRO="arch-based"
            echo "${BLUE}Detected Arch-based Linux${RC}"
        elif command_exists zypper; then
            DISTRO="suse-based"
            echo "${BLUE}Detected SUSE-based Linux${RC}"
        fi
    fi
}

selectShell() {
    echo "${CYAN}==================================================${RC}"
    echo "${CYAN}       Select your preferred shell:               ${RC}"
    echo "${CYAN}==================================================${RC}"
    echo "${YELLOW}1) Bash ${RC}(default, most compatible)"
    echo "${YELLOW}2) Zsh ${RC}(enhanced features, popular alternative)"
    echo "${YELLOW}3) Fish ${RC}(modern, user-friendly, less POSIX-compatible)"
    echo ""
    
    # Default to bash if no selection is made
    SELECTED_SHELL="bash"
    
    read -p "Enter your choice [1-3] (default: 1): " shell_choice
    
    case "$shell_choice" in
        2)
            if command_exists zsh; then
                SELECTED_SHELL="zsh"
            else
                echo "${YELLOW}Zsh is not installed yet. It will be installed during setup.${RC}"
                SELECTED_SHELL="zsh"
            fi
            ;;
        3)
            if command_exists fish; then
                SELECTED_SHELL="fish"
            else
                echo "${YELLOW}Fish is not installed yet. It will be installed during setup.${RC}"
                SELECTED_SHELL="fish"
            fi
            ;;
        *)
            SELECTED_SHELL="bash"
            ;;
    esac
    
    echo "${GREEN}Selected shell: $SELECTED_SHELL${RC}"
}

configure_konsole() {
    echo "${YELLOW}Configuring Konsole to use FiraCode Nerd Font...${RC}"
    
    # Get user home directory
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Create Konsole profile directory if it doesn't exist
    KONSOLE_DIR="$USER_HOME/.local/share/konsole"
    mkdir -p "$KONSOLE_DIR"
    
    # Create/update Konsole profile with FiraCode Nerd Font
    PROFILE_NAME="DXSBash.profile"
    PROFILE_PATH="$KONSOLE_DIR/$PROFILE_NAME"
    
    # Create profile file
    cat > "$PROFILE_PATH" << EOL
[Appearance]
ColorScheme=Breeze
Font=FiraCode Nerd Font,12,-1,5,50,0,0,0,0,0

[General]
Name=DXSBash
Parent=FALLBACK/
TerminalCenter=false
TerminalMargin=1

[Scrolling]
HistoryMode=2
ScrollBarPosition=2

[Terminal Features]
BlinkingCursorEnabled=true
EOL
    
    # Make sure permissions are correct
    chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$PROFILE_PATH"
    
    # Create/update Konsole configuration to use the new profile by default
    KONSOLERC="$USER_HOME/.config/konsolerc"
    
    # Only create konsolerc if it doesn't exist
    if [ ! -f "$KONSOLERC" ]; then
        cat > "$KONSOLERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[MainWindow]
MenuBar=Disabled
ToolBarsMovable=Disabled

[TabBar]
NewTabButton=true
EOL
        chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$KONSOLERC"
    else
        # If konsolerc exists, just update the DefaultProfile line
        if grep -q "DefaultProfile=" "$KONSOLERC"; then
            # Replace existing DefaultProfile line
            sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$KONSOLERC"
        else
            # Add DefaultProfile line if it doesn't exist
            echo "DefaultProfile=DXSBash.profile" >> "$KONSOLERC"
        fi
    fi
    
    echo "${GREEN}Konsole configured to use FiraCode Nerd Font${RC}"
}

configure_kde_terminal_emulators() {
    # Check if running in KDE environment
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || command_exists konsole; then
        echo "${YELLOW}KDE environment detected, configuring terminal emulators...${RC}"
        
        # Configure Konsole
        if command_exists konsole; then
            configure_konsole
        fi
        
        # Configure Yakuake if installed
        if command_exists yakuake; then
            echo "${YELLOW}Configuring Yakuake to use FiraCode Nerd Font...${RC}"
            
            # Yakuake uses the same profiles as Konsole, so we just need to update yakuakerc
            USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
            YAKUAKERC="$USER_HOME/.config/yakuakerc"
            
            if [ -f "$YAKUAKERC" ]; then
                # Update existing DefaultProfile
                if grep -q "DefaultProfile=" "$YAKUAKERC"; then
                    sed -i "s/DefaultProfile=.*/DefaultProfile=DXSBash.profile/" "$YAKUAKERC"
                else
                    echo "DefaultProfile=DXSBash.profile" >> "$YAKUAKERC"
                fi
            else
                # Create new yakuakerc
                mkdir -p "$USER_HOME/.config"
                cat > "$YAKUAKERC" << EOL
[Desktop Entry]
DefaultProfile=DXSBash.profile

[Dialogs]
FirstRun=false

[Window]
KeepOpen=false
EOL
                chown "${SUDO_USER:-$USER}:$(id -gn ${SUDO_USER:-$USER})" "$YAKUAKERC"
            fi
            
            echo "${GREEN}Yakuake configured to use FiraCode Nerd Font${RC}"
        fi
    fi
}

# Main installation flow
checkEnv
detectDistro
selectShell
installDepend
installStarshipAndFzf
installZoxide
install_additional_dependencies
create_fastfetch_config
setupShellConfig
setDefaultShell
installResetScript
installUpdaterCommand
configure_kde_terminal_emulators

# Create logs directory
mkdir -p "$HOME/.dxsbash/logs"
touch "$HOME/.dxsbash/logs/dxsbash.log"
chmod R 777 "$HOME/.dxsbash/logs/dxsbash.log"

# Copy the utilities file - only if source and destination are different
if [ "$GITPATH/dxsbash-utils.sh" != "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh" ]; then
    cp -f "$GITPATH/dxsbash-utils.sh" "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh"
fi
chmod +x "$LINUXTOOLBOXDIR/dxsbash/dxsbash-utils.sh"
chmod -R 700 "$HOME/.dxsbash/logs"
chmod -R 644 "$HOME/.dxsbash/logs/dxsbash.log"

# Create symlink to updater in home directory
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
ln -svf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh" || {
    echo "${RED}Failed to create symlink for updater in home directory${RC}"
    echo "${YELLOW}Continuing with installation anyway...${RC}"
}
chmod +x "$USER_HOME/update-dxsbash.sh"

echo "${GREEN}Done!\nLog out and log back in to start using your new $SELECTED_SHELL shell.${RC}"
echo "${CYAN}$SELECTED_SHELL${RC}"
