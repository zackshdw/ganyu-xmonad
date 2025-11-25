#!/bin/bash
set -e

BLUE="\e[34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

REQUIREMENTS_FILE="requirements.txt"
GTK_THEMES="$(pwd)/themes/gtk"
GTK_THEMES_DEST="$HOME/.themes"
CONFIG_DIR="$(pwd)/temp"
CONFIG_DEST_DIR="$HOME/.config"
HOME_DIR="$HOME"

LOADING=("/" "|" "\\" "-")
LOADING_INDEX=0
LOADING_MAX=4
SLEEP_INTERVAL=0.1 

loading() {
    echo -ne "${LOADING[$LOADING_INDEX]}  Downloading... $1 \r"
    ((LOADING_INDEX=(LOADING_INDEX+1)%LOADING_MAX))
    sleep $SLEEP_INTERVAL  
}

echo -e "${BLUE}=============================================="
echo -e "${BLUE}         Ganyu Xmonad  Debian Installer"
echo -e "${BLUE}==============================================${RESET}"


# ============================================================
#                     PATH CONFIGURATION
# ============================================================
echo -e "${BLUE}→ Updating PATH In ~/.bashrc...${RESET}"

if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi

source ~/.bashrc


# ============================================================
#                     QT PROFILE CONFIG
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
#                     APT REPOSITORIES
# ============================================================
echo -e "${BLUE}→ Configuring APT Repositories...${RESET}"

CODENAME=$(lsb_release -c | awk '{print $2}')

if [[ "$CODENAME" == "bookworm" || "$CODENAME" == "trixie" ]]; then
    echo -e "${BLUE}→ Setting Repositories For $CODENAME...${RESET}"

sudo tee /etc/apt/sources.list << EOF
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

sudo apt update
else
    echo -e "${RED}Unsupported Debian Release: $CODENAME${RESET}"
fi


# ============================================================
#                     PACKAGE INSTALLATION
# ============================================================
echo -e "${BLUE}→ Installing System Packages...${RESET}"

if [[ "$CODENAME" == "trixie" ]]; then
    echo -e "${BLUE}→ Installing fastfetch (Trixie)...${RESET}"
    EXTRA_TOOLS="fastfetch qt-style-kvantum"
elif [[ "$CODENAME" == "bookworm" ]]; then
    echo -e "${BLUE}→ Installing neofetch (Bookworm)...${RESET}"
    EXTRA_TOOLS="neofetch qt5-style-kvantum"
else
    EXTRA_TOOLS=""
fi

sudo apt install -y \
build-essential cmake linux-headers-$(uname -r) python3 python3-pip \
net-tools network-manager ffmpeg ffmpegthumbnailer tumbler libglib2.0-bin \
webp-pixbuf-loader htop pulseaudio pulsemixer curl jq wget git gnupg2

echo -e "${BLUE}→ Installing Archive Tools...${RESET}"
sudo apt install -y tar p7zip zip unzip rar unrar xarchiver

echo -e "${BLUE}→ Installing XMonad Environment...${RESET}"
sudo apt install -y xmonad xmobar kitty

echo -e "${BLUE}→ Installing Mount Tools...${RESET}"
sudo apt install -y \
xdg-utils ntfs-3g nfs-common cifs-utils lxpolkit pmount udisks2 gvfs gvfs-backends

echo -e "${BLUE}→ Installing Themes...${RESET}"
sudo apt install -y \
breeze-icon-theme papirus-icon-theme

echo -e "${BLUE}→ Installing Utilities...${RESET}"
sudo apt install -y \
xrdp yad gnome-software scrot feh lxappearance qt5ct qt6ct \
mpd mpc ncmpcpp cava simplescreenrecorder vlc \
compton rofi mousepad nemo remmina firefox-esr $EXTRA_TOOLS

echo -e "${BLUE}→ Installing ZSH & OH-MY-ZSH...${RESET}"
sudo apt install -y zsh
sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo -e "${BLUE}→ Updating PATH In ~/.zshrc...${RESET}"

if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.zshrc; then
cat << 'EOF' >> ~/.zshrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi


# ============================================================
#                     REMOVE FILE-ROLLER
# ============================================================
echo -e "${BLUE}→ Removing file-roller...${RESET}"
sudo apt remove -y file-roller
sudo apt autoremove -y


# ============================================================
#                     USER PERMISSIONS
# ============================================================
echo -e "${BLUE}→ Adding User Permissions...${RESET}"
sudo usermod -aG plugdev,disk "$USER"


# ============================================================
#                     CREATE ~/.nanorc
# ============================================================
echo -e "${BLUE}→ Creating ~/.nanorc...${RESET}"
cat << 'EOF' > ~/.nanorc
set linenumbers
set softwrap
EOF


# ============================================================
#            ORIGINAL REPO-DOWNLOAD + CONFIG MERGE
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
        while kill -0 $! 2>/dev/null; do loading "$package"; done

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
#                     INSTALL GTK THEMES
# ============================================================
if [ -d "$GTK_THEMES" ]; then

    mkdir -p "$GTK_THEMES_DEST"

    for theme in "$GTK_THEMES"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            echo -e "${BLUE}→ Installing $theme_name${RESET} GTK Themes..."
            rm -rf "$GTK_THEMES_DEST/$theme_name"
            cp -r "$theme" "$GTK_THEMES_DEST"
        fi
    done

    echo -e "${BLUE}✔ GTK Themes Installed${RESET}"
fi


# ============================================================
#                     SYSTEM THEMING
# ============================================================
echo -e "${BLUE}→ Applying Dark Mode...${RESET}"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

echo -e "${BLUE}→ Setting Default Terminal To Kitty...${RESET}"
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty || true


# ============================================================
#                     CLEANUP PROMPT
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
