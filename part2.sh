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

function1(){
    print_seperator "Setting root password And creating user"
    echo -e "${BOLD}Time to set a new password for root\n${NORMAL}"
    passwd
    prompt_exit "Were you successful in setting the password?" "Restart the script"
    echo -e "Do you wish to create a new user? (for yourself if you didn't already create one) (y/n) "
    read answer 

    if [[ $answer == "y" || $answer == "Y" ]]; then
        while true; do
            echo -e "Enter a username: "
            read user_name
            echo -e "\nAre you sure you want the user's username to be: $user_name? (y/n)"
            read confirmation
            if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
                if useradd -m -g users -G wheel,storage,video,audio -s /bin/bash "${user_name}"; then
                    echo "User ${user_name} added successfully."
                    
                    echo -e "\nNow let's set a password for the user"
                    while ! passwd ${user_name}; do
                        echo -e "Password setup failed, please try again."
                    done
                    echo -e "\nPassword for user ${user_name} set successfully."

                    echo -e "\n\nNow, we have added this new user to the wheel group and other groups. The Wheel group allows the user to access root privileges with a sudo command. For that, we need to edit the sudoers file. Type the below command\n\nReference can be found in the repo's readme"

                    echo -e "\n\n${BOLD}%wheel ALL=(ALL:ALL) ALL${NORMAL}"
                    sleep 10
                    visudo                    
                    break
                else
                    echo "Failed to add user ${user_name}. Please try again."
                fi
            else
                echo -e "Let's try again."
            fi
        done
    fi
}

function2(){
    print_seperator "Setting up grub bootloader"
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo -e "Do you also have windows or any other OS installed on your system?(y/n) "
    read answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        sudo pacman -Sy os-prober --noconfirm
        echo -e "Uncomment the following line in the file that will be opened in vim.\nReference can be found in github repo.\n\n${BOLD}GRUB_DISABLE_OS_PROBER=false${NORMAL}\n\nAlso set the grub timeout to a more suitable time like 20 seconds. Reference can again be found in repo\n\n${BOLD}GRUB_TIMEOUT=20${NORMAL}\n"
        vim /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        echo "Skipping to next step."
    fi
}

function3(){
    print_seperator "Setting up Timezone/Region"
    echo -e "Do you wish to setup the timezone or skip it?(y to setup/n to skip) "
    read answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        while true; do
            ls /usr/share/zoneinfo/
            echo -e "Enter a region name for your timezone (for example: Asia for most Asian countries including India): "
            read outer_region
            if [ ! -d "/usr/share/zoneinfo/${outer_region}" ]; then
                echo "Invalid region. Please try again."
                continue
            fi

            ls /usr/share/zoneinfo/${outer_region}
            echo -e "Enter a city name for where your timezone is (for example: Kolkata for India): "
            read inner_region
            if [ ! -f "/usr/share/zoneinfo/${outer_region}/${inner_region}" ]; then
                echo "Invalid city. Please try again."
                continue
            fi

            ln -sf /usr/share/zoneinfo/${outer_region}/${inner_region} /etc/localtime
            hwclock --systohc
            echo "Timezone set to ${outer_region}/${inner_region}."
            break
        done
    else
        echo "Skipping to next step."
    fi
}

function4(){
    print_seperator "Setting up locale"
    while true; do
        echo -e "Uncomment ${BOLD}en_US.UTF-8${NORMAL} for english speaking users.\n\nReference can be found in github repo."
        sleep 5

        vim /etc/locale.gen
        language_op=$(locale-gen | grep done | cut -d ' ' -f 3 | sed 's/\.\.\.$//')

        if [ -z "$language_op" ]; then
            echo "Error: Failed to identify the generated locale."
            continue
        fi

        echo  "LANG=$language_op" > /etc/locale.conf
        break
    done
     echo "Locale set to $language_op successfully."
}

function5(){
    print_seperator "Setting up hosts"
    echo "archlinux" >> /etc/hostname
    echo "127.0.0.1        localhost\n::1        localhost\n127.0.1.1        archlinux.localdomain        archlinux" >> /etc/hosts
}

function6(){
    print_seperator "Enabling services"
    systemctl enable bluetooth
    systemctl enable NetworkManager    
}

function7(){
    echo -e "Do you want to install yay? (an AUR manager) (AUR=arch user repositories) (y/n) "
    read answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -R yay
    else
        echo "Skipping to next step."
    fi
}

for index in `seq $starting_index 7`; do
    update_status $index
    function${index} 
done 
