#!/usr/bin/env bash
set -euo pipefail
# ----------------------------
# 📘 contributor-parser.sh
# Parse contributors from GitHub
# ----------------------------

source "${SCRIPT_DIR}/utils/logger.sh"

contribruits_json() {
  local contributor=$1 # here we will receive a indivisual contributor account username

  echo "contributor: $contributor"
  members_json=""
  if [[ ! -n $contributor ]]; then
    log_error "Contributor not found from perser"
  else
    source "${SCRIPT_DIR}/plugins/github-utils.sh"
    user_data=$(github_api "users/$contributor" none)
    echo "user data here: $user_data"
    name=$(echo "$user_data" | jq -r '.name // .login')
    bio=$(echo "$user_data" | jq -r '.bio // "Contributor"')

    echo "contributor name: $name"
    echo "contributor bio: $bio"
    # members_json+="
        #{
        #    name: \"$name\",
        #    role: \"$bio\"
        #},"
  fi

  # Remove trailing comma safely
  members_json=$(echo "$members_json" | sed '$ s/,$//')
  log_success "Contributors informations extracted"

  export members_json
}

