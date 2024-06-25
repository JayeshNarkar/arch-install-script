#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo -e "${GREEN}The archlinux-keyring package is fundamental to the security model of Arch Linux, ensuring that you can trust the packages you install from the official repositories.${NC}"

echo -n -e "\nDo you wish to go through with its installation? ${RED}(RECOMMENDED)${NC} (y/n): "
read answer

answer="${answer,,}"

while true; do 
    case "$answer" in 
        y | yes | "")
            echo -e "${BOLD}Installing archlinux-keyring package...${NORMAL}"
            sudo pacman -S archlinux-keyring --noconfirm
            break ;;
        n | no)
            echo -e "${BOLD}Moving forward...${NORMAL}"
            break ;;
        *)
            read -rp "Please enter 'y' or 'n': " answer ;;
    esac
done

