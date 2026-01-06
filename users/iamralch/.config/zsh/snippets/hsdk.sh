#!/bin/bash

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
# _hsdk_delete_env_from_keychain (private)
# ------------------------------------------------------------------------------
# Deletes HSDK environment variables from macOS Keychain.
#
# Parameters:
#   $1 - Environment ID
# ------------------------------------------------------------------------------
_hsdk_delete_env_from_keychain() {
	local env_id="$1"
	security delete-generic-password -s "$HSDK_SECRETS_VAULT" -a "$env_id" >/dev/null 2>&1 || true
}

# ==============================================================================
# HSDK Environment Selection Utilities
# ==============================================================================
# Shell functions for interacting with HSDK (Hippo Software Delivery Kit)
# environments using fuzzy finding (fzf) for selection.
#
# Dependencies:
#   - hsdk: Hippo SDK CLI tool
#   - jq: Command-line JSON processor
#   - fzf: Fuzzy finder for terminal
#   - column: Text column formatting utility
#
# Environment Color Coding:
#   When running in tmux, windows are automatically styled based on environment
#   type to provide visual distinction and prevent accidental operations:
#   - Development (dev):  Yellow indicator  (lower risk)
#   - Staging (stage):    Peach indicator   (moderate risk)
#   - Production (prod):  Red indicator     (high risk)
#   - Other/Unknown:      Rosewater default (unclassified)
#
#   The color coding applies to both active and inactive tmux window status bars,
#   making it easy to identify which environment you're working with at a glance.
#
# Usage:
#   Source this file in your shell configuration:
#     source ~/.config/zsh/snippets/hsdk.sh
#
#   Or run directly:
#     ~/.config/zsh/snippets/hsdk.sh              # Select and set env
#     ~/.config/zsh/snippets/hsdk.sh <id>         # Set env by ID
#     ~/.config/zsh/snippets/hsdk.sh --exec       # Select, set, exec shell
#     ~/.config/zsh/snippets/hsdk.sh --exec <id>  # Set env by ID, exec shell
#
# Workflow Examples:
#
#   Example 1: Quick environment switch in current shell
#     $ hsdk-env
#     [Interactive fzf selection appears]
#     [Select environment, press Enter]
#     [Environment credentials loaded in current shell]
#
#   Example 2: Opening AWS console while browsing
#     $ hsdk-env
#     [Type to filter environments, e.g., "prod"]
#     [Press ctrl-o to open AWS console in browser]
#     [Browser opens, fzf selection still active]
#     [Continue browsing or press Esc to cancel]
#
#   Example 3: Creating dedicated tmux windows for environments
#     $ hsdk-env
#     [Navigate to production environment]
#     [Press ctrl-n to create new tmux window]
#     [New window opens with red indicator and prod environment configured]
#     [Repeat for staging (peach) and dev (yellow) environments]
#     [Result: Multi-window tmux layout with color-coded environments]
#
#   Example 4: Direct environment selection by ID
#     $ hsdk-env 655141976367-us-east-1
#     [Environment set immediately without fzf prompt]
#     [Useful for scripting or when ID is already known]
#
#   Example 5: Setting up monitoring layout in tmux
#     [In tmux, create multiple windows using ctrl-n from fzf]
#     [Window 1: Production environment (red indicator)]
#     [Window 2: Staging environment (peach indicator)]
#     [Window 3: Development environment (yellow indicator)]
#     [Easy visual distinction while monitoring multiple environments]
# ==============================================================================

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
#   - Enter: Select environment and return the ID and Type (for setting in
#            current shell or further processing)
#   - ctrl-o: Open the AWS console URL in default browser without selecting
#            the environment. Useful for quickly checking console while browsing
#            options. The selection remains active after opening.
#   - ctrl-n: Create new tmux window with the selected environment already
#            configured. The window is automatically named with the environment
#            ID and styled with color-coded indicators based on environment type
#            (dev/stage/prod). A new shell is exec'd in the window with the
#            environment credentials loaded.
#   - Esc: Cancel selection and return without setting any environment
#
# Output:
#   The selected environment ID (stdout)
# ------------------------------------------------------------------------------
_hsdk_env_fzf() {
	local hsdk_env_list
	local hsdk_env_list_columns

	# Query HSDK for environments and format as tab-separated values:
	# Column 1: Environment ID
	# Column 2: Environment Name
	# Column 3: Environment Type
	# Column 4: Description
	# Column 5: AWS Console URL (SSO URL + account info)
	hsdk_env_list_columns='(["ID", "NAME", "DESCRIPTION", "URL"] | @tsv),
	                       (.[] | [.Id, .Name, .Description, .AWSSsoUrl + "/#/console?account_id=" + .AWSAccountId + "&role_name=AdministratorAccess"] | @tsv)'

	# Get the environment list
	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r "$hsdk_env_list_columns" | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1..-2: Show all columns except the last (hide URL)
	# --accept-nth=1,3: Return Environment ID and Type on selection
	# --bind 'ctrl-o:...': Open browser with URL on ctrl-o
	# --bind 'ctrl-n:...': Open new tmux window with selected environment
	echo "$hsdk_env_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 --with-nth 1..-2 \
		--footer "$_fzf_icon Environment" \
		--bind 'ctrl-o:execute-silent(open {-1})' \
		--bind 'ctrl-n:execute(tmux new-window -n {1} "~/.config/zsh/snippets/hsdk.sh --exec {1}")+abort'
}

# ------------------------------------------------------------------------------
# _hsdk_env_tmux (private)
# ------------------------------------------------------------------------------
# Apply environment-specific tmux window styling based on environment type.
#
# This function customizes the tmux window status bar appearance to provide
# visual indicators for different environment types. It helps prevent accidental
# operations by making it immediately clear which environment context you're in.
#
# The function sets two tmux window options:
#   1. window-status-current-format: Style for the currently active window
#   2. window-status-format: Style for inactive windows
#
# Both formats include:
#   - Window index number (#I)
#   - AWS cloud icon (󰸏) for visual context
#   - Window name (#W)
#   - Window flags (#F)
#   - Environment-specific color coding
#
# Parameters:
#   $1 - Environment type string (case-insensitive)
#        Supports partial matching against the type string
#
# Color Mapping (using Catppuccin theme variables):
#   - *dev*   → @thm_yellow    (Development environments)
#   - *stage* → @thm_peach     (Staging environments)
#   - *prod*  → @thm_red       (Production environments - high risk)
#   - other   → @thm_rosewater (Default for unrecognized types)
#
# Example Usage:
#   _hsdk_env_tmux "production"     # Sets red indicator
#   _hsdk_env_tmux "dev-testing"    # Sets yellow indicator (partial match)
#   _hsdk_env_tmux "STAGE"          # Sets peach indicator (case-insensitive)
#
# Note: This function should only be called when inside a tmux session.
# ------------------------------------------------------------------------------
_hsdk_env_tmux() {
	local env_type="$1"
	local env_color

	# Convert to lowercase for case-insensitive matching
	env_type=$(echo "$env_type" | tr '[:upper:]' '[:lower:]')
	env_color="@thm_rosewater"

	# Partial match against type
	case "$env_type" in
	*dev*)
		env_color="@thm_yellow"
		;;
	*stage*)
		env_color="@thm_peach"
		;;
	*prod*)
		env_color="@thm_red"
		;;
	esac

	# Style active window with environment-specific color, text, and AWS icon
	tmux set-window-option window-status-current-format "#[fg=#{@thm_bg},bg=#{${env_color}}] #I:   #W #F "
	# Style inactive window with environment-specific color and AWS icon
	tmux set-window-option window-status-format "#[fg=#{${env_color}},bg=#{@thm_bg}] #I:   #W #F "
}

# ------------------------------------------------------------------------------
# _hsdk_env_shell (private)
# ------------------------------------------------------------------------------
# Handles the final steps of setting up an HSDK environment in a new shell.
# It applies tmux styling if applicable and then replaces the current shell
# with a new one, ensuring the environment is fully loaded.
#
# This is typically called with the `--exec` flag in `hsdk-env`.
#
# Parameters:
#   $1 - Environment Type (e.g., "prod", "dev")
# ------------------------------------------------------------------------------
_hsdk_env_shell() {
	local env_type="${1:-$TF_VAR_account_type}"
	if [[ -n "$TMUX" ]]; then
		_hsdk_env_tmux "$env_type"
	fi
	exec "$SHELL"
}

# ------------------------------------------------------------------------------
# _hsdk_set_env (private)
# ------------------------------------------------------------------------------
# Sets the HSDK environment by sourcing credentials, using a keychain cache.
#
# This function handles the logic of retrieving HSDK environment variables.
# It first checks for cached credentials in the macOS keychain. If found, it
# validates them using `aws sts get-caller-identity`. If they are valid, they are
# used. If not, or if they are not found, it fetches new credentials from
# `hsdk se`, verifies them, and caches them in the keychain.
#
# Parameters:
#   $1 - Environment ID
#
# Returns:
#   0 on success, 1 on failure.
# ------------------------------------------------------------------------------
_hsdk_set_env() {
	local env_id="$1"
	local env_data

	env_data=$(_hsdk_read_env_from_keychain "$env_id")
	# Load cached credentials if available
	if [[ -n "$env_data" ]]; then
		eval "$env_data"
		# We also need to eval the alias-tools after setting the env
		eval "$(hsdk alias-tools)"

		if gum spin --title "Verifying cached credentials for '$env_id'..." -- aws sts get-caller-identity >/dev/null 2>&1; then
			# Credentials are good, we are done.
			gum log --level info "Using valid cached credentials for '$env_id'."
			return 0
		fi

		gum log --level warn "Cached credentials for '$env_id' are expired or invalid. Refreshing..."
		# If we are here, credentials were bad.
		_hsdk_delete_env_from_keychain "$env_id"
	fi

	# Fetch new ones.
	# shellcheck disable=SC2016
	env_data=$(
		gum spin --title "Fetching new credentials for '$env_id'..." -- \
			env -i HOME="$HOME" PATH="$PATH" HSDK_ENV_ID="$env_id" \
			sh -c 'eval "$(hsdk se $HSDK_ENV_ID 2>/dev/null)"; env' | grep -E '^(TF_|AWS_|HSDK_)' | awk '{print "export " $0}'
	)

	# If fetching failed, exit with error.
	if [[ -z "$env_data" ]]; then
		gum log --level error "Failed to fetch credentials for '$env_id'."
		return 1
	fi

	eval "$env_data"
	# We also need to eval the alias-tools after setting the env
	eval "$(hsdk alias-tools)"

	# Verify that the new credentials work before caching them.
	if gum spin --title "Verifying new credentials for '$env_id'..." -- aws sts get-caller-identity >/dev/null 2>&1; then
		_hsdk_write_env_to_keychain "$env_id" "$env_data"
		gum log --level info "Successfully cached new credentials for '$env_id'."
	else
		gum log --level error "Fetched credentials for '$env_id' are invalid."
		return 1
	fi

	return 0
}

# ------------------------------------------------------------------------------
# hsdk-env
# ------------------------------------------------------------------------------
# Set HSDK environment in the current shell, with optional interactive selection.
#
# This function now includes keychain caching for HSDK credentials. It will
# first attempt to load credentials from the macOS keychain. If found, it checks
# if they are expired. If they are not expired, it uses them. Otherwise, it
# fetches new credentials from `hsdk`, caches them in the keychain, and then
# loads them.
#
# Usage:
#   hsdk-env              # Select interactively, set in current shell
#   hsdk-env <id>         # Set environment by ID
#   hsdk-env --exec       # Select interactively, set, then exec new shell
#   hsdk-env --exec <id>  # Set environment by ID, then exec new shell
#
# Options:
#   --exec    After setting the environment, replace the current process with
#             a new shell. Useful for tmux new-window integration.
#
# Examples:
#   hsdk-env                           # Interactive selection
#   hsdk-env 655141976367-us-east-1    # Set specific environment
#   hsdk-env --exec                    # Interactive + new shell (for tmux)
# ------------------------------------------------------------------------------
hsdk-env() {
	local exec_shell=false
	local env_id

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--exec)
			exec_shell=true
			shift
			;;
		*)
			env_id="$1"
			shift
			;;
		esac
	done

	# If no env_id provided, select interactively
	if [[ -z "$env_id" ]]; then
		# get the environment
		env_id=$(_hsdk_env_fzf)
	fi

	# If no env_id is set after parsing and fzf, exit.
	if [[ -z "$env_id" ]]; then
		# fzf was cancelled, not an error
		return 0
	fi

	# Set the environment
	if ! _hsdk_set_env "$env_id"; then
		return 1
	fi

	# Spawn new shell if requested
	if [[ "$exec_shell" == true ]]; then
		_hsdk_env_shell
	fi
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
