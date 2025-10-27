#!/usr/bin/env bash
set -euo pipefail
# ----------------------------
# 📘 contributor-parser.sh
# Parse contributors from GitHub
# ----------------------------

source "${SCRIPT_DIR}/utils/logger.sh"

contribruits_json() {
  local contributors=$1

  echo "contributors: $contributors"
  members_json=""
  if [[ ! -n $contributors ]]; then
    log_error "Contributors not found from perser"
  else
    source "${SCRIPT_DIR}/plugins/github-utils.sh"
    for user in $contributors; do
      user_data=$(github_api "users/$user")
      echo "$user_data"
      name=$(echo "$user_data" | jq -r '.name // .login')
      bio=$(echo "$user_data" | jq -r '.bio // "Contributor"')

      members_json+="
            {
                name: \"$name\",
                role: \"$bio\"
            },"
    done
  fi
  
  # Remove trailing comma safely
  members_json=$(echo "$members_json" | sed '$ s/,$//')
  log_success "Contributors informations extracted"

  export members_json
}

