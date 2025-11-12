#!/usr/bin/env bash
set -euo pipefail


takeInitialDecision() {
    source "${SCRIPT_DIR}/helper/print.sh"
    # handle selection
    clear
    case $selected in
        0)
            echo -e "${GREEN}🔧 Initializing project for deployment...${RESET}"
            source "${SCRIPT_DIR}/init_project.sh"
            ;;
        1)
            echo -e "${GREEN}🚀 Ready to Deploying project instantly...${RESET}"
            # bash "${SCRIPT_DIR}/deploy_now.sh"
            ;;
        2)
            echo -e "${YELLOW}👋 Exiting. Have a great day!${RESET}"
            exit 0
            ;;
    esac
}