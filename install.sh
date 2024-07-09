#!/bin/bash

LOG_FILE="log.txt"

starting_index=1

if [ -f "$LOG_FILE" ]; then
    starting_index=$(cat "$LOG_FILE")
fi

BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

update_status() {
    echo "$1" > $LOG_FILE
}

print_seperator(){
     printf '%.0s-' {1..50}
    echo -e "\n${BLUE}$1${NORMAL}${NC}\n"
}

print_slow_message(){        
    message="$1"
    color=${2^^} 
    echo -e "${!color}"
    for word in $message; do
        echo -n "$word "  
        sleep 0.5 
    done
    echo -e "${NORMAL}${NC}\n"
}

ask_network_connection() {
    echo -e "Do you need to connect to WiFi, or are you already connected via Ethernet?"
    echo -e "1) Connect to WiFi using iwctl"
    echo -e "2) Already connected via Ethernet"
    read -p "Please choose an option (1/2): " network_choice

    case $network_choice in
        1)
            echo -e "${BOLD}Starting WiFi connection setup...${NORMAL}"
            local wifi_device
            local device_check_output
            while true; do
                read -p "Enter the device name you wish to connect with (e.g., wlan0): " wifi_device                
                device_check_output=$(iwctl station "$wifi_device" show 2>&1)
                if [[ $device_check_output == *"Device $wifi_device not found"* ]]; then
                    echo -e "${RED}Device not found. Please enter a valid device name.${NC}"
                else
                    break
                fi
            done
            echo -e "Scanning for WiFi networks..."
            iwctl station "$wifi_device" scan
            echo -e "Listing available networks..."
            iwctl station "$wifi_device" get-networks
            read -p "Enter the SSID of the WiFi network you wish to connect to: " wifi_ssid
            read -sp "Enter the WiFi password: " wifi_password
            echo
            iwctl --passphrase "$wifi_password" station "$wifi_device" connect "$wifi_ssid"
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

    echo -n -e "${BOLD}\nDo you wish to go through with its installation? ${necessity_color}(${package_necessity})${NC} (y/n): "
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
                echo -e "${BOLD}Skipping $package_name installation...${NORMAL}\n"
                break ;;
            *)
                read -rp "Please enter 'y' or 'n': " answer ;;
        esac
    done
}

prompt_exit() {
  while true; do
    echo -e "$1${NORMAL} (y/n) "
    read answer
    case $answer in
      [Yy]* ) break;;
      [Nn]* ) echo -e "\n$2"
      echo -e "${BOLD}\nExiting script.${NORMAL}"; exit;;
      * ) echo "Please answer y or n.";;
    esac
  done
}

function1(){
    print_slow_message "Welcome to Jayesh's Arch Linux install script!" "green"
}

function2(){
    print_seperator "Network Connection Setup"
    ask_network_connection
}

function3(){
    prompt_installation "archlinux-keyring" "The archlinux-keyring package is fundamental to the security model of Arch Linux, ensuring that you can trust the packages you install from the official repositories." "recommended"
}

function4(){
    print_seperator "Storage Allocation"
    prompt_exit "The minimum space required for the following types of installs is given below (feel free to free up more than that if you see fit): \n•Minimal (no desktop environment): 11 GB \n•GNOME or KDE Desktop Environment: 41 GB \n•Wayland Desktop Enviornment: 41 GB \n\nAlso do note that this does not include the swap partition size required (which is recommended to be the same size as your actual ram).\nSwap space is optional but beneficial, enhancing system performance by providing additional virtual memory when RAM is full.\n\nSo if you have 8GB ram free up 41GB (for xfce/kde/wayland) + 8GB (for swap) = 49GB\n\n${BOLD}Have you free'd up space on one of the storage devices connected to the system?" "Go ahead and do so in your windows OS (if you are setting up a dual boot) or use the cfdisk command provided by the arch installer in the current terminal that you are in.\nAlso this arch install script will start from here again instead of starting from the start so....you're welcome!"
}

for index in `seq $starting_index 4`; do
    update_status $index
    function${index} 
done 