#!/bin/bash

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
# Usage:
#   Source this file in your shell configuration:
#     source ~/.config/zsh/snippets/hsdk.sh
#
#   Or run directly for tmux integration:
#     ~/.config/zsh/snippets/hsdk.sh --tmux
# ==============================================================================

# ------------------------------------------------------------------------------
# hsdk-env-fzf
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
#   - Enter: Select environment and return the ID
#   - ctrl-o: Open the AWS console URL in default browser
#   - Esc: Cancel selection
#
# Output:
#   The selected environment ID (stdout)
#
# Environment Variables:
#   HSDK_DEFAULT_OUTPUT: Temporarily set to 'json' for structured data retrieval
#
# Example:
#   selected_env=$(hsdk-env-fzf)
#   echo "Selected environment: $selected_env"
# ------------------------------------------------------------------------------
hsdk-env-fzf() {
	local hsdk_env_list

	# Query HSDK for environments and format as tab-separated values:
	# Column 1: Environment ID
	# Column 2: Environment Name
	# Column 3: AWS Console URL (SSO URL + account info)
	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r '.[] | "\(.Id)\t\(.Name)\t\(.AWSSsoUrl)/#/console?account_id=\(.AWSAccountId)&role_name=AdministratorAccess"' | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1,2: Show only ID and Name columns (hide URL)
	# --accept-nth=1: Return only the Environment ID on selection
	# --bind 'ctrl-o:become(open {3})': Open browser with URL on ctrl-o
	echo "$hsdk_env_list" | fzf --ansi \
		--with-nth=1,2 \
		--accept-nth=1 \
		--header='  Environment' \
		--color=header:cyan \
		--bind 'ctrl-o:become(open {3})+abort'
}

# ------------------------------------------------------------------------------
# hsdk-env-set
# ------------------------------------------------------------------------------
# Interactively selects and sets the HSDK environment for the current shell.
#
# This function provides a seamless workflow for switching environments:
#   1. It calls `hsdk-env-fzf` to display an interactive fuzzy finder.
#   2. The user selects an environment from the list.
#   3. The selected environment ID is then passed to `hsdk se` to configure
#      the shell.
#
# Usage:
#   hsdk-env-set
# ------------------------------------------------------------------------------
hsdk-env-set() {
	hsdk se "$(hsdk-env-fzf)"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), execute hsdk-env-fzf with provided arguments.
# This enables tmux integration via: ~/.config/zsh/snippets/hsdk.sh --tmux
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	hsdk-env-fzf "$@"
fi
