#!/bin/bash -x

ssh-auth() {
  # Vault Information
  VAULT_NAME="Private"
  VAULT_ACCOUNT="my.1password.com"
  VAULT_ITEM_ID="vxzzdak7qtvnts2rjwwvpcall4"

  # Key Information
  KEY_DATA=$(op item get "$VAULT_ITEM_ID" --account "$VAULT_ACCOUNT" --vault "$VAULT_NAME" --field "private key" --reveal | sed 's/^"//; s/"$//' | sed '/^[[:space:]]*$/d')
  KEY_EXPIRATION="${1:-"1h"}"

  if [[ -z "$KEY_DATA" ]]; then
    echo "Failed to retrieve SSH key from 1Password"
    exit 1
  fi

  # Create a temporary file and ensure it's cleaned up
  KEY_PATH=$(mktemp)
  echo "$KEY_DATA" >"$KEY_PATH"
  chmod 600 "$KEY_PATH"

  # Add the key with a timeout and delete all others first
  ssh-add -D
  ssh-add -t "${KEY_EXPIRATION}" "$KEY_PATH"

  # Cleanup
  rm -f "$KEY_PATH"
}

ssh-tunnel() {
  ssh -p 443 -R0:localhost:"$1" qr@a.pinggy.io
}
