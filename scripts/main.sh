#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the current script (main.sh)
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "$SCRIPT_DIR"

source "${SCRIPT_DIR}/utils/logger.sh"


echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════╗
║   NestJS Zero-Downtime Deployment Setup      ║
║   🚀 Initializing your project...            ║
╚══════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# Check prerequisites
source "${SCRIPT_DIR}/checks/prerequires.sh"
prerequirements

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
    log_error "package.json not found! Are you in a NestJS project?"
    exit 1
fi

# Extract metadata
source "${SCRIPT_DIR}/utils/extractor.sh"
extract_metadata


# Collect user input - this function will export too many thing like
# DOCKER_USERNAME SE_DOCKER_PASSWORD EMAIL VPS_HOST VPS_USER VPS_SSH_PRIVATE_KEY SE_GIT_TOKEN PORT DOMAIN
source "${SCRIPT_DIR}/core/stdio.sh"
echo "before"
take_input
echo "after"

# Generate .env.production
log_info "Creating .env.production..."
source "${SCRIPT_DIR}/generator/generate-env.sh"
create_env
log_success "✅ Successfully generated: .env.production"

# extract all github information
extract_github_repo_info

# Build team JSON dynamically
if [[ -n "$contributors" ]]; then
    source "${SCRIPT_DIR}/parsers/contributor-parser.sh"
    contribruits_json "$contributors" # comes from extractor utils and extract_github_repo_info functions
fi

# Create Caddyfile if domain provided
if [[ -n "$DOMAIN" ]]; then
    log_info "Creating Caddyfile for domain: $DOMAIN"
    source "${SCRIPT_DIR}/generator/generate-caddyfile.sh"
    generate_caddyfile "$DOMAIN"
    log_success "Created Caddyfile"
fi

# # Add to .gitignore
# log_info "Updating .gitignore..."
# cat >> .gitignore <<EOF

# # Deployment files
# .env.production
# .env
# *.pem
# *.key
# *.secret
# deploy_key*
# backups/
# logs/
# EOF
# log_success ".gitignore updated"

# SETUP_CI_CD="scripts/setup-ci-cd.sh"
# # Generate GitHub Actions
# if [[ -f $SETUP_CI_CD ]]; then
#     log_info "Generating GitHub Actions & workflows..."
#     bash ./$SETUP_CI_CD
#     log_success "GitHub Actions generated"
# else
#     log_warning "$SETUP_CI_CD not found. Please Copy it from the template."
# fi

# # Generate Dockerfile
# read -p "Is Dockerfile setup required? (y/n, default: y): " IS_DOCKER
# IS_DOCKER="${IS_DOCKER:-y}"
# if [[ "$IS_DOCKER" == "y" || "$IS_DOCKER" == "Y" ]]; then
#     log_info "Generate Dockerfile"
#     GENERATE_DOCKERFILE="scripts/generate-dockerfile.sh"

#     if [[ -f $GENERATE_DOCKERFILE ]]; then
#         log_info "Generating Dockerfile..."
#         bash ./$GENERATE_DOCKERFILE
#         log_success "✅ Successfully generated: Dockerfile"
#     else
#         log_warning "$GENERATE_DOCKERFILE not found. Please Copy it from the template."
#     fi

#     # Asking for generating .dockerignore file
#     read -p "Do you want to generate .dockerignore file? (y/n, default: y): " IS_GENERATE_DOCKER_IGNORE
#     IS_GENERATE_DOCKER_IGNORE="${IS_GENERATE_DOCKER_IGNORE:-y}"
#     if [[ "$IS_GENERATE_DOCKER_IGNORE" == "y" || "${IS_GENERATE_DOCKER_IGNORE}" == "Y" ]]; then
#         log_info "Generating/updating .dockerignore file"
#         GENERATE_DOCKER_IGNORE="scripts/generate-dockerignore.sh"
#         if [[ -f $GENERATE_DOCKER_IGNORE ]]; then
#             log_info "Generating .dockerignore file"
#             bash ./$GENERATE_DOCKER_IGNORE
#         else
#             log_warning "$GENERATE_DOCKER_IGNORE not found. Please Copy it from the template."
#         fi
#     fi

# else
#     log_warning "Docker setup not required. Skipping Dockerfile generation."
# fi

# # Generate docker-compose.yaml file
# read -p "Is docker-compose.yaml setup required? (y/n, default: y): " IS_DOCKER_COMPOSE
# IS_DOCKER_COMPOSE="${IS_DOCKER_COMPOSE:-y}"
# if [[ "$IS_DOCKER_COMPOSE" == "y" || "$IS_DOCKER_COMPOSE" == "Y" ]]; then
#     log_info "Generate docker-compose file"
#     GENERATE_DOCKER_COMPSOE="scripts/generate-dockerfile.sh"

#     if [[ -f $GENERATE_DOCKER_COMPSOE ]]; then
#         log_info "Generating docker-compose..."
#         bash ./$GENERATE_DOCKER_COMPSOE
#         log_success "✅ Successfully generated: $GENERATE_DOCKER_COMPSOE"
#     else
#         log_warning "$GENERATE_DOCKER_COMPSOE not found. Please Copy it from the template."
#     fi
# else
#     log_warning "Docker compose setup not required. Skipping docker-compsoe generation."
# fi

# # Create health check endpoint reminder with members_json
# export members_json
# log_success "✅ Successfully generated: src/health.controller.ts"

# echo ""
# log_success "==================================="
# log_success "🎉 Project initialized successfully!"
# log_success "==================================="
# echo ""
# log_info "Next steps:"
# echo ""
# echo "  1. Review and update .env.production with your actual values"
# echo "  2. Add health check endpoint to your NestJS app:"
# echo "     See: src/health.controller.ts"
# echo ""
# echo "  3. Set GitHub secrets (required for CI/CD):"
# echo "     ${YELLOW}gh secret set SE_DOCKER_PASSWORD --body \"your_token\"${RESET}"
# echo "     ${YELLOW}gh secret set SE_GIT_TOKEN --body \"your_token\"${RESET}"
# echo "     ${YELLOW}gh secret set VPS_SSH_PRIVATE_KEY --body \"\$(cat ~/.ssh/id_rsa)\"${RESET}"
# echo ""
# echo "  4. Setup your VPS server:"
# echo "     ${YELLOW}ssh $VPS_USER@$VPS_HOST${RESET}"
# echo "     ${YELLOW}curl -fsSL https://get.docker.com | sh${RESET}"
# echo ""
# echo "  5. Test locally:"
# echo "     ${YELLOW}docker compose --profile prod up --build${RESET}"
# echo ""
# echo "  6. Deploy to production:"
# echo "     ${YELLOW}git add .${RESET}"
# echo "     ${YELLOW}git commit -m \"Initial deployment setup\"${RESET}"
# echo "     ${YELLOW}git push origin main${RESET}"
# echo ""
# log_info "For detailed instructions, see: DEPLOYMENT.md"
# echo ""
# log_success "Happy deploying! 🚀"
