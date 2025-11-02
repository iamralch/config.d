#!/bin/bash -x

ssh-auth() {
  # Vault Information
  VAULT_NAME="Private"
  VAULT_ACCOUNT="my.1password.com"
  VAULT_ITEM_ID="vxzzdak7qtvnts2rjwwvpcall4"

  KEY_EXPIRATION="${1:-"1h"}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --profile)
      case "$2" in
      work)
        VAULT_ACCOUNT="team-em.1password.com"
        VAULT_ITEM_ID="6iyzh6xbx3aq3bdgph6jxyz2t4"
        ;;
      *)
        echo "Provided profile is not found"
        exti 1
        ;;
      esac
      shift 2
      ;;
    -e | --expiration)
      KEY_EXPIRATION="$2"
      shift 2
      ;;
    *)
      shift
      ;;
    esac
  done

  # Key Information
  KEY_DATA=$(op item get "$VAULT_ITEM_ID" --account "$VAULT_ACCOUNT" --vault "$VAULT_NAME" --field "private key" --reveal | sed 's/^"//; s/"$//' | sed '/^[[:space:]]*$/d')

  if [[ -z "$KEY_DATA" ]]; then
    echo "Failed to retrieve SSH key from 1Password"
    exit 1
  fi

  # Create a temporary file and ensure it's cleaned up
  KEY_PATH=$(mktemp)
  echo "$KEY_DATA" >"$KEY_PATH"
  chmod 600 "$KEY_PATH"

  # Add the key with a timeout and delete all others first
  # ssh-add -D
  ssh-add -t "${KEY_EXPIRATION}" "$KEY_PATH"

  # Cleanup
  rm -f "$KEY_PATH"
}

ssh-auth-token() {
  # shellcheck disable=SC2155
  export FIGMA_API_KEY="$(op read 'op://Personal/Figma/API Key')"
  # shellcheck disable=SC2155
  export CONTEXT7_API_KEY="$(op read 'op://Personal/Context7/API Key')"
  # shellcheck disable=SC2155
  export FIRECRAWL_API_KEY="$(op read 'op://Personal/Firecrawl/API Key')"
  # shellcheck disable=SC2155
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(op read 'op://Personal/GitHub/Secrets/Personal Access Token')"
}

ssh-tunnel() {
  ssh -p 443 -R0:localhost:"$1" qr@a.pinggy.io
}
