#!/bin/bash

BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo -e "${BOLD}${GREEN}Welcome to Jayesh's Arch Linux install script!${NORMAL}${NC}\n"

ask_network_connection() {
    echo -e "${BOLD}${BLUE}Network Connection Setup${NORMAL}${NC}"
    echo -e "Do you need to connect to WiFi, or are you already connected via Ethernet?"
    echo -e "1) Connect to WiFi using iwctl"
    echo -e "2) Already connected via Ethernet"
    read -p "Please choose an option (1/2): " network_choice

    case $network_choice in
        1)
            echo -e "${BOLD}Starting WiFi connection setup...${NORMAL}"
            echo -e "Listing available WiFi devices..."
            iwctl device list
            read -p "Enter the device name you wish to connect with (e.g., wlan0): " wifi_device
            echo -e "Scanning for WiFi networks..."
            iwctl station $wifi_device scan
            echo -e "Listing available networks..."
            iwctl station $wifi_device get-networks
            read -p "Enter the SSID of the WiFi network you wish to connect to: " wifi_ssid
            iwctl --passphrase prompt station $wifi_device connect "$wifi_ssid"
            ;;
        2)
            echo -e "${BOLD}Proceeding with Ethernet connection...\n${NORMAL}"
            ;;
        *)
            echo -e "${RED}Invalid option selected. Please try again.${NC}"
            ask_network_connection
            ;;
    esac
}

prompt_installation() {
    local package_name=$1
    local package_description=$2
    local package_necessity=${3^^}    
    local necessity_color=$NC 

    if [[ $package_necessity == "RECOMMENDED" ]]; then
        necessity_color=$RED
    elif [[ $package_necessity == "OPTIONAL" ]]; then
        necessity_color=$BLUE
    fi
    
    echo -e "${BLUE}Package Name:${NC} ${package_name}"
    
    echo -e "\n${GREEN}$package_description${NC}"

    echo -n -e "\nDo you wish to go through with its installation? ${necessity_color}(${package_necessity})${NC} (y/n): "
    local answer
    read answer
    answer="${answer,,}"

    while true; do 
        case "$answer" in 
            y | yes | "")
                echo -e "${BOLD}Installing $package_name package...${NORMAL}"
                sudo pacman -S "$package_name" --noconfirm
                break ;;
            n | no)
                echo -e "${BOLD}Skipping $package_name installation...${NORMAL}"
                break ;;
            *)
                read -rp "Please enter 'y' or 'n': " answer ;;
        esac
    done
}

ask_network_connection

prompt_installation "archlinux-keyring" "The archlinux-keyring package is fundamental to the security model of Arch Linux, ensuring that you can trust the packages you install from the official repositories." "recommended"


