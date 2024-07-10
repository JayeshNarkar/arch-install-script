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

    echo -e "Do you wish to create a new user? (for yourself if you didnt already create one) (y/n) "
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
                    echo -e "\nNow lets set a password for the user"
                    passwd ${user_name}
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

for index in `seq $starting_index 1`; do
    update_status $index
    function${index} 
done 