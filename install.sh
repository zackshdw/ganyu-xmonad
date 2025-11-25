#!/bin/bash
set -e

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

# Spinner symbols
LOADING=("/" "|" "\\" "-")
LOADING_MAX=4
SLEEP_INTERVAL=0.1

# ============================================================
#                   Spinner for Git clone
# ============================================================
loading() {
    local message="$1"
    local index="$2"
    echo -ne "${LOADING[index]}  Downloading... $message \r"
    sleep $SLEEP_INTERVAL
}

# ============================================================
#                   Silent APT Wrapper
# ============================================================
silent() {
    local MSG="$1"
    local CMD="$2"

    echo -ne "${BLUE}→ $MSG...${RESET} "

    bash -c "$CMD" > /dev/null 2>&1 &
    local PID=$!

    local i=0
    while kill -0 $PID 2>/dev/null; do
        echo -ne "${LOADING[i]}  \r"
        i=$(( (i+1) % LOADING_MAX ))
        sleep $SLEEP_INTERVAL
    done

    wait $PID
    echo -e "${BLUE}✔ Done${RESET}"
}

# ============================================================
#                   Welcome Banner
# ============================================================
echo -e "${BLUE}=============================================="
echo -e "${BLUE}         Ganyu Xmonad  Debian Installer"
echo -e "${BLUE}==============================================${RESET}"

# ============================================================
#                   PATH Configuration
# ============================================================
echo -e "${BLUE}→ Updating PATH in ~/.bashrc...${RESET}"
if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi
source ~/.bashrc

# ============================================================
#                   QT Profile Config
# ============================================================
echo -e "${BLUE}→ Adding QT Environment Variables To ~/.profile...${RESET}"
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" ~/.profile; then
cat << 'EOF' >> ~/.profile

# QT Theming
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=Kvantum
EOF
fi

# ============================================================
#                   APT Repositories
# ============================================================
echo -e "${BLUE}→ Configuring APT Repositories...${RESET}"

CODENAME=$(lsb_release -c | awk '{print $2}')

if [[ "$CODENAME" == "bookworm" || "$CODENAME" == "trixie" ]]; then
    echo -e "${BLUE}→ Setting Repositories For $CODENAME...${RESET}"

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

silent "Updating APT" "sudo DEBIAN_FRONTEND=noninteractive apt update"

else
    echo -e "${RED}Unsupported Debian Release: $CODENAME${RESET}"
fi

# ============================================================
#                   Package Installation
# ============================================================
echo -e "${BLUE}→ Installing System Packages...${RESET}"

if [[ "$CODENAME" == "trixie" ]]; then
    EXTRA_TOOLS="fastfetch qt-style-kvantum"
elif [[ "$CODENAME" == "bookworm" ]]; then
    EXTRA_TOOLS="neofetch qt5-style-kvantum"
else
    EXTRA_TOOLS=""
fi

silent "Installing System Packages" "sudo DEBIAN_FRONTEND=noninteractive apt install -y \
build-essential cmake linux-headers-$(uname -r) python3 python3-pip \
net-tools network-manager ffmpeg ffmpegthumbnailer tumbler libglib2.0-bin \
webp-pixbuf-loader htop pulseaudio pulsemixer curl jq wget git gnupg2"

silent "Installing Archive Tools" "sudo DEBIAN_FRONTEND=noninteractive apt install -y tar p7zip zip unzip rar unrar xarchiver"

silent "Installing XMonad Environment" "sudo DEBIAN_FRONTEND=noninteractive apt install -y xmonad xmobar kitty"

silent "Installing Mount Tools" "sudo DEBIAN_FRONTEND=noninteractive apt install -y \
xdg-utils ntfs-3g nfs-common cifs-utils lxpolkit pmount udisks2 gvfs gvfs-backends gparted"

silent "Installing Themes" "sudo DEBIAN_FRONTEND=noninteractive apt install -y \
breeze-icon-theme papirus-icon-theme"

silent "Installing Utilities" "sudo DEBIAN_FRONTEND=noninteractive apt install -y \
xrdp yad gnome-software scrot feh lxappearance qt5ct qt6ct \
mpd mpc ncmpcpp cava simplescreenrecorder vlc \
compton rofi mousepad nemo remmina firefox-esr $EXTRA_TOOLS"

silent "Installing ZSH" "sudo DEBIAN_FRONTEND=noninteractive apt install -y zsh"

sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ============================================================
#                   Remove file-roller
# ============================================================
silent "Removing file-roller" "sudo DEBIAN_FRONTEND=noninteractive apt remove -y file-roller"
silent "Auto-removing Unnecessary Packages" "sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y"

# ============================================================
#                   User Permissions
# ============================================================
echo -e "${BLUE}→ Adding User Permissions...${RESET}"
sudo usermod -aG plugdev,disk "$USER"

# ============================================================
#                   Create ~/.nanorc
# ============================================================
echo -e "${BLUE}→ Creating ~/.nanorc...${RESET}"
cat << 'EOF' > ~/.nanorc
set linenumbers
set softwrap
EOF

# ============================================================
#                   GitHub Repo Downloads
# ============================================================
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
        PID=$!
        LOADER_INDEX=0
        while kill -0 $PID 2>/dev/null; do
            echo -ne "${LOADING[LOADER_INDEX]}  Downloading... $package \r"
            LOADER_INDEX=$(( (LOADER_INDEX+1)%LOADING_MAX ))
            sleep 0.1
        done
        echo -e "${BLUE}✔ $package Downloaded.${RESET}"
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

for package in "$CONFIG_DIR"/*; do
    package_name=$(basename "$package")

    case "$package_name" in
        fonts) process "$HOME_DIR/.fonts" "$package" ;;
        Pictures) process "$HOME_DIR/Pictures" "$package" ;;
        zsh-themes) process "$HOME_DIR/.oh-my-zsh/themes" "$package" ;;
        *) process "$CONFIG_DEST_DIR/$package_name" "$package" ;;
    esac
done

# ============================================================
#                   GTK Themes
# ============================================================
if [ -d "$GTK_THEMES" ]; then
    mkdir -p "$GTK_THEMES_DEST"
    for theme in "$GTK_THEMES"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            echo -e "${BLUE}→ Installing $theme_name GTK Themes...${RESET}"
            rm -rf "$GTK_THEMES_DEST/$theme_name"
            cp -r "$theme" "$GTK_THEMES_DEST"
        fi
    done
    echo -e "${BLUE}✔ GTK Themes Installed${RESET}"
fi

# ============================================================
#                   System Theming
# ============================================================
echo -e "${BLUE}→ Applying Dark Mode...${RESET}"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

echo -e "${BLUE}→ Setting Default Terminal To Kitty...${RESET}"
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty || true

# ============================================================
#                   Cleanup Prompt
# ============================================================
echo -ne "${YELLOW}Clean Up Downloaded Files? (Y/n): ${RESET}"
read -r answer
answer=${answer:-y}

case "$answer" in
    y|Y|yes|YES)
        cleanup
        echo -e "${BLUE}✔ Cleanup Complete.${RESET}"
    ;;
    *)
        echo -e "${YELLOW}Skipping Cleanup. Temporary Files Kept.${RESET}"
    ;;
esac

echo -e "${BLUE}=============================================="
echo -e "${BLUE}            Installation Complete!${RESET}"
echo -e "${BLUE}==============================================${RESET}"
