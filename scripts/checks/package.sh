#!/usr/bin/env bash
set -euo pipefail

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
    log_error "package.json not found! Are you in a NestJS project?"
    exit 1
fi

# Extract metadata
source "${SCRIPT_DIR}/utils/extract-metadata.sh"
extract_metadata