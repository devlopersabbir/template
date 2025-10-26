#!/usr/bin/env bash
set -euo pipefail

# ================================
# Project Initialization Script
# ================================
# Quick setup script for new NestJS projects

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════╗
║   NestJS Zero-Downtime Deployment Setup      ║
║   🚀 Initializing your project...            ║
╚══════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

# Check prerequisites
log_info "Checking prerequisites..."

command -v node >/dev/null 2>&1 || { log_error "Node.js is required but not installed!"; exit 1; }
command -v docker >/dev/null 2>&1 || { log_error "Docker is required but not installed!"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { log_error "Docker Compose is required but not installed!"; exit 1; }

log_success "All prerequisites found!"

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
    log_error "package.json not found! Are you in a NestJS project?"
    exit 1
fi

# Read package name and version
PACKAGE_NAME=$(node -e "console.log(require('./package.json').name || 'my-app')")
PACKAGE_VERSION=$(node -e "console.log(require('./package.json').version || '0.0.1')")

log_info "Project: $PACKAGE_NAME"
log_info "Version: $PACKAGE_VERSION"

# Collect user input
echo ""
log_info "Please provide the following information:"
echo ""

read -p "Docker Hub Username: " DOCKER_USERNAME
read -p "Docker access token (default: empty_string): " SE_DOCKER_PASSWORD
SE_DOCKER_PASSWORD=${SE_DOCKER_PASSWORD:-empty_string}
read -p "Email: " EMAIL
read -p "VPS IP Address: " VPS_HOST
read -p "VPS User (default: root): " VPS_USER
VPS_USER=${VPS_USER:-root}
read -p "VPS Private key (default: empty_string): " VPS_SSH_PRIVATE_KEY
VPS_SSH_PRIVATE_KEY=${VPS_SSH_PRIVATE_KEY:-empty_string}
# read -p "Github acces token (default: empty_string): " SE_GIT_TOKEN
# SE_GIT_TOKEN=${SE_GIT_TOKEN:-}
read -p "Application Port (default: 5000): " PORT
PORT=${PORT:-5000}
read -p "Domain (optional, press Enter to skip): " DOMAIN

echo ""
log_warning "You'll need to set these secrets manually later:"
echo "  - Docker Hub Token (SE_DOCKER_PASSWORD)"
echo "  - GitHub Token (SE_GIT_TOKEN)"
echo "  - VPS SSH Private Key (VPS_SSH_PRIVATE_KEY)"
echo ""

# Generate .env.production
log_info "Creating .env.production..."

cat > .env.production <<EOF
# ======= Auto-generated - Don't touch ======== #
DOCKER_USERNAME=$DOCKER_USERNAME
PACKAGE_NAME=$PACKAGE_NAME
PACKAGE_VERSION=$PACKAGE_VERSION
EMAIL=$EMAIL
IMAGE_TAG=$DOCKER_USERNAME/$PACKAGE_NAME:$PACKAGE_VERSION
SE_DOCKER_PASSWORD=$SE_DOCKER_PASSWORD
SE_GIT_TOKEN="SE_GIT_TOKEN"
VPS_HOST="$VPS_HOST"
VPS_USER="$VPS_USER"
VPS_HOST_IP="$VPS_HOST"
CADDY_CONTAINER_NAME="caddy_container"
# ======= Don't touch ======== #

# ======= Application Configuration Start from here... ======== #
DATABASE_URL="postgresql://postgres:postgres@db:5432/mydb?connection_limit=10&pool_timeout=30&pgbouncer=true"
SALT_ROUND=10
PORT=$PORT

# JWT Configuration
ACCESS_TOKEN_SECRET=$(openssl rand -base64 32)
REFRESH_TOKEN_SECRET=$(openssl rand -base64 32)
ACCESS_TOKEN_EXPIREIN='30d'
REFRESH_TOKEN_EXPIREIN='30d'

# Email Configuration (update with your SMTP details)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS="your-app-password"
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMPT_FROM=$PACKAGE_NAME

# Admin Credentials
ADMIN_EMAIL=admin@example.com
ADMIN_PHONE=+1234567890
ADMIN_PASSWORD=$(openssl rand -base64 16)

# Client URLs
CLIENT_URL=http://localhost:3000
SERVER_URL=${SERVER_URL:-http://localhost:$PORT}

# Add your additional environment variables here
# STRIPE_SECRET_KEY=sk_test_
# TWILIO_ACCOUNT_SID=here..
# TWILIO_AUTH_TOKEN=here..
EOF

log_success "Created .env.production"

# ==== Extract github repository information ==== #
if [[ -f ".env.production" ]]; then
    # Export all key=value pairs to environment
    export $(grep -v '^#' .env.production | xargs)
else
    log_warning "⚠️  .env.production not found, skipping token load."
fi
#  Detect GitHub repo info from local git config
REPO_URL=$(git config --get remote.origin.url || true)
if [[ -z "$REPO_URL" ]]; then
  log_error "❌ Error: No GitHub remote.origin.url found in git config."
fi

# Normalize repo URL (handle SSH and HTTPS formats)
if [[ "$REPO_URL" =~ ^git@github\.com:(.*)\.git$ ]]; then
  GITHUB_PATH="${BASH_REMATCH[1]}"
elif [[ "$REPO_URL" =~ ^https://github\.com/(.*)\.git$ ]]; then
  GITHUB_PATH="${BASH_REMATCH[1]}"
else
  log_error "❌ Unsupported GitHub URL format: $REPO_URL"
fi
# Extract github owner and github repo
GITHUB_OWNER=$(echo "$GITHUB_PATH" | cut -d'/' -f1)
GITHUB_REPO=$(echo "$GITHUB_PATH" | cut -d'/' -f2)
log_success "📦 Repository detected: $GITHUB_OWNER/$GITHUB_REPO"

# Check GitHub Token
if [[ -z "$SE_GIT_TOKEN" ]]; then
  log_warning "⚠️  SE_GIT_TOKEN not found in .env.production — using unauthenticated API (rate-limited)."
else
  log_info "🔑 Using GitHub token from .env.production"
fi
# Define helper for API calls
github_api() {
  local endpoint="$1"
#   echo "token value: $SE_GIT_TOKEN"
#   if [[ "$SE_GIT_TOKEN" != "SE_GIT_TOKEN" ]]; then
    # # if [[ -n "$SE_GIT_TOKEN" ]]; then
    # #     curl -s -H "Authorization: token $SE_GIT_TOKEN" "https://api.github.com/$endpoint"
    # # else
    curl -s "https://api.github.com/$endpoint"
    # fi
#   fi
}
log_info "🔍 Fetching contributors from GitHub..."
response=$(github_api "repos/$GITHUB_OWNER/$GITHUB_REPO/contributors")

# Debug helper
echo "$response" | jq . || echo "$response"


contributors=$(github_api "repos/$GITHUB_OWNER/$GITHUB_REPO/contributors" | jq -r '.[].login')

# if contributors not found then display error message
if [[ -z "$contributors" ]]; then
  log_error "❌ No contributors found for $GITHUB_OWNER/$GITHUB_REPO"
fi
# Build team JSON dynamically
members_json=""
for user in $contributors; do
  user_data=$(github_api "users/$user")
  name=$(echo "$user_data" | jq -r '.name // .login')
  bio=$(echo "$user_data" | jq -r '.bio // "Contributor"')

  members_json+="
        {
            name: \"$name\",
            role: \"$bio\"
        },"
done
# Remove trailing comma safely
members_json=$(echo "$members_json" | sed '$ s/,$//')
log_success "Contributors informations extracted"

# Create Caddyfile if domain provided
if [[ -n "$DOMAIN" ]]; then
    log_info "Creating Caddyfile for domain: $DOMAIN"

    cat > Caddyfile <<EOF
$DOMAIN {
    # Reverse proxy to the live container
    reverse_proxy app_live:{$PORT} {
        # Load balancing (if scaling horizontally)
        lb_policy round_robin
        lb_try_duration 5s

        # Health checks
        health_uri /api/health
        health_interval 10s
        health_timeout 5s
        health_status 200

        # Failover settings
        fail_duration 30s
        max_fails 3
        unhealthy_status 5xx

        # Headers for proper proxying
        header_up Host {upstream_hostport}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-Port {server_port}

        # WebSocket support
        header_up Connection {>Connection}
        header_up Upgrade {>Upgrade}

        # Timeout settings
        transport http {
            dial_timeout 5s
            response_header_timeout 30s
            read_timeout 60s
            write_timeout 60s
        }
    }

    # Security headers
    header {
        # CORS headers
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With, Accept, Origin"
        Access-Control-Allow-Credentials true
        Access-Control-Max-Age 3600

        # Security headers
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin

        # Remove server identification
        -Server
        -X-Powered-By
    }
}

# Health check endpoint (accessible without domain)
:2019 {
    metrics /metrics
}
EOF
    log_success "Created Caddyfile"
fi

# Make scripts executable
if [[ -d "scripts" ]]; then
    log_info "Making scripts executable..."
    chmod +x scripts/*.sh
    log_success "Scripts are now executable"
fi

# Create directories
log_info "Creating necessary directories..."
mkdir -p backups
mkdir -p logs
log_success "Directories created"

# Add to .gitignore
log_info "Updating .gitignore..."
cat >> .gitignore <<EOF

# Deployment files
.env.production
.env
*.pem
*.key
*.secret
deploy_key*
backups/
logs/
EOF
log_success ".gitignore updated"

SETUP_CI_CD="scripts/setup-ci-cd.sh"
# Generate GitHub Actions
if [[ -f $SETUP_CI_CD ]]; then
    log_info "Generating GitHub Actions & workflows..."
    bash ./$SETUP_CI_CD
    log_success "GitHub Actions generated"
else
    log_warning "$SETUP_CI_CD not found. Please Copy it from the template."
fi

# Generate Dockerfile
read -p "Is Dockerfile setup required? (y/n, default: y): " IS_DOCKER
IS_DOCKER="${IS_DOCKER:-y}"
if [[ "$IS_DOCKER" == "y" || "$IS_DOCKER" == "Y" ]]; then
    log_info "Generate Dockerfile"
    GENERATE_DOCKERFILE="scripts/generate-dockerfile.sh"

    if [[ -f $GENERATE_DOCKERFILE ]]; then
        log_info "Generating Dockerfile..."
        bash ./$GENERATE_DOCKERFILE
        log_success "✅ Successfully generated: Dockerfile"
    else
        log_warning "$GENERATE_DOCKERFILE not found. Please Copy it from the template."
    fi

    # Asking for generating .dockerignore file
    read -p "Do you want to generate .dockerignore file? (y/n, default: y): " IS_GENERATE_DOCKER_IGNORE
    IS_GENERATE_DOCKER_IGNORE="${IS_GENERATE_DOCKER_IGNORE:-y}"
    if [[ "$IS_GENERATE_DOCKER_IGNORE" == "y" || "${IS_GENERATE_DOCKER_IGNORE}" == "Y" ]]; then
        log_info "Generating/updating .dockerignore file"
        GENERATE_DOCKER_IGNORE="scripts/generate-dockerignore.sh"
        if [[ -f $GENERATE_DOCKER_IGNORE ]]; then
            log_info "Generating .dockerignore file"
            bash ./$GENERATE_DOCKER_IGNORE
        else
            log_warning "$GENERATE_DOCKER_IGNORE not found. Please Copy it from the template."
        fi
    fi
    
else
    log_warning "Docker setup not required. Skipping Dockerfile generation."
fi

# Generate docker-compose.yaml file
read -p "Is docker-compose.yaml setup required? (y/n, default: y): " IS_DOCKER_COMPOSE
IS_DOCKER_COMPOSE="${IS_DOCKER_COMPOSE:-y}"
if [[ "$IS_DOCKER_COMPOSE" == "y" || "$IS_DOCKER_COMPOSE" == "Y" ]]; then
    log_info "Generate docker-compose file"
    GENERATE_DOCKER_COMPSOE="scripts/generate-dockerfile.sh"

    if [[ -f $GENERATE_DOCKER_COMPSOE ]]; then
        log_info "Generating docker-compose..."
        bash ./$GENERATE_DOCKER_COMPSOE
        log_success "✅ Successfully generated: $GENERATE_DOCKER_COMPSOE"
    else
        log_warning "$GENERATE_DOCKER_COMPSOE not found. Please Copy it from the template."
    fi
else
    log_warning "Docker compose setup not required. Skipping docker-compsoe generation."
fi

# Create health check endpoint reminder with members_json
export members_json
log_success "✅ Successfully generated: src/health.controller.ts"

echo ""
log_success "==================================="
log_success "🎉 Project initialized successfully!"
log_success "==================================="
echo ""
log_info "Next steps:"
echo ""
echo "  1. Review and update .env.production with your actual values"
echo "  2. Add health check endpoint to your NestJS app:"
echo "     See: src/health.controller.ts"
echo ""
echo "  3. Set GitHub secrets (required for CI/CD):"
echo "     ${YELLOW}gh secret set SE_DOCKER_PASSWORD --body \"your_token\"${RESET}"
echo "     ${YELLOW}gh secret set SE_GIT_TOKEN --body \"your_token\"${RESET}"
echo "     ${YELLOW}gh secret set VPS_SSH_PRIVATE_KEY --body \"\$(cat ~/.ssh/id_rsa)\"${RESET}"
echo ""
echo "  4. Setup your VPS server:"
echo "     ${YELLOW}ssh $VPS_USER@$VPS_HOST${RESET}"
echo "     ${YELLOW}curl -fsSL https://get.docker.com | sh${RESET}"
echo ""
echo "  5. Test locally:"
echo "     ${YELLOW}docker compose --profile prod up --build${RESET}"
echo ""
echo "  6. Deploy to production:"
echo "     ${YELLOW}git add .${RESET}"
echo "     ${YELLOW}git commit -m \"Initial deployment setup\"${RESET}"
echo "     ${YELLOW}git push origin main${RESET}"
echo ""
log_info "For detailed instructions, see: DEPLOYMENT.md"
echo ""
log_success "Happy deploying! 🚀"
