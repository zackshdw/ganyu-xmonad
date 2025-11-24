#!/bin/bash

BLUE="\e[34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

REQUIREMENTS_FILE="requirements.txt"
CONFIG_DIR="$(pwd)/config"
CONFIG_DEST_DIR="$(pwd)/.config"
HOME_DIR="$HOME"

LOADING=("/" "|" "\\" "-")
LOADING_INDEX=0
LOADING_MAX=4
SLEEP_INTERVAL=0.1 

show_loading() {
    echo -ne "${LOADING[$LOADING_INDEX]}  Downloading... $1 \r"
    ((LOADING_INDEX=(LOADING_INDEX+1)%LOADING_MAX))
    sleep $SLEEP_INTERVAL  
}

echo -e "${BLUE}=============================================="
echo -e "${BLUE}         Ganyu Xmonad  Debian Installer"
echo -e "${BLUE}==============================================${RESET}"

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Error: $REQUIREMENTS_FILE Not Found!${RESET}"
    exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

while IFS= read -r package || [[ -n "$package" ]]; do
    package=$(echo "$package" | xargs)
    
    if [[ -z "$package" || "$package" == \#* ]]; then
        continue
    fi

    REPO_URL="https://github.com/zackshdw/$package.git"
    TARGET_DIR="$CONFIG_DIR/$package"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}$package Already Downloaded, Skipping...${RESET}"
    else
        git clone "$REPO_URL" "$TARGET_DIR" > /dev/null 2>&1 & 

        while kill -0 $! 2>/dev/null; do 
            show_loading "$package"
        done

        if [ $? -eq 0 ]; then
            echo -e "${BLUE}✔  $package Downloaded Successfully.${RESET}"
        else
            echo -e "${RED}Error: Failed To Download $package.${RESET}"
        fi
    fi

done < "$REQUIREMENTS_FILE"

# Move files based on the package name
echo -e "${BLUE}Moving files from $CONFIG_DIR to appropriate locations...${RESET}"

if [ ! -d "$CONFIG_DEST_DIR" ]; then
    mkdir -p "$CONFIG_DEST_DIR"
fi

create_dir() {
    dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

for package in "$CONFIG_DIR"/*; do
    package_name=$(basename "$package")
    
    if [[ "$package_name" == "fonts" ]]; then
        create_dir "$HOME_DIR/.fonts"
        mv -f "$package"/* "$HOME_DIR/.fonts"
    
    elif [[ "$package_name" == "Pictures" ]]; then
        create_dir "$HOME_DIR/Pictures"
        mv -f "$package"/* "$HOME_DIR/Pictures"
    
    elif [[ "$package_name" == "zsh-theme" ]]; then
        create_dir "$HOME_DIR/.oh-my-zsh/themes"
        mv -f "$package"/* "$HOME_DIR/.oh-my-zsh/themes"
    
    else
        create_dir "$CONFIG_DEST_DIR"
        mv -f "$package" "$CONFIG_DEST_DIR"
    fi
done

rm -r "$CONFIG_DIR"

echo -e "${BLUE}=============================================="
echo -e "${BLUE}Installation Complete!${RESET}"
echo -e "${BLUE}==============================================${RESET}"
