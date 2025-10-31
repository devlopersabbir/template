#!/usr/bin/env bash
set -euo pipefail
# ----------------------------
# 📘 github-utils.sh
# Common GitHub API helper functions
# ----------------------------

source "${SCRIPT_DIR}/utils/logger.sh"

github_api() {
  echo "$1"
  echo "$2"
  local endpoint="$1"
  local token="$2:-default"

  echo "endpoint is====: $endpoint"
  echo "token is====: $token"
  if [[ -n "$token" && "$token" == ghp_* ]]; then
      log_info "🔑 Using token: ${token:0:10}****"
   else
      echo "⚠️ No token provided, using public API"
   fi


   # Check if token looks like a classic GitHub token
   if [[ -n "$token" && "$token" == ghp_* ]]; then
       curl -s -H "Authorization: token $token" "https://api.github.com/$endpoint"
    else
        curl -s "https://api.github.com/$endpoint"
    fi
}
