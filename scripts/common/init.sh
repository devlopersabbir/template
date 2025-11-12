#!/usr/bin/env bash
set -euo pipefail

# Check prerequisites
source "${SCRIPT_DIR}/checks/prerequires.sh"
prerequirements

# Check if package.json exists
source "${SCRIPT_DIR}/checks/package.sh"

# Collect user input - this function will export too many thing like
# DOCKER_USERNAME SE_DOCKER_PASSWORD EMAIL VPS_HOST VPS_USER VPS_SSH_PRIVATE_KEY SE_GIT_TOKEN PORT DOMAIN
source "${SCRIPT_DIR}/core/stdio.sh"
takeInitialInput