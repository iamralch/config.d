#!/bin/bash

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# HSDK Keychain Configuration
# ------------------------------------------------------------------------------
HSDK_SECRETS_VAULT="hsdk-secrets"

# ------------------------------------------------------------------------------
# _hsdk_read_env_from_keychain (private)
# ------------------------------------------------------------------------------
# Reads HSDK environment variables from macOS Keychain.
#
# Data is stored base64-encoded to handle multi-line scripts. This function
# decodes the data upon retrieval.
#
# Parameters:
#   $1 - Environment ID
#
# Output:
#   The stored environment variables script, or empty if not found.
# ------------------------------------------------------------------------------
_hsdk_read_env_from_keychain() {
	local env_id="$1"
	local b64_data
	b64_data=$(security find-generic-password -s "$HSDK_SECRETS_VAULT" -a "$env_id" -w 2>/dev/null)
	if [[ -n "$b64_data" ]]; then
		printf "%s" "$b64_data" | base64 --decode
	fi
}

# ------------------------------------------------------------------------------
# _hsdk_write_env_to_keychain (private)
# ------------------------------------------------------------------------------
# Writes HSDK environment variables to macOS Keychain.
#
# Data is base64-encoded before storage to ensure that newlines and special
# characters are preserved correctly.
#
# Parameters:
#   $1 - Environment ID
#   $2 - The environment variables script to store
# ------------------------------------------------------------------------------
_hsdk_write_env_to_keychain() {
	local env_id="$1"
	local env_data="$2"
	local b64_data
	b64_data=$(echo -n "$env_data" | base64)
	security add-generic-password -U -s "$HSDK_SECRETS_VAULT" -a "$env_id" -w "$b64_data"
}

# ------------------------------------------------------------------------------
# _export_hsdk_secrets (private)
# ------------------------------------------------------------------------------
# Loads HSDK environment variables and aliases for an already configured shell.
#
# This function is intended to be used in shell initialization files (e.g.,
# .zshrc, .bashrc) to quickly restore an HSDK environment based on the
# `AWS_PROFILE` variable. It performs two main actions:
#   1. Reads cached environment variables (like HSDK tokens, AWS credentials)
#      from the macOS Keychain using `_hsdk_read_env_from_keychain`.
#   2. Sources the HSDK alias tools, which provide convenient short commands
#      for common tasks within the HSDK environment.
#
# This function should be called after `AWS_PROFILE` has been established,
# typically in a new shell that was spawned for a specific environment.
#
# Globals:
#   - AWS_PROFILE: The AWS profile name, which is used as the key for keychain
#                  lookups. If not set, the function does nothing.
# ------------------------------------------------------------------------------
_export_hsdk_secrets() {
	if [[ -n "$AWS_PROFILE" ]]; then
		# Read cached environment variables from keychain
		eval "$(_hsdk_read_env_from_keychain "$AWS_PROFILE")"
		# Read from hsdk alias tools if available
		if command -v hsdk &>/dev/null; then
			eval "$(hsdk alias-tools 2>/dev/null || true)"
		fi
	fi
}

hsdk-sync() {
	(
		export HSDK_ROLE_NAME="${HSDK_ROLE_NAME:-AdministratorAccess}"
		export HSDK_DEFAULT_OUTPUT=json

		# Make sure the sso directory exists
		mkdir -p ~/.aws/cli/fzf
		# Export the sso config
		hsdk lse | jq '{profiles: [.[] | {
    profile: (.Name + "-" + env.HSDK_ROLE_NAME),
    sso_account_id: .AWSAccountId,
    sso_role_name: env.HSDK_ROLE_NAME,
    sso_region: .AWSSsoRegion,
    sso_start_url: .AWSSsoUrl
  }]}' >~/.aws/cli/fzf/config.json
	)
}

hsdk-exec() {
	local command="$1"

	if [[ "$command" != "exec" ]]; then
		echo "Usage: hsdk.sh exec <profile> -- <command...>" >&2
		exit 1
	fi

	local aws_profile="$2"

	# Get AWS config from profile
	local aws_account_id
	aws_account_id="$(aws configure get sso_account_id --profile "$aws_profile")"

	local aws_region
	aws_region="$(aws configure get sso_region --profile "$aws_profile")"

	# Build HSDK environment ID (format: accountId-region)
	local hsdk_env_id="$aws_account_id-$aws_region"

	# Set the environment using HSDK
	eval "$(hsdk setenv "$hsdk_env_id")"

	# Export AWS_PROFILE for compatibility
	export AWS_PROFILE="$aws_profile"

	# Cache environment variables for future shells
	local env_config
	env_config=$(env | grep -E 'HSDK_|TF_' | awk '{print "export " $0}')

	# Write to keychain
	_hsdk_write_env_to_keychain "$aws_profile" "$env_config"

	# Set the account type in AWS config for tmux-aws styling
	aws configure set environment "${TF_VAR_account_type:-none}" --profile "$aws_profile"

	# Skip 'exec', profile, and '--'
	shift 3
	# Execute the command
	exec "$@"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to hsdk-env.
# This enables tmux integration and scripted usage.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	hsdk-exec "$@"
fi
