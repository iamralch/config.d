#!/bin/bash

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# Global Configuration
# ------------------------------------------------------------------------------
# _fzf_icon: AWS cloud icon (󰸏) used in fzf prompt footers for visual context
# _fzf_options: Shared fzf configuration array for consistent UI across all
#               interactive selections. Key settings:
#   --tmux='100%,100%': Run fzf in tmux popup (full screen)
#   --border='none': No outer border (tmux popup provides border)
#   --layout='reverse-list': List items top-to-bottom with prompt at bottom
#   --header-lines='1': Treat first line as column headers
#   Various --*-border and --color options for styled appearance
# ------------------------------------------------------------------------------

_fzf_icon=" "

_fzf_options=(
	--ansi
	--tmux
	--border='sharp'
	--color='header:cyan'
	--color='footer:cyan'
	--header-lines='1'
	--header-border='sharp'
	--footer-border='sharp'
	--input-border='sharp'
	--layout='reverse-list'
)

HSDK_ROLE_NAME="${HSDK_ROLE_NAME:-AdministratorAccess}"

# ------------------------------------------------------------------------------
# _hsdk_env_fzf (private)
# ------------------------------------------------------------------------------
# Interactively select an HSDK environment using fzf with AWS console URLs.
#
# This function queries HSDK for available environments and presents them in
# an interactive fuzzy finder. Each environment entry includes:
#   - Environment ID
#   - Environment Name
#   - AWS SSO Console URL (hidden in display, accessible via ctrl-o)
#
# Keybindings:
#   - Enter: Select environment and return the ID for setting in the current
#            shell or for further processing.
#   - ctrl-o: Open the AWS console URL in the default browser without selecting
#            the environment. Useful for quickly checking the console.
#   - alt-n: Create a new tmux window with the selected environment already
#            configured. The window is automatically named with the environment
#            ID. A new shell is started in the window with the environment
#            credentials loaded.
#   - Esc: Cancel selection and return without setting any environment.
#
# Output:
#   The selected environment ID (stdout).
# ------------------------------------------------------------------------------
_hsdk_env_fzf() {
	local hsdk_env_list
	local hsdk_env_list_columns

	# Query HSDK for environments and format as tab-separated values:
	# Column 1: Environment ID
	# Column 2: Environment Name
	# Column 3: Description
	# Column 4: AWS Console URL (SSO URL + account info)
	hsdk_env_list_columns='(["ID", "NAME", "ACCOUNT", "REGION", "URL", "DESCRIPTION"] | @tsv),
	                       (.[] | [.Id, .Name, .AWSAccountId, .AWSSsoRegion, .AWSSsoUrl, .Description] | @tsv)'

	# Get the environment list
	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r "$hsdk_env_list_columns" | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1..-2: Show all columns except the last (hide URL)
	# --accept-nth=1: Return Environment ID on selection
	# --bind 'ctrl-o:...': Open browser with URL on ctrl-o
	# --bind 'ctrl-n:...': Open new tmux window with selected environment
	echo "$hsdk_env_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1,2,6.. \
		--footer "$_fzf_icon Environment" \
		--bind "ctrl-o:execute(open {5}/\#/console\?account_id={3}\&role_name=$HSDK_ROLE_NAME)+abort" \
		--bind "alt-enter:become(tmux new-window -n {1} $HOME/.config/zsh/snippets/hsdk.sh auth {1})+abort"
}

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
# _hsdk_set_env (private)
# ------------------------------------------------------------------------------
# Sets the HSDK environment by fetching and caching credentials.
#
# This function handles the logic of retrieving and storing HSDK environment
# variables. It performs the following steps:
#   1. Fetches new credentials and environment variables using `hsdk setenv`.
#   2. Exports the `AWS_PROFILE` variable based on the environment alias.
#   3. Gathers all relevant environment variables (HSDK, TF, AWS_VAULT).
#   4. Caches these variables in the macOS Keychain for later use by
#      `_export_hsdk_secrets`.
#
# This function always fetches fresh credentials and overwrites any existing
# cached entry.
#
# Parameters:
#   $1 - Environment ID
#
# Returns:
#   0 on success, assuming `hsdk setenv` is successful.
# ------------------------------------------------------------------------------
_hsdk_set_env() {
	local env_id="$1"

	# Get the HSDK Credentials
	# shellcheck disable=SC2016
	eval "$(unset AWS_VAULT && hsdk setenv "$env_id")"
	# We assume success if we reach this point
	export AWS_PROFILE="${HSDK_ENV_ALIAS}-${HSDK_ROLE_NAME}"

	local env_config
	env_config=$(env | grep -E 'HSDK|TF' | awk '{print "export " $0}')
	# Write the hsdk env to the keychain
	_hsdk_write_env_to_keychain "$AWS_PROFILE" "$env_config"
}

# ------------------------------------------------------------------------------
# _hsdk_env_auth (private)
# ------------------------------------------------------------------------------
# Authenticates and configures a new tmux window for a given HSDK environment.
#
# This function is designed to be called when creating a new tmux window for a
# specific environment. It performs the following steps:
#   1. Sets the HSDK environment using `_hsdk_set_env`, which handles credential
#      fetching and caching.
#   2. If inside a tmux session, it configures the AWS profile with the
#      environment type (e.g., 'dev', 'stage', 'prod').
#   3. Updates the tmux status bar to display the current AWS profile using a
#      tmux plugin.
#   4. Replaces the current shell with a new login shell, ensuring the
#      environment is fully loaded.
#
# This function is primarily used by the `_hsdk_env_fzf`'s `ctrl-n` keybinding.
#
# Parameters:
#   $1 - The HSDK environment ID to authenticate with.
#
# Returns:
#   This function typically replaces the current process and does not return.
#   If not in a tmux session or if `_hsdk_set_env` fails, it will do nothing
#   and return.
# ------------------------------------------------------------------------------
_hsdk_env_auth() {
	local env_id="$1"

	# Set the HSDK environment for the new tmux window
	if [[ -n "$TMUX" ]]; then
		local tmux_window_id
		tmux_window_id="$(tmux display -p '#{session_name}:#{window_index}')"

		if _hsdk_set_env "$env_id"; then
			# Set the environment profile type
			# shellcheck disable=SC2154
			aws configure set environment "${TF_VAR_account_type}" --profile "$AWS_PROFILE"
			# Create a new tmux window with the selected environment
			"$TMUX_PLUGIN_MANAGER_PATH/tmux-aws/scripts/tmux-aws.sh" --profile "$AWS_PROFILE" --target "$tmux_window_id"
			# Start a new shell in the tmux window
			"$SHELL" --login
		fi
	else
		_hsdk_set_env "$env_id"
	fi

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
		# Read from environment variables if set
		eval "$(_hsdk_read_env_from_keychain "$AWS_PROFILE")"
		# Export AWS_VAULT for aws-vault compatibility
		export AWS_VAULT="$HSDK_ENV_ID"
		# Read from hsdk alias tools if available
		eval "$(hsdk alias-tools)"
	fi
}

# ------------------------------------------------------------------------------
# hsdk-env
# ------------------------------------------------------------------------------
# Manages HSDK environments, supporting interactive selection and tmux integration.
#
# This script provides two main modes of operation:
#
# 1. Interactive Environment Selection (default):
#    When run without arguments, it launches an fzf-based interactive menu
#    to select an HSDK environment. Upon selection, it fetches credentials
#    for that environment using `hsdk setenv`, caches them in the macOS
#    Keychain, and loads them into the current shell.
#
# 2. Tmux Authentication (`auth` subcommand):
#    This mode is intended for internal use, specifically with tmux. It's
#    triggered by the `ctrl-n` binding in the fzf menu. It sets up a new
#    tmux window for the selected environment, complete with AWS profile
#    configuration and a custom status bar.
#
# The script leverages the macOS Keychain to cache credentials, allowing for
# quick re-sourcing of environments in new shell sessions via the `_export_hsdk_secrets`
# function (which should be added to a shell rc file).
#
# Usage:
#   hsdk-env              # Interactively select and set environment in the current shell.
#   hsdk-env auth <id>    # (Internal) Authenticate and configure a new tmux window.
#
# Examples:
#   hsdk-env              # Launch fzf to choose an environment.
#
# Direct execution:
#   If this script is executed directly (not sourced), it passes all arguments
#   to the `hsdk-env` function, enabling its use in contexts like tmux keybindings.
# ------------------------------------------------------------------------------
hsdk-env() {
	local command="${1:-}"

	case "$command" in
	auth)
		shift
		_hsdk_env_auth "$1"
		;;
	"")
		local env_id
		env_id="$(_hsdk_env_fzf)"
		# Set the selected environment
		if [[ -n "$env_id" ]]; then
			_hsdk_set_env "$env_id"
		fi
		;;
	*)
		return 1
		;;
	esac
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to hsdk-env.
# This enables tmux integration and scripted usage.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	hsdk-env "$@"
fi
