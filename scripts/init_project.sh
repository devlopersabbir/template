#!/usr/bin/env bash
set -euo pipefail

echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════╗
║   NestJS Zero-Downtime Deployment Setup      ║
║   🚀 Initializing your project...            ║
╚══════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# source common init file to do bellow thing
# 1. Check prerequisites
# 2. Check if package.json exists
# 3. Extract metadata from package.json
source "${SCRIPT_DIR}/common/init.sh"

echo -ne "${YELLOW}?${RESET} Do you want to generate ${BLUE}.env.production${RESET} file? (y/n): "
read -r answer

case "$answer" in
    [Yy]|[Yy][Ee][Ss])
        echo -e "${GREEN}🛠 Generating .env.production file...${RESET}"

        source "${SCRIPT_DIR}/generator/generate-env.sh"
        create_env
        ;;
    [Nn]|[Nn][Oo])
        echo -e "${YELLOW}⚠ Skipped .env.production generation.${RESET}"
        ;;
    *)
        echo -e "${RED}❌ Invalid input. Please type 'y' or 'n'.${RESET}"
        exit 1
        ;;
esac

echo "perfectly generate .env"