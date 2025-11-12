#!/usr/bin/env bash
set -euo pipefail

export options=(
    "Initialize project for deployment"
    "Instantly deploy project"
    "Exit"
)

print_menu() {
    clear
    echo -e "${BLUE}==========================================${RESET}"
    echo -e "${YELLOW}🚀 Project Deployment Assistant${RESET}"
    echo -e "${BLUE}==========================================${RESET}\n"

    for i in "${!options[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo -e "${GREEN}> ${options[$i]}${RESET}"
        else
            echo "  ${options[$i]}"
        fi
    done
}

# interactive loop
selected=0
print_menu

while true; do
    # Read one key press
    read -rsn1 key
    case "$key" in
        $'\x1b')
            read -rsn2 key2
            case "$key2" in
                "[A") # Up arrow
                    ((selected--))
                    ((selected < 0)) && selected=$((${#options[@]} - 1))
                    ;;
                "[B") # Down arrow
                    ((selected++))
                    ((selected >= ${#options[@]})) && selected=0
                    ;;
            esac
            ;;
        "") # Enter key
            break
            ;;
    esac
    print_menu
done

