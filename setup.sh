#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

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
    DEPENDENCIES='bash bash-completion tar bat tree multitail curl wget unzip fontconfig joe git nala plocate nano fish zoxide trash-cli fzf pwgen powerline'
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
    elif [ "$PACKAGER" = "xbps-install" ]; then
        ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nix-env" ]; then
        ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch  nixos.pkgs.starship
    elif [ "$PACKAGER" = "dnf" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    else
        ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
    fi

    # Check to see if the MesloLGS Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="MesloLGS Nerd Font Mono"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        echo "Installing font '$FONT_NAME'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
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

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    ## Check if a bashrc file is already there.
    OLD_BASHRC="$USER_HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ]; then
        BACKUP_FILE="$USER_HOME/.bashrc.bak"
        
        # If backup already exists, create a timestamped version
        if [ -e "$BACKUP_FILE" ]; then
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            BACKUP_FILE="$USER_HOME/.bashrc.bak.$TIMESTAMP"
        fi
        
        echo "${YELLOW}Moving old bash config file to $BACKUP_FILE${RC}"
        
        if ! mv "$OLD_BASHRC" "$BACKUP_FILE"; then
            echo "${RED}Warning: Can't move the old bash config file!${RC}"
            echo "${YELLOW}Continuing with installation anyway...${RC}"
            # Don't exit, continue with installation
        fi
    fi
    
    echo "${YELLOW}Linking new bash config file...${RC}"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
        echo "${RED}Failed to create symbolic link for .bashrc${RC}"
        exit 1
    }
    # link .bashrc_help
    ln -svf "$GITPATH/.bashrc_help" "$USER_HOME/.bashrc_help" || {
        echo "${RED}Failed to create symbolic link for .bashrc_help${RC}"
        exit 1
    }
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        echo "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
    
    # Add a symlink to updater.sh in the home directory
    echo "${YELLOW}Creating updater symlink in home directory...${RC}"
    ln -svf "$GITPATH/updater.sh" "$USER_HOME/update-dxsbash.sh" || {
        echo "${RED}Failed to create symlink for updater in home directory${RC}"
        echo "${YELLOW}Continuing with installation anyway...${RC}"
        # Don't exit, continue with installation
    }
    # Make sure the symlink is executable
    chmod +x "$USER_HOME/update-dxsbash.sh"
    }
installResetScript() {
    echo "${YELLOW}Installing reset-bash-profile script...${RC}"
    
    # Copy the reset script to the linuxtoolbox directory
    if [ -f "$GITPATH/reset-bash-profile.sh" ]; then
        cp "$GITPATH/reset-bash-profile.sh" "$LINUXTOOLBOXDIR/"
        chmod +x "$LINUXTOOLBOXDIR/reset-bash-profile.sh"
        
        # Create a symbolic link to make it available system-wide
        ${SUDO_CMD} ln -sf "$LINUXTOOLBOXDIR/reset-bash-profile.sh" /usr/local/bin/reset-bash-profile
        
        echo "${GREEN}Reset script installed successfully at $LINUXTOOLBOXDIR/reset-bash-profile.sh${RC}"
        echo "${GREEN}You can run it with: sudo reset-bash-profile [username]${RC}"
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

checkEnv
installDepend
installStarshipAndFzf
installZoxide
install_additional_dependencies

if linkConfig; then
    installResetScript
    installUpdaterCommand
    echo "${GREEN}Done!\nrestart your shell to see the changes.${RC}"
else
    echo "${RED}Something went wrong!${RC}"
fi
