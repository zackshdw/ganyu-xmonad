#!/bin/bash

# set -e

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Do NOT Run This Script As root Or sudo!${RESET}"
    exit 1
fi

clear

BLUE="\e[34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

REQUIREMENTS_FILE="requirements.txt"
GTK_THEMES="$(pwd)/themes/gtk"
GTK_THEMES_DEST="$HOME/.themes"
CONFIG_DIR="$(pwd)/config"
CONFIG_DEST_DIR="$HOME/.config"
HOME_DIR="$HOME"

# ============================================================
#                     SPINNER
# ============================================================
spinner() {
    local pid="$1"
    local msg="$2"
    local delay=0.1
    local spin=('/' '|' '\' '-')
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${spin[$i]} ${msg}"
        i=$(( (i+1) % 4 ))
        sleep $delay
    done
    printf "\r✔ ${msg}\n"
}

# ============================================================
#                     PACKAGE INSTALL
# ============================================================
install_pkg() {
    local pkg="$1"
    sudo apt install -y "$pkg" > /dev/null 2>&1 &
    spinner $! "Installing $pkg"
}

remove_pkg() {
    local pkg="$1"
    sudo apt remove -y "$pkg" > /dev/null 2>&1 &
    spinner $! "Removing $pkg"
}

# ============================================================
#                     HEADER
# ============================================================
echo -e "${BLUE}=============================================="
echo -e "${BLUE}         Ganyu Xmonad  Debian Installer"
echo -e "${BLUE}==============================================${RESET}"

# ============================================================
#                     PATH CONFIGURATION
# ============================================================
echo -e "${BLUE}→ Updating PATH In ~/.bashrc...${RESET}"
if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.bashrc; then
cat << EOF >> ~/.bashrc

# Add PATH
export PATH="\$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi
source ~/.bashrc

# ============================================================
#                     QT PROFILE CONFIG
# ============================================================
echo -e "${BLUE}→ Adding QT Environment Variables To ~/.profile...${RESET}"
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" ~/.profile; then
cat << EOF >> ~/.profile

# QT Theming
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=Kvantum
EOF
fi

# ============================================================
#                     APT REPOSITORIES
# ============================================================
echo -e "${BLUE}→ Configuring APT Repositories...${RESET}"
CODENAME=$(lsb_release -c | awk '{print $2}')

if [[ "$CODENAME" == "bookworm" || "$CODENAME" == "trixie" ]]; then
echo -e "${BLUE}→ Setting Repositories For $CODENAME...${RESET}"

export SUDO_PROMPT=$'\e[34m→ Enter Your Password: \e[0m'
sudo -p "$SUDO_PROMPT" true || exit 1

sudo tee /etc/apt/sources.list > /dev/null << EOF
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

sudo apt update > /dev/null 2>&1 &
spinner $! "Updating APT"

else
    echo -e "${RED}Unsupported Debian Release: $CODENAME${RESET}"
    exit 1
fi

# ============================================================
#                     PACKAGE INSTALLATION
# ============================================================
if [[ "$CODENAME" == "trixie" ]]; then
    EXTRA_TOOLS=(fastfetch qt-style-kvantum)
elif [[ "$CODENAME" == "bookworm" ]]; then
    EXTRA_TOOLS=(neofetch qt5-style-kvantum)
else
    EXTRA_TOOLS=()
fi

SYSTEM_PACKAGES=(
    build-essential cmake linux-headers-$(uname -r) python3 python3-pip
    net-tools network-manager ffmpeg ffmpegthumbnailer tumbler libglib2.0-bin
    webp-pixbuf-loader htop pulseaudio pulsemixer curl jq wget git gnupg2
    xserver-xorg xserver-xorg-input-libinput ranger
)

ARCHIVE_TOOLS=(tar p7zip zip unzip rar unrar xarchiver)
XMONAD_ENV=(xmonad xmobar kitty)
MOUNT_TOOLS=(xdg-utils ntfs-3g nfs-common cifs-utils lxpolkit pmount udisks2 gvfs gvfs-backends gparted)
THEMES=(breeze-icon-theme papirus-icon-theme)
UTILITIES=(xrdp yad gthumb scrot feh lxappearance qt5ct qt6ct mpd mpc ncmpcpp cava simplescreenrecorder vlc compton rofi mousepad nemo remmina firefox-esr "${EXTRA_TOOLS[@]}")

echo -e "${BLUE}→ Installing System Packages...${RESET}"
for pkg in "${SYSTEM_PACKAGES[@]}"; do install_pkg "$pkg"; done

echo -e "${BLUE}→ Installing Archive Tools...${RESET}"
for pkg in "${ARCHIVE_TOOLS[@]}"; do install_pkg "$pkg"; done

echo -e "${BLUE}→ Installing XMonad Environment...${RESET}"
for pkg in "${XMONAD_ENV[@]}"; do install_pkg "$pkg"; done

echo -e "${BLUE}→ Installing Mount Tools...${RESET}"
for pkg in "${MOUNT_TOOLS[@]}"; do install_pkg "$pkg"; done

echo -e "${BLUE}→ Installing Themes...${RESET}"
for pkg in "${THEMES[@]}"; do install_pkg "$pkg"; done

echo -e "${BLUE}→ Installing Utilities...${RESET}"
for pkg in "${UTILITIES[@]}"; do install_pkg "$pkg"; done

# ============================================================
#                     REMOVE FILE-ROLLER
# ============================================================
echo -e "${BLUE}→ Removing file-roller...${RESET}"
remove_pkg "file-roller"

# ============================================================
#                     ZSH & OH-MY-ZSH
# ============================================================
echo -e "${BLUE}→ Installing ZSH & OH-MY-ZSH...${RESET}"
install_pkg "zsh"
sudo chsh -s /usr/bin/zsh "$USER"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}→ Installing OH-MY-ZSH...${RESET}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /tmp/oh-my-zsh-install.log 2>&1
else
    echo -e "${YELLOW}→ OH-MY-ZSH Already Installed, Skipping...${RESET}"
fi

ZSHRC="$HOME/.zshrc"
NEW_PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/$USER/.local/bin"
NEW_THEME="ganyu"

sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$NEW_THEME\"/" "$ZSHRC"

if grep -q '^# export PATH=' "$ZSHRC"; then
    sed -i "s|^# export PATH=.*|export PATH=\"$NEW_PATH\"|" "$ZSHRC"

elif ! grep -q '^export PATH=' "$ZSHRC"; then
    cat << EOF >> "$ZSHRC"

# Add PATH
export PATH="$NEW_PATH"
EOF
fi

# ============================================================
#                        INSTALL LSD
# ============================================================
echo -e "${BLUE}→ Installing LSD (ls Replacement)...${RESET}"

if ! command -v lsd >/dev/null 2>&1; then
    curl -sS https://webi.sh/lsd | sh > /tmp/lsd-install.log 2>&1 &
    spinner $! "Installing lsd..."

    if [ -f "$HOME/.config/envman/PATH.env" ]; then
        source "$HOME/.config/envman/PATH.env"
    fi
else
    echo -e "${YELLOW}✔ lsd Already Installed, Skipping...${RESET}"
fi

if ! grep -q "alias ls=lsd" ~/.zshrc; then
cat << 'EOF' >> ~/.zshrc

# LSD Aliases
alias ls='lsd'
alias tree='lsd --tree'
EOF
fi

if ! grep -q "alias ls=lsd" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# LSD Aliases
alias ls='lsd'
alias tree='lsd --tree'
EOF
fi

# ============================================================
#                     USER PERMISSIONS
# ============================================================
echo -e "${BLUE}→ Adding User Permissions...${RESET}"
sudo usermod -aG plugdev,disk "$USER"

# ============================================================
#                     CREATE ~/.nanorc
# ============================================================
echo -e "${BLUE}→ Creating ~/.nanorc...${RESET}"
cat << EOF > ~/.nanorc
set linenumbers
set softwrap
EOF

# ============================================================
#            DOWNLOAD REPOS (FULLY FIXED)
# ============================================================
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Error: $REQUIREMENTS_FILE Not Found!${RESET}"
    exit 1
fi

mkdir -p "$CONFIG_DIR"

echo -e "${BLUE}→ Downloading GitHub Config Files...${RESET}"

while IFS= read -r package || [[ -n "$package" ]]; do
    package=$(echo "$package" | xargs)

    [[ -z "$package" || "$package" == \#* ]] && continue

    REPO_URL="https://github.com/zackshdw/$package.git"
    TARGET_DIR="$CONFIG_DIR/$package"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "✔ ${YELLOW}$package Already Downloaded, Skipping...${RESET}"
    else
        git clone "$REPO_URL" "$TARGET_DIR" > /dev/null 2>&1 &
        spinner $! "Downloading $package"
    fi

done < "$REQUIREMENTS_FILE"

# ============================================================
#                 MOVE CONFIG FILES
# ============================================================
process() {
    target="$1"
    source="$2"

    mkdir -p "$target"

    for file in "$source"/*; do
        [[ -f "$file" ]] && mv -f "$file" "$target"
    done
}

cleanup() {
    rm -rf "$CONFIG_DIR"/*
}

mkdir -p "$CONFIG_DEST_DIR"

for package in "$CONFIG_DIR"/*; do
    name=$(basename "$package")

    case "$name" in
        fonts)       process "$HOME_DIR/.fonts" "$package" ;;
        Pictures)    process "$HOME_DIR/Pictures" "$package" ;;
        zsh-themes)  process "$HOME_DIR/.oh-my-zsh/themes" "$package" ;;
        *)           process "$CONFIG_DEST_DIR/$name" "$package" ;;
    esac
done

# ============================================================
#                     GTK THEMES
# ============================================================
if [ -d "$GTK_THEMES" ]; then
    mkdir -p "$GTK_THEMES_DEST"
    for theme in "$GTK_THEMES"/*; do
        if [ -d "$theme" ]; then
            name=$(basename "$theme")
            echo -e "${BLUE}→ Installing $name GTK Theme...${RESET}"
            rm -rf "$GTK_THEMES_DEST/$name"
            cp -r "$theme" "$GTK_THEMES_DEST"
        fi
    done
    echo -e "${BLUE}✔ GTK Themes Installed${RESET}"
fi

# ============================================================
#                     CLEANUP
# ============================================================
echo -ne "${YELLOW}Clean Up Downloaded Files? (Y/n): ${RESET}"
read -r answer
answer=${answer:-y}

if [[ "$answer" =~ ^[Yy]$ ]]; then
    cleanup
    echo -e "${BLUE}✔ Cleanup Complete${RESET}"
else
    echo -e "${YELLOW}✔ Skipping Cleanup${RESET}"
fi

echo -e "${BLUE}=============================================="
echo -e "${BLUE} Installation Complete!  Type startx To Start${RESET}"
echo -e "${BLUE}==============================================${RESET}"
