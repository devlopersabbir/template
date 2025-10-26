#!/usr/bin/env bash
set -euo pipefail

cat > Dockerfile <<EOF
node_modules
dist
data
logs
.git
.vscode
.vercel
.env.local
.env.local
.env.development.local
.env.test.local
.env.production.local
.pnpm-store
Dockerfile
docker-compose.yaml
generated
.env.keys
.env
.env.production
*.pem
*.key
*.secret
scripts
EOF