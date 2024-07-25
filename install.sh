#!/bin/bash

LOG_FILE="log.txt"

BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

starting_index=1

if [ -f "$LOG_FILE" ]; then
    starting_index=$(cat "$LOG_FILE")
fi

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
	    iwctl station list
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
            iwctl station "$wifi_device" connect "$wifi_ssid"
	    echo -e "\nThe setup will now artifically wait for 8 seconds. This is so wifi has time to connect."
	    sleep 8
	    ;;
	2)
            echo -e "${BOLD}Proceeding with Ethernet connection...\n${NORMAL}"
            ;;
        *)
            echo -e "${RED}Invalid option selected. Please try again.${NC}"
            ask_network_connection
            ;;
    esac
    local result
    result="$(ping -c 1 google.com | grep "1 received")"
    if [ -z "$result" ]; then 
	    echo -e "\nExiting script since you havent connected to internet. Either re-plug your ethernet and try after waiting. Or re-connect to wifi by restarting the script."
	    exit
    fi	    
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
                sudo pacman -Sy "$package_name" --noconfirm
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

prompt_skip() {
  while true; do
    echo -e "$1${NORMAL} (y/n) "
    read answer
    case $answer in
      [Yy]* ) break;;
      [Nn]* ) echo -e "\n$2"
      echo -e "${BOLD}\Skipping ahead.${NORMAL}"; return;;
      * ) echo "Please answer y or n.";;
    esac
  done
}

countdown() {
    for i in $(seq $1 -1 1); do
        echo -e "$i"
        sleep 1
    done
}

show_steps_for_making_partitions(){
    echo -e "\nThis next step requires some human intervention since identifying and creating partitions through a script is a tough task. But here are some steps to guide you through it:"
    sleep 2

    echo -e "\nStep 1. Identify the storage device you want to make the partitions on."
    sleep 2

    echo -e "\nStep 2. When prompted enter its name (nvme0n1,sda)"
    sleep 2
    
    echo -e "\nStep 3. in the menu displayed there will be a section called free space and it will be in green. If you dont see it that means you either forgot to do what was instructed in the previous step. (to free up space) Or you just selected the wrong storage device"

    sleep 2

    echo -e "\nStep 4. Create 2-3 partitions. for boot and root (and swap (optional but highly recommended))"

    sleep 2

    echo -e "\nHere are some info on the partitions and the sizes you should give them:"
    sleep 2

    echo -e "\n1. Efi/boot: 500-800M (mb is M in that menu)"
    sleep 2
    
    echo -e "\n2. Swap: 8G or 16G or however much your ram is(gb is G in that menu)"    
    sleep 2

    echo -e "\n3. Root: Rest of the remaining free space"    
    sleep 2

    echo -e "A video showing how to create these can also be found in the github repo of this script."    
    sleep 2

    echo -e "\nUse the arrow keys <- and -> to move from one option to another"
    sleep 2

    echo -e "\nStep 6. Go to the write button and press enter. Which should exit that menu and script will start running again!"
    sleep 2
}

function install_desktop_environment() {
    pacstrap -i /mnt noto-fonts noto-font-emoji ttf-dejavu ttf-font-awesome firefox --noconfirm

    while true; do
        echo "Select the desktop environment you want to install:"
        echo "1) GNOME"
        echo "2) KDE"
        echo "3) XFCE"
        read -p "Enter your choice (1-3): " choice

        case $choice in
            1)
                echo "Installing GNOME Desktop Environment."
                pacstrap -i /mnt xorg gdm gnome gnome-extra --noconfirm
                arch-chroot /mnt sudo systemctl enable gdm               
                break
                ;;
            2)
                echo "Installing KDE Plasma Desktop Environment."
                pacstrap -i /mnt plasma-workspace xorg sddm plasma-meta flatpak konsole --noconfirm
                arch-chroot /mnt sudo systemctl enable sddm
                break
                ;;
            3)
                echo "Installing XFCE Environment."
                pacstrap -i /mnt  xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm
                arch-chroot /mnt sudo systemctl enable lightdm
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
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
    prompt_exit "Have you free'd up space on one of the storage devices connected to the system?" "Go ahead and do so in your windows OS (if you are setting up a dual boot) or use the cfdisk command provided by the arch installer in the current terminal that you are in.\nAlso this arch install script will start from here again instead of starting from the start so....you're welcome!"
}

function5(){
    local answer
    echo -e "\nDo you wish to see the steps to make the partitions?(y/n) "
    read answer
     if [[ $answer == "y" || $answer == "Y" ]]; then
        show_steps_for_making_partitions
    fi

    echo -e "\nHave you already created the partitions?(y/n) "
    read answer
    if [[ $answer == "n" || $answer == "N" ]]; then
        lsblk
        sleep 1
        echo -e "\n\nWhats the name of the storage device where you wish to install arch?(nvme0n1, sda) "
        read storage_device_for_partitions
        cfdisk /dev/${storage_device_for_partitions}
    fi

    echo -e "\nDid you create the 3 partitions?(y/n) "
    read answer
     if [[ $answer == "n" || $answer == "N" ]]; then
        echo -e "Exiting script. Restart the script by typing ./install.sh. It should restart from the same step as you left"
        exit
    else
        echo -e "\Continuing..."
     fi
     
     lsblk
     echo -e "Enter the root partition (sda2, nvme0n1p3, or something) "
     read root_partition
     mkfs.ext4 /dev/${root_partition}
     mount /dev/${root_partition} /mnt

     echo -e "Enter the efi partition name (sda1, nvme0n1p2, or something): "
     read efi_partition
     mkdir /mnt/boot
     mkfs.fat -F32 /dev/${efi_partition}
     mount /dev/${efi_partition} /mnt/boot

     echo -e "Do you have a swap partition?(y/n) "
     read answer
     if [[ $answer == "y" || $answer == "Y" ]]; then
        echo -e "Enter the swap partition (sda2, nvme0n1p3, or something) "
        read swap_partition
        mkswap /dev/${swap_partition}
        swapon /dev/${swap_partition}
     fi
}

# cargo mpv bluez bluez-utils

function6(){
    print_seperator "Installing Basic packages"

    prompt_exit "\nBefore proceeding, this is a final time asking if you are sure you made all 3 partitions properly with proper types and are connected to network.\nAre you sure you wish to continue?" "Images of how your lsblk after partioning should be present in the repo. And to check your network connectivity use the command ping -c 1 google.com"

    echo -e "Do you wish to speedup your installation time using reflectors?(y/n) "
    read answer
     if [[ $answer == "y" || $answer == "Y" ]]; then
        pacman -Sy reflector --noconfirm        
        reflector --list-countries
        echo -e "\nChoose a country where you live.(case-sensitive) "
        read country
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
        reflector --verbose --country "${country}" -l 10 --sort rate --save /etc/pacman.d/mirrorlist
        cp /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.bak
        cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
     fi
     
    echo -e "Do you have intel or amd based cpu?(intel/amd) "
    read cpu_type

    if [[ $cpu_type != "intel" && $cpu_type != "amd" ]]; then
        echo "Invalid CPU type. Exiting script."
        exit 1
    fi

    pacstrap -i /mnt base base-devel linux linux-headers linux-firmware ${cpu_type}-ucode sudo git nano vim neofetch htop networkmanager cmake make gcc grub efibootmgr dosfstools mtools --noconfirm

    read -p "Do you have a Nvidia or Radeon GPU or neither? (nvidia/radeon/neither): " gpu_type

    case $gpu_type in
        [Nn]vidia)
            pacstrap -i /mnt nvidia
            ;;
        [Rr]adeon)
            pacstrap -i /mnt xf86-video-amdgpu
            ;;
        *)
            echo "Skipping GPU specific steps."
            ;;
    esac

    genfstab -U /mnt >> /mnt/etc/fstab    
}

function7(){
    print_seperator "Installing a desktop environment"

    read -p "Do you want to install a desktop environment? (y/n): " answer

     if [[ $answer == "y" || $answer == "Y" ]]; then
        install_desktop_environment
    else
        echo "Skipping to next step."
    fi
}

function8(){
    print_seperator "Changing root environments"

    mv part2.sh /mnt/

    chmod +x /mnt/part2.sh

    arch-chroot /mnt ./part2.sh
}

function9(){
    print_seperator "Unmounting all partitions"
    umount -lR /mnt
}

function10(){
    print_seperator "Rebooting system"
    arch-chroot /mnt rm part2.sh 
    arch-chroot /mnt rm log.txt
    countdown 5
    reboot now 
}

for index in `seq $starting_index 10`; do
    update_status $index
    function${index} 
done 

