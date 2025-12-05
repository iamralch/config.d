#!/bin/bash -x

# ==============================================================================
# SSH Authentication and Tunneling Utilities
# ==============================================================================
# Shell functions for managing SSH authentication using 1Password and creating
# SSH tunnels for development purposes.
#
# Dependencies:
#   - op: 1Password CLI tool
#   - ssh: OpenSSH client
#   - mktemp: Temporary file creation utility
#
# Authentication:
#   Requires 1Password CLI authentication:
#   - op signin
#   - Valid 1Password account access
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/sshd.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# ssh-auth
# ------------------------------------------------------------------------------
# Authenticate SSH using keys stored in 1Password and load environment secrets.
#
# This function retrieves SSH private keys from 1Password vaults, adds them to
# the SSH agent with configurable expiration times, and loads various API keys
# and secrets into environment variables.
#
# The function supports multiple profiles (personal/work) with different
# 1Password vaults and can set custom key expiration times.
#
# Arguments:
#   $1 - Key expiration time (optional, default: "1h")
#        Valid formats: "30m", "1h", "24h", etc.
#
# Options:
#   -p, --profile PROFILE    Select profile (work|personal, default: personal)
#   -e, --expiration TIME    Set key expiration time (default: "1h")
#
# Profiles:
#   - personal: Uses my.1password.com account with Private vault
#   - work: Uses team-em.1password.com account with different vault
#
# Environment Variables Set:
#   - FIGMA_API_KEY: Figma API access token
#   - CONTEXT7_API_KEY: Context7 service API key
#   - FIRECRAWL_API_KEY: Firecrawl API access token
#   - GITHUB_PERSONAL_ACCESS_TOKEN: GitHub personal access token
#
# Security Features:
#   - Temporary files are created with 600 permissions
#   - SSH keys are automatically cleaned up after loading
#   - Keys expire after specified time period
#   - Secrets are loaded into temporary config file
#
# Example:
#   ssh-auth                           # Load personal SSH key for 1 hour
#   ssh-auth 30m                       # Load personal SSH key for 30 minutes
#   ssh-auth --profile work            # Load work SSH key
#   ssh-auth --profile work -e 8h      # Load work SSH key for 8 hours
# ------------------------------------------------------------------------------
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

	# Create file with environment variable exports
	TMP_CONFIG="${TMPDIR:-/tmp}/config"

	# Read secrets and write export statements to file
	{
		echo "export FIGMA_API_KEY=\"$(op read 'op://Personal/Figma/API Key')\""
		echo "export CONTEXT7_API_KEY=\"$(op read 'op://Personal/Context7/API Key')\""
		echo "export FIRECRAWL_API_KEY=\"$(op read 'op://Personal/Firecrawl/API Key')\""
		echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$(op read 'op://Personal/GitHub/Secrets/Personal Access Token')\""
	} >"$TMP_CONFIG"

	# shellcheck disable=SC1090
	source "$TMP_CONFIG"
}

# ------------------------------------------------------------------------------
# ssh-tunnel
# ------------------------------------------------------------------------------
# Create a reverse SSH tunnel to expose a local service to the internet.
#
# This function creates a reverse SSH tunnel using the Pinggy.io service,
# which allows you to expose local development servers, APIs, or services
# to the internet for testing, webhooks, or sharing purposes.
#
# The tunnel provides:
#   - HTTPS endpoint with automatic SSL certificate
#   - Random subdomain assignment
#   - Traffic forwarding to your local port
#   - Real-time connection logs
#
# Arguments:
#   $1 - Local port number to expose (required)
#
# Connection Details:
#   - Remote host: a.pinggy.io
#   - SSH port: 443 (works through most firewalls)
#   - Username: qr (Pinggy service account)
#   - Tunnel type: Reverse (-R flag)
#   - Auto-assigned remote port (0)
#
# Security Considerations:
#   - Exposes your local service to the public internet
#   - Use only for development and testing
#   - Consider authentication/authorization for sensitive services
#   - Tunnel session is active until SSH connection is terminated
#
# Example:
#   ssh-tunnel 3000          # Expose local port 3000 (e.g., React dev server)
#   ssh-tunnel 8080          # Expose local port 8080 (e.g., API server)
#
# Usage with Development Servers:
#   # Start your local server
#   npm start                # Usually runs on port 3000
#   
#   # In another terminal, create tunnel
#   ssh-tunnel 3000
#   
#   # Access via the provided HTTPS URL
#   # Example output: https://abc123.a.pinggy.io
# ------------------------------------------------------------------------------
ssh-tunnel() {
	ssh -p 443 -R0:localhost:"$1" qr@a.pinggy.io
}
