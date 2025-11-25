#!/bin/bash
set -e

clear

BLUE="\e[34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

REQUIREMENTS_FILE="requirements.txt"
GTK_THEMES="$(pwd)/themes/gtk"
GTK_THEMES_DEST="$HOME/.themes"
CONFIG_DIR="$(pwd)/config"
CONFIG_DEST_DIR="$HOME/.config"
HOME_DIR="$HOME"

LOADING=("/" "|" "\\" "-")
LOADING_INDEX=0
LOADING_MAX=4
SLEEP_INTERVAL=0.1 

loading() {
    echo -ne "${LOADING[$LOADING_INDEX]}  $1 \r"
    ((LOADING_INDEX=(LOADING_INDEX+1)%LOADING_MAX))
    sleep $SLEEP_INTERVAL  
}

install_package() {
    local package=$1
    local temp_log=$(mktemp)
    
    sudo apt install -y "$package" > "$temp_log" 2>&1 &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        loading "Installing $package"
    done
    
    wait $pid
    local exit_code=$?
    
    echo -ne "\r\033[K"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${BLUE}✔ $package Installed${RESET}"
        rm -f "$temp_log"
        return 0
    else
        echo -e "${RED}✘ $package Failed To Install${RESET}"
        rm -f "$temp_log"
        return 1
    fi
}

install_packages() {
    for package in "$@"; do
        install_package "$package"
    done
}

remove_package() {
    local package=$1
    local temp_log=$(mktemp)
    
    sudo apt remove -y "$package" > "$temp_log" 2>&1 &
    local pid=$!
    
    # Show animated loading while process runs
    while kill -0 $pid 2>/dev/null; do
        loading "Removing $package"
    done
    
    wait $pid
    local exit_code=$?
    
    echo -ne "\r\033[K"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${BLUE}✔ $package Removed${RESET}"
        rm -f "$temp_log"
        return 0
    else
        echo -e "${RED}✘ $package Failed To Remove${RESET}"
        rm -f "$temp_log"
        return 1
    fi
}


echo -e "${BLUE}=============================================="
echo -e "${BLUE}         Ganyu Xmonad  Debian Installer"
echo -e "${BLUE}==============================================${RESET}"

# ============================================================
#                     PATH CONFIGURATION
# ============================================================

if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi

source ~/.bashrc

echo -e "${BLUE}✔ PATH In ~/.bashrc Is Updated${RESET}"


# ============================================================
#                     QT PROFILE CONFIG
# ============================================================

if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" ~/.profile; then
cat << 'EOF' >> ~/.profile

# QT Theming
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=Kvantum
EOF
fi

echo -e "${BLUE}✔ QT Environment Variables In ~/.profile Is Added${RESET}"


# ============================================================
#                     APT REPOSITORIES
# ============================================================

echo -e "${BLUE}→ Configuring APT Repositories...${RESET}"

CODENAME=$(lsb_release -c | awk '{print $2}')

if [[ "$CODENAME" == "bookworm" || "$CODENAME" == "trixie" ]]; then
    echo -e "${BLUE}→ Setting Repositories For $CODENAME...${RESET}"

sudo tee /etc/apt/sources.list << EOF > /dev/null
deb http://deb.debian.org/debian $CODENAME contrib main non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-proposed-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-backports contrib main non-free non-free-firmware
deb http://deb.debian.org/debian-security $CODENAME-security contrib main non-free non-free-firmware

deb-src http://deb.debian.org/debian $CODENAME contrib main non-free non-free-firmware
deb-src http://deb.debian.org/debian $CODENAME-updates contrib main non-free non-free-firmware
deb-src http://deb.debian.org/debian $CODENAME-proposed-updates contrib main non-free non-free-firmware
deb-src http://deb.debian.org/debian $CODENAME-backports contrib main non-free non-free-firmware
deb-src http://deb.debian.org/debian-security $CODENAME-security contrib main non-free non-free-firmware
EOF

echo -ne "${BLUE}${LOADING[0]}  Updating Package Lists...\r"
if sudo apt update > /dev/null 2>&1; then
    echo -e "${BLUE}✔ Package Lists Updated${RESET}"
else
    echo -e "${RED}✘ Failed To Update Package Lists${RESET}"
fi
else
    echo -e "${RED}Unsupported Debian Release: $CODENAME${RESET}"
    exit 1
fi


# ============================================================
#                     PACKAGE INSTALLATION
# ============================================================

echo -e "\n${BLUE}→ Installing System Packages...${RESET}"

if [[ "$CODENAME" == "trixie" ]]; then
    EXTRA_TOOLS="fastfetch qt-style-kvantum"
elif [[ "$CODENAME" == "bookworm" ]]; then
    EXTRA_TOOLS="neofetch qt5-style-kvantum"
else
    EXTRA_TOOLS=""
fi

install_packages \
    build-essential cmake "linux-headers-$(uname -r)" python3 python3-pip \
    net-tools network-manager ffmpeg ffmpegthumbnailer tumbler libglib2.0-bin \
    webp-pixbuf-loader htop pulseaudio pulsemixer curl jq wget git gnupg2

echo -e "\n${BLUE}→ Installing Archive Tools...${RESET}"
install_packages tar p7zip zip unzip rar unrar xarchiver

echo -e "\n${BLUE}→ Installing XMonad Environment...${RESET}"
install_packages xmonad xmobar kitty

echo -e "\n${BLUE}→ Installing Mount Tools...${RESET}"
install_packages \
    xdg-utils ntfs-3g nfs-common cifs-utils lxpolkit pmount udisks2 gvfs gvfs-backends

echo -e "\n${BLUE}→ Installing Themes...${RESET}"
install_packages breeze-icon-theme papirus-icon-theme

echo -e "\n${BLUE}→ Installing Utilities...${RESET}"
install_packages \
    xrdp yad gnome-software scrot feh lxappearance qt5ct qt6ct \
    mpd mpc ncmpcpp cava simplescreenrecorder vlc \
    compton rofi mousepad nemo remmina firefox-esr

if [ -n "$EXTRA_TOOLS" ]; then
    install_packages $EXTRA_TOOLS
fi

echo -e "\n${BLUE}→ Installing ZSH & OH-MY-ZSH...${RESET}"
install_package zsh

echo -ne "${BLUE}${LOADING[0]}  Configuring ZSH As Default Shell...\r"
if sudo chsh -s $(which zsh) > /dev/null 2>&1; then
    echo -e "${BLUE}✔ ZSH Set As Default Shell${RESET}"
else
    echo -e "${RED}✘ Failed To Set ZSH As Default Shell${RESET}"
fi

echo -ne "${BLUE}${LOADING[0]}  Installing OH-MY-ZSH...\r"
if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1; then
    echo -e "${BLUE}✔ OH-MY-ZSH Installed${RESET}"
else
    echo -e "${RED}✘ Failed To Install OH-MY-ZSH${RESET}"
fi

if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.zshrc; then
cat << 'EOF' >> ~/.zshrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi

echo -e "${BLUE}✔ PATH In ~/.zshrc Is Updated${RESET}"


# ============================================================
#                     REMOVE FILE-ROLLER
# ============================================================

echo -e "\n${BLUE}→ Removing file-roller...${RESET}"
remove_package file-roller

echo -ne "${BLUE}${LOADING[0]}  Running Autoremove...\r"
if sudo apt autoremove -y > /dev/null 2>&1; then
    echo -e "${BLUE}✔ Autoremove Complete${RESET}"
else
    echo -e "${RED}✘ Autoremove Failed${RESET}"
fi


# ============================================================
#                     USER PERMISSIONS
# ============================================================

echo -e "\n${BLUE}→ Adding User Permissions...${RESET}"
if sudo usermod -aG plugdev,disk "$USER" > /dev/null 2>&1; then
    echo -e "${BLUE}✔ User Added To plugdev,disk groups${RESET}"
else
    echo -e "${RED}✘ Failed To Add User To Groups${RESET}"
fi


# ============================================================
#                     CREATE ~/.nanorc
# ============================================================

echo -e "\n${BLUE}→ Creating ~/.nanorc...${RESET}"
cat << 'EOF' > ~/.nanorc
set linenumbers
set softwrap
EOF
echo -e "${BLUE}✔ ~/.nanorc Created${RESET}"


# ============================================================
#            ORIGINAL REPO-DOWNLOAD + CONFIG MERGE
# ============================================================

echo -e "\n${BLUE}→ Downloading Configuration Files...${RESET}"

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Error: $REQUIREMENTS_FILE Not Found!${RESET}"
    exit 1
fi

mkdir -p "$CONFIG_DIR"

while IFS= read -r package || [[ -n "$package" ]]; do
    package=$(echo "$package" | xargs)
    [[ -z "$package" || "$package" == \#* ]] && continue

    REPO_URL="https://github.com/zackshdw/$package.git"
    TARGET_DIR="$CONFIG_DIR/$package"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}$package Already Downloaded, Skipping...${RESET}"
    else
        git clone "$REPO_URL" "$TARGET_DIR" > /dev/null 2>&1 &
        while kill -0 $! 2>/dev/null; do loading "Downloading $package"; done
        echo -e "${GREEN}✔${RESET} $package Downloaded                    "
    fi

done < "$REQUIREMENTS_FILE"

mkdir -p "$CONFIG_DEST_DIR"

process() {
    target_dir="$1"
    package="$2"

    mkdir -p "$target_dir"

    for file in "$package"/*; do
        [ -f "$file" ] && mv -f "$file" "$target_dir"
    done
}

cleanup() {
    for dir in "$CONFIG_DIR"/*; do
        [[ -d "$dir" && ! "$dir" =~ /.git/ ]] && rm -rf "$dir"
    done
}

echo -e "\n${BLUE}→ Processing Configuration Files...${RESET}"
for package in "$CONFIG_DIR"/*; do
    package_name=$(basename "$package")

    case "$package_name" in
        fonts) process "$HOME_DIR/.fonts" "$package" ;;
        Pictures) process "$HOME_DIR/Pictures" "$package" ;;
        zsh-themes) process "$HOME_DIR/.oh-my-zsh/themes" "$package" ;;
        *) process "$CONFIG_DEST_DIR/$package_name" "$package" ;;
    esac
    
    echo -e "${BLUE}✔ $package_name Configured${RESET}"
done


# ============================================================
#                     INSTALL GTK THEMES
# ============================================================

echo -e "\n${BLUE}→ Installing GTK Themes...${RESET}"

if [ -d "$GTK_THEMES" ]; then
    mkdir -p "$GTK_THEMES_DEST"

    for theme in "$GTK_THEMES"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            rm -rf "$GTK_THEMES_DEST/$theme_name"
            cp -r "$theme" "$GTK_THEMES_DEST"
            echo -e "${BLUE}✔ $theme_name Installed${RESET}"
        fi
    done
else
    echo -e "${YELLOW}No GTK Themes Directory Found, Skipping...${RESET}"
fi


# ============================================================
#                     SYSTEM THEMING
# ============================================================

echo -e "\n${BLUE}→ Applying System Settings...${RESET}"

echo -ne "${LOADING[0]}  Applying Dark Mode...\r"
if gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null; then
    echo -e "${BLUE}✔ Dark Mode Applied${RESET}"
else
    echo -e "${YELLOW}⚠ Could Not Apply Dark Mode${RESET}"
fi

echo -ne "${BLUE}${LOADING[0]}  Setting Default Terminal...\r"
if gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty 2>/dev/null; then
    echo -e "${BLUE}✔ Default Terminal Set To Kitty${RESET}"
else
    echo -e "${YELLOW}⚠ Could Not Set Default Terminal${RESET}"
fi


# ============================================================
#                     CLEANUP PROMPT
# ============================================================

echo -e "\n${YELLOW}Clean Up Downloaded Files? (Y/n): ${RESET}"
read -r answer
answer=${answer:-y}

case "$answer" in
    y|Y|yes|YES)
        cleanup
        echo -e "${BLUE}✔ Cleanup Complete${RESET}"
    ;;
    *)
        echo -e "${YELLOW}Skipping Cleanup. Temporary Files Kept.${RESET}"
    ;;
esac

echo -e "\n${BLUE}=============================================="
echo -e "${BLUE}            Installation Complete!${RESET}"
echo -e "${BLUE}==============================================${RESET}"