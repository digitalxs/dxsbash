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
    COMMON_DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano zoxide trash-cli fzf pwgen powerline'
    
    # Shell-specific dependencies
    BASH_DEPENDENCIES=""
    ZSH_DEPENDENCIES="zsh zsh-autosuggestions zsh-syntax-highlighting"
    FISH_DEPENDENCIES="fish"
    
    # Combine dependencies based on the selected shell
    DEPENDENCIES="$COMMON_DEPENDENCIES"
    
    if [ "$SELECTED_SHELL" = "zsh" ]; then
        DEPENDENCIES="$DEPENDENCIES $ZSH_DEPENDENCIES"
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
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
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
    # we have PACKAGER so just use it
    # for now just going to return early as we have already installed neovim in `installDepend`
    # so I am not sure why we are trying to install it again
    return
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
            ${SUDO_CMD} dnf install -y neovim
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

setupShellConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    # Make sure all required directories exist
    mkdir -p "$USER_HOME/.config/fish"
    
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
        if [ -e "$USER_HOME/.zshrc" ]; then
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
        
        # Link Zsh config
        ln -svf "$GITPATH/.zshrc" "$USER_HOME/.zshrc" || {
            echo "${RED}Failed to create symbolic link for .zshrc${RC}"
            exit 1
        }
        ln -svf "$GITPATH/.zshrc_help" "$USER_HOME/.zshrc_help" || {
            echo "${RED}Failed to create symbolic link for .zshrc_help${RC}"
            exit 1
        }
        
        # Install Oh My Zsh if not already installed
        if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
            echo "${YELLOW}Installing Oh My Zsh...${RC}"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            echo "${GREEN}Oh My Zsh installed${RC}"
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

# Main installation flow
checkEnv
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

# Create symlink to updater in home directory
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
ln -svf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh" || {
    echo "${RED}Failed to create symlink for updater in home directory${RC}"
    echo "${YELLOW}Continuing with installation anyway...${RC}"
}
chmod +x "$USER_HOME/update-dxsbash.sh"

echo "${GREEN}Done!\nLog out and log back in to start using your new $SELECTED_SHELL shell.${RC}"
echo "${YELLOW}Alternatively, you can start using it right now by running:${RC}"
echo "${CYAN}$SELECTED_SHELL${RC}"
