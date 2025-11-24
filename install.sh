#!/bin/bash

BLUE="\e[34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

REQUIREMENTS_FILE="requirements.txt"
CONFIG_DIR="$(pwd)/config"
CONFIG_DEST_DIR="$HOME/.config"
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

if [ ! -d "$CONFIG_DEST_DIR" ]; then
    mkdir -p "$CONFIG_DEST_DIR"
fi

process() {
    target_dir="$1"
    package="$2" 
    
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    
    for file in "$package"/*; do
        if [ -f "$file" ]; then
            mv -f "$file" "$target_dir"
        fi
    done
}

cleanup() {
    for dir in "$CONFIG_DIR"/*; do
        if [[ -d "$dir" && ! "$dir" =~ /.git/ ]]; then
            rm -rf "$dir"
        fi
    done
}

for package in "$CONFIG_DIR"/*; do
    package_name=$(basename "$package")
    
    if [[ "$package_name" == "fonts" ]]; then
        process "$HOME_DIR/.fonts" "$package"
    
    elif [[ "$package_name" == "Pictures" ]]; then
        process "$HOME_DIR/Pictures" "$package"
    
    elif [[ "$package_name" == "zsh-themes" ]]; then
        process "$HOME_DIR/.oh-my-zsh/themes" "$package"
    
    else
        process "$CONFIG_DEST_DIR/$package_name" "$package"
    fi
done

cleanup

echo -e "${BLUE}=============================================="
echo -e "${BLUE}Installation Complete!${RESET}"
echo -e "${BLUE}==============================================${RESET}"
