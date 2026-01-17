#!/bin/bash

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# Environment Secrets Configuration
# ------------------------------------------------------------------------------
# Service name for macOS Keychain storage
ENV_SECRETS_VAULT="env-secrets"
# List of environment variable names to store/retrieve from keychain
# These must match field names under op://Personal/GitHub/Secrets/
ENV_SECRETS_KEYS=(
	"op://Personal/GitHub/Secrets/GITHUB_TOKEN"
	"op://Personal/Anthropic/Secrets/CLAUDE_CODE_OAUTH_TOKEN"
)

# ------------------------------------------------------------------------------
# ssh-auth
# ------------------------------------------------------------------------------
# Authenticate SSH using keys stored in 1Password and load environment secrets.
#
# This function retrieves SSH private keys from 1Password vaults, adds them to
# the SSH agent with configurable expiration times, and stores various API keys
# and secrets in macOS Keychain for secure retrieval.
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
#   - GITHUB_TOKEN: GitHub personal access token (via ENV_SECRETS_KEYS)
#
# Security Features:
#   - Temporary files are created with 600 permissions
#   - SSH keys are automatically cleaned up after loading
#   - Keys expire after specified time period
#   - Secrets are stored in macOS Keychain (encrypted at rest)
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
	# Default values
	local profile="personal"
	local key_expiration="1h"

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-p | --profile)
			profile="$2"
			shift 2
			;;
		-e | --expiration)
			key_expiration="$2"
			shift 2
			;;
		*)
			gum log --level warn "Unknown option: $1"
			shift
			;;
		esac
	done

	# Configure vault based on profile
	local vault_name vault_account vault_item_id
	case "$profile" in
	work)
		vault_name="Employee"
		vault_account="team-em.1password.com"
		vault_item_id="6iyzh6xbx3aq3bdgph6jxyz2t4"
		;;
	personal)
		vault_name="Private"
		vault_account="my.1password.com"
		vault_item_id="vxzzdak7qtvnts2rjwwvpcall4"
		;;
	*)
		gum log --level error "Profile '$profile' not found"
		gum log --level warn "Available profiles: work, personal"
		return 1
		;;
	esac

	# Key Information
	key_data=$(gum spin --title "Retrieving SSH key from $vault_account..." -- \
		op item get "$vault_item_id" --account "$vault_account" --vault "$vault_name" --field "private key" --reveal | sed 's/^\"//' | sed 's/\"$//' | sed '/^[[:space:]]*$/d')

	if [[ -z "$key_data" ]]; then
		gum log --level error "Failed to retrieve SSH key from 1Password"
		gum log --level warn "Check your 1Password authentication and vault access"
		gum log --level warn "Run: op signin --account $vault_account"
		return 1
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
		return 1
	fi

	# Cleanup
	rm -f "$key_path"

	# Store environment secrets in macOS Keychain
	_write_env_secrets
	# Load secrets into current shell
	_export_env_secrets

	# Success messages
	gum log --level info "SSH authentication completed successfully"
	gum log --level info "SSH key loaded with ${key_expiration} expiration"
	gum log --level info "Environment secrets stored in Keychain"
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
# _export_env_secrets
# ------------------------------------------------------------------------------
# Export environment secrets from macOS Keychain into the current shell.
#
# This function retrieves secrets that were previously stored by ssh-auth
# from the macOS Keychain and exports them as environment variables.
#
# The secrets are stored under the service name defined in ENV_SECRETS_SERVICE
# with account names matching the environment variable names in ENV_SECRETS_KEYS.
#
# If no secrets are found (e.g., ssh-auth hasn't been run yet), a warning
# message is printed to stderr, but the function continues silently.
#
# Example:
#   _export_env_secrets    # Load all configured secrets from keychain
# ------------------------------------------------------------------------------
_export_env_secrets() {
	local loaded=0

	local name
	local value
	# Load each secret from Keychain and export as env var
	for key in "${ENV_SECRETS_KEYS[@]}"; do
		name=$(basename "$key")
		if value=$(security find-generic-password -s "$ENV_SECRETS_VAULT" -a "$name" -w 2>/dev/null); then
			export "$name=$value"
			((loaded++))
		fi
	done

	if [[ $loaded -eq 0 ]]; then
		gum log --level warn "No environment secrets found in Keychain. Run 'ssh-auth' to load them."
	fi
}

# ------------------------------------------------------------------------------
# _write_env_secrets
# ------------------------------------------------------------------------------
# Helper function to retrieve environment secrets from 1Password and store them
# in macOS Keychain.
#
# This internal function is called by ssh-auth to handle the environment variable
# storage process. It retrieves API keys and tokens from 1Password Personal vault
# and stores them in macOS Keychain under the ENV_SECRETS_SERVICE service name.
#
# The function iterates over ENV_SECRETS_KEYS array and for each key:
#   1. Reads the secret from 1Password at op://Personal/GitHub/Secrets/<key>
#   2. Stores it in Keychain with -U flag (update if exists, create if not)
#
# 1Password Items Required:
#   - op://Personal/GitHub/Secrets/<ENV_VAR_NAME> for each key in ENV_SECRETS_KEYS
#
# Error Handling:
#   Function will fail if any 1Password read operation fails or if the keychain
#   operation fails. Errors are handled by the calling function.
# ------------------------------------------------------------------------------
_write_env_secrets() {
	local name
	local value
	# Write each secret to Keychain
	for key in "${ENV_SECRETS_KEYS[@]}"; do
		name=$(basename "$key")
		value=$(_read_env_secret "$key")
		security add-generic-password -U -s "$ENV_SECRETS_VAULT" -a "$name" -w "$value"
	done
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

# ------------------------------------------------------------------------------
# ssh-docker
# ------------------------------------------------------------------------------
# Connects to a development pod via SSH.
#
# This function constructs the SSH hostname by taking the base name of the
# current working directory and appending ".devpod" to it. It then initiates
# an SSH connection to this constructed hostname.
#
# This is useful for quickly connecting to dynamically named development
# environments (e.g., cloud-based dev environments) that follow a consistent
# naming convention based on the project directory.
#
# Arguments:
#   None. The hostname is derived from the current working directory.
#
# Example:
#   # If current directory is `/Users/iamralch/Projects/my-project`
#   ssh-docker               # Connects to `my-project.devpod`
#
# Usage with dynamically created dev pods:
#   Ensure your SSH config (~/.ssh/config) or DNS settings can resolve
#   hostnames like `your-project-name.devpod` to the correct IP address
#   or SSH gateway.
# ------------------------------------------------------------------------------
ssh-docker() {
	local project_name="${1:-}"

	local project_path
	project_path="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

	if [[ -z "$project_name" ]]; then
		project_name="$(basename "$project_path")"
	fi

	local project_state
	project_state="$(devpod status --output json --silent "$project_name" | jq -r '.state')"

	case "$project_state" in
	NotFound | Stopped)
		devpod up "$project_path"
		;;
	Running)
		gum log --level info "Container '$project_name' is already running."
		;;
	*)
		gum log --level fatal "Failed to ssh '$project_name' (state: $project_state)"
		return 1
		;;
	esac

	gum log --level info "Connecting to '$project_name'..."
	# We use devpod ssh to connect to the pod
	devpod ssh "$project_name"
}
