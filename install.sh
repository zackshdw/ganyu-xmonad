#!/usr/bin/env bash
set -e

# ==============
#  PATH SETTINGS
# ==============
echo "Updating PATH in ~/.bashrc..."
if ! grep -q 'export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/'"$USER"'/.local/bin"' ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# Add PATH
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin/:/sbin:/home/$USER/.local/bin"
EOF
fi

# Reload .bashrc
source ~/.bashrc

# =========================
#  PROFILE QT CONFIGURATION
# =========================
echo "Adding QT Environment Variables to ~/.profile..."

if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" ~/.profile; then
cat << 'EOF' >> ~/.profile

# QT Theming
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=Kvantum
EOF
fi

# =================
#  APT REPOSITORIES
# =================
echo "Configuring APT Repositories..."

# Get The Codename Of The Current Debian Release
CODENAME=$(lsb_release -c | awk '{print $2}')

# Check if We're Running Debian Bookworm Or Trixie
if [[ "$CODENAME" == "bookworm" || "$CODENAME" == "trixie" ]]; then
    echo "Configuring APT repositories for $CODENAME..."

    # Write The Appropriate Sources To The sources.list File
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
    echo "This Script Only Supports Debian Bookworm Or Trixie. Your System Is Running $CODENAME, Which Is Might Unsupported By This Script."
fi

# =====================
#  PACKAGE INSTALLATION
# =====================
echo "Installing Packages..."

sudo apt install -y \
xrdp yad python3 python3-pip gnome-software \
gnome-software-plugin-flatpak gnome-software-plugin-snap ffmpeg \
rxvt-unicode xsel scrot cava lxappearance qt5ct qt6ct qt-style-kvantum \
mpd mpc ncmpcpp breeze-icon-theme papirus-icon-theme simplescreenrecorder \
ffmpegthumbnailer tumbler libglib2.0-bin webp-pixbuf-loader net-tools \
cmake build-essential compton htop rofi vlc fastfetch xmonad xmobar feh \
pulseaudio pulsemixer mousepad nemo xarchiver curl jq wget git remmina \
tar p7zip zip unzip rar unrar gnupg2 linux-headers-$(uname -r) firefox-esr \
vlc xdg-utils ntfs-3g nfs-common pmount cifs-utils lxpolkit pmount \
udisks2 gvfs gvfs-backends

# =====================
#  REMOVE FILE-ROLLER
# =====================
sudo apt remove -y file-roller
sudo apt autoremove -y

# =================
#  USER PERMISSIONS
# =================
echo "Adding $USER To Groups..."
sudo usermod -aG plugdev,disk "$USER"

# =====================
#  POWER MANAGEMENT OFF
# =====================
#echo "Disabling Sleep & Display Power Saving..."
#xset -dpms
#xset -s off
#xset -s noblank

# Disable Systemd Suspend
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ========
#  THEMING
# ========
echo "Applying Dark Mode..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

# ================================
# Create Blue-Themed ~/.Xresources
# ================================
echo "Writing .Xresources..."
cat << 'EOF' > ~/.Xresources
!! Colorscheme - Blue Theme

! special
*.foreground: #c0d6e4
*.background: #0f1b26
*.cursorColor: #a0c4e8

! black
*.color0: #1b2833
*.color8: #3b4f63

! red
*.color1: #d45d6e
*.color9: #ff7f91

! greenred
*.color2: #ffffff
*.color10: #4ec5d2

! yellow
*.color3: #7aaef7
*.color11: #a0cfff

! blue
*.color4: #3d85c6
*.color12: #5aa0f2

! magenta
*.color5: #7b6ff1
*.color13: #9a87ff

! cyan
*.color6: #34a0a4
*.color14: #50d6d9

! white
*.color7: #b8cce0
*.color15: #eaf4ff


!! URxvt Appearance
URxvt.font: xft:Iosevka Nerd Font Mono:style=Regular:size=9
URxvt.boldFont: xft:Iosevka Nerd Font Mono:style=Bold:size=9
URxvt.italicFont: -misc-fixed-*-*-*-*-12-*-*-*-*-*-*-*
URxvt.boldItalicfont: -misc-fixed-*-*-*-*-12-*-*-*-*-*-*
URxvt.letterSpace: 0
URxvt.lineSpace: 0
URxvt.geometry: 92x24
URxvt.internalBorder: 4
URxvt.cursorBlink: true
URxvt.cursorUnderline: false
URxvt.saveline: 2048
URxvt.scrollBar: false
URxvt.scrollBar_right: false
URxvt.urgentOnBell: true
URxvt.iso14755: false

! REQUIRED for RGBA background
URxvt.depth: 32
URxvt.background: rgba:0000/0000/0200/c800

!! Navigation Keybinds
URxvt.keysym.Shift-Up: command:\033]720;1\007
URxvt.keysym.Shift-Down: command:\033]721;1\007
URxvt.keysym.Control-Up: \033[1;5A
URxvt.keysym.Control-Down: \033[1;5B
URxvt.keysym.Control-Right: \033[1;5C
URxvt.keysym.Control-Left: \033[1;5D

!! Clipboard & Extensions
URxvt.perl-ext-common: default,clipboard,url-select,keyboard-select
URxvt.copyCommand: xclip -i -selection clipboard
URxvt.pasteCommand: xclip -o -selection clipboard
URxvt.keysym.M-c: perl:clipboard:copy
URxvt.keysym.M-v: perl:clipboard:paste
URxvt.keysym.M-C-v: perl:clipboard:paste_escaped
URxvt.keysym.M-Escape: perl:keyboard-select:activate
URxvt.keysym.M-s: perl:keyboard-select:search
URxvt.keysym.M-u: perl:url-select:select_next

URxvt.urlLauncher: firefox
URxvt.underlineURLs: true
URxvt.urlButton: 1
EOF

# ================
# Create ~/.nanorc
# ================
echo "Writing .nanorc..."
cat << 'EOF' > ~/.nanorc
set linenumbers
set mouse
set softwrap
EOF

# ==================
# Move Items To HOME
# ==================
echo "Moving Files To $HOME ..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_name="$(basename "${BASH_SOURCE[0]}")"
exclusions=( ".git" "$script_name" "LICENSE" )
timestamp=$(date +%s)

shopt -s dotglob
for src in "$SCRIPT_DIR"/*; do
	[ -e "$src" ] || continue
	name="$(basename "$src")"
	skip=false
	for ex in "${exclusions[@]}"; do
		if [ "$name" = "$ex" ]; then
			skip=true
			break
		fi
	done
	if [ "$skip" = true ]; then
		echo "  - Skipping $name"
		continue
	fi
	dest="$HOME/$name"
	if [ -e "$dest" ]; then
		backup="${dest}.backup.${timestamp}"
		echo "  - Backing Up Existing ${dest} -> ${backup}"
		mv "$dest" "$backup" || { echo "Failed To Backup $dest"; exit 1; }
	fi
	echo "  - Moving $src -> $dest"
	mv "$src" "$dest" || { echo "Failed To Move $src"; exit 1; }
done
shopt -u dotglob

echo "Done!"
