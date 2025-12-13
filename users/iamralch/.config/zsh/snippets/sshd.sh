#!/bin/bash -e

# ==============================================================================
# SSH Authentication and Tunneling Utilities
# ==============================================================================
# Shell functions for managing SSH authentication using 1Password and creating
# SSH tunnels for development purposes. Features interactive UI with progress
# indicators and structured logging for enhanced user experience.
#
# Dependencies:
#   - op: 1Password CLI tool
#   - ssh: OpenSSH client
#   - gum: Charm CLI styling and interaction tool
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
#   - GITHUB_TOKEN: GitHub personal access token
#
# Security Features:
#   - Temporary files are created with 600 permissions
#   - SSH keys are automatically cleaned up after loading
#   - Keys expire after specified time period
#   - Secrets are loaded into temporary config file with actual values
#   - 1Password CLI handles secure secret retrieval
#   - Environment variables are exported directly to current shell
#
# User Experience Features:
#   - Interactive progress indicators using gum spinners
#   - Structured logging with appropriate levels (info/warn/error)
#   - Profile selection feedback with visual confirmation
#   - Context-aware error messages with troubleshooting hints
#   - Clean success reporting with operation summaries
#
# Example:
#   ssh-auth                           # Load personal SSH key for 1 hour
#   ssh-auth 30m                       # Load personal SSH key for 30 minutes
#   ssh-auth --profile work            # Load work SSH key
#   ssh-auth --profile work -e 8h      # Load work SSH key for 8 hours
# ------------------------------------------------------------------------------
ssh-auth() {
	# Vault Information
	local vault_name="Private"
	local vault_account="my.1password.com"
	local vault_item_id="vxzzdak7qtvnts2rjwwvpcall4"
	local key_expiration="${1:-"1h"}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-p | --profile)
			case "$2" in
			work)
				vault_name="Employee"
				vault_account="team-em.1password.com"
				vault_item_id="6iyzh6xbx3aq3bdgph6jxyz2t4"
				;;
			personal)
				# Already set as defaults, just show confirmation
				vault_name="Private"
				vault_account="my.1password.com"
				vault_item_id="vxzzdak7qtvnts2rjwwvpcall4"
				;;
			*)
				gum log --level error "Profile '$2' not found"
				gum log --level warn "Available profiles: work, personal"
				exit 1
				;;
			esac
			shift 2
			;;
		-e | --expiration)
			key_expiration="$2"
			shift 2
			;;
		*)
			shift
			;;
		esac
	done

	# Key Information
	key_data=$(gum spin --title "Retrieving SSH key from $vault_account..." -- \
		op item get "$vault_item_id" --account "$vault_account" --vault "$vault_name" --field "private key" --reveal | sed 's/^\"//' | sed 's/\"$//' | sed '/^[[:space:]]*$/d')

	if [[ -z "$key_data" ]]; then
		gum log --level error "Failed to retrieve SSH key from 1Password"
		gum log --level warn "Check your 1Password authentication and vault access"
		gum log --level warn "Run: op signin --account $vault_account"
		exit 1
	fi

	# Create a temporary file and ensure it's cleaned up
	key_path=$(mktemp -t ssh)
	echo "$key_data" >"$key_path"
	chmod 600 "$key_path"

	# Add the key with a timeout and delete all others first
	# ssh-add -D
	gum spin --title "Adding SSH key to agent (expires: ${key_expiration})..." -- ssh-add -t "${key_expiration}" "$key_path"

	# shellcheck disable=SC2181
	if [[ $? -ne 0 ]]; then
		gum log --level error "Failed to add SSH key to agent"
		gum log --level warn "Make sure SSH agent is running: eval \$(ssh-agent)"
		rm -f "$key_path"
		exit 1
	fi

	# Cleanup
	rm -f "$key_path"

	# Create file with environment variable exports
	config_path="$XDG_DATA_HOME/zinit/config"
	# Write the environment secrets
	_write_env_secrets "$config_path"
	# Set the correct permissions
	chmod 600 "$config_path"
	# shellcheck disable=SC1090
	source "$config_path"

	# Success messages
	gum log --level info "SSH authentication completed successfully"
	gum log --level info "SSH key loaded with ${key_expiration} expiration"
	gum log --level info "Environment secrets loaded"
}

# ------------------------------------------------------------------------------
# _read_env_secret
# ------------------------------------------------------------------------------
# Helper function to retrieve a single secret from 1Password using a spinner.
#
# Arguments:
#   $1 - The 1Password secret URI (e.g., 'op://vault/item/field')
#
# Example:
#   _read_env_secret 'op://Personal/GitHub/Secrets/GITHUB_TOKEN'
# ------------------------------------------------------------------------------
_read_env_secret() {
	gum spin --title "Retrieving secret from $1..." -- op read "$1"
}

# ------------------------------------------------------------------------------
# _write_env_secrets
# ------------------------------------------------------------------------------
# Helper function to retrieve environment secrets from 1Password and write them
# to a configuration file with actual values.
#
# This internal function is called by ssh-auth to handle the environment variable
# loading process. It retrieves API keys and tokens from 1Password Personal vault
# and writes export statements with the actual secret values to the specified file.
#
# Arguments:
#   $1 - Output file path where export statements will be written
#
# 1Password Items Required:
#   - op://Personal/GitHub/Secrets/GITHUB_TOKEN
#
# Output Format:
#   The generated file contains export statements with actual secret values:
#   export FIGMA_API_KEY="actual_figma_token_here"
#   export CONTEXT7_API_KEY="actual_context7_key_here"
#   export FIRECRAWL_API_KEY="actual_firecrawl_token_here"
#   export GH_TOKEN="actual_github_token_here"
#
# Error Handling:
#   Function will fail if any 1Password read operation fails or if the output
#   file cannot be created. Errors are handled by the calling function.
# ------------------------------------------------------------------------------
_write_env_secrets() {
	local file_path="$1"

	# Read secrets and write export statements to file
	{
		echo "export GITHUB_TOKEN=\"$(_read_env_secret 'op://Personal/GitHub/Secrets/GITHUB_TOKEN')\""
	} >"$file_path"
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
