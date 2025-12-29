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
#   Or run directly:
#     ~/.config/zsh/snippets/hsdk.sh              # Select and set env
#     ~/.config/zsh/snippets/hsdk.sh <id>         # Set env by ID
#     ~/.config/zsh/snippets/hsdk.sh --exec       # Select, set, exec shell
#     ~/.config/zsh/snippets/hsdk.sh --exec <id>  # Set env by ID, exec shell
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
#   - Enter: Select environment and return the ID
#   - ctrl-o: Open the AWS console URL in default browser
#   - ctrl-w: Open new tmux window with selected environment
#   - Esc: Cancel selection
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
	# Column 3: Description
	# Column 4: AWS Console URL (SSO URL + account info)
	hsdk_env_list_columns='["Id", "Name", "Description", "URL"], (.[] | [.Id, .Name, .Description, .AWSSsoUrl + "/#/console?account_id=" + .AWSAccountId + "&role_name=AdministratorAccess"]) | @tsv'
	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r "$hsdk_env_list_columns" | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1..-2: Show all columns except the last (hide URL)
	# --accept-nth=1: Return only the Environment ID on selection
	# --bind 'ctrl-o:...': Open browser with URL on ctrl-o
	# --bind 'ctrl-w:...': Open new tmux window with selected environment
	echo "$hsdk_env_list" | fzf --ansi \
		--border none \
		--accept-nth=1 \
		--with-nth=1..-2 \
		--tmux 100%,100% \
		--header-lines 1 \
		--color header:cyan \
		--header='  Environment' \
		--bind 'ctrl-o:execute-silent(open {-1})' \
		--bind 'ctrl-n:become(tmux new-window -n aws/{1} "~/.config/zsh/snippets/hsdk.sh --exec {1}")'
}

# ------------------------------------------------------------------------------
# hsdk-env
# ------------------------------------------------------------------------------
# Set HSDK environment in the current shell, with optional interactive selection.
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
	local env_id=""

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
		env_id=$(_hsdk_env_fzf)
	fi

	# Set the environment
	if [[ -n "$env_id" ]]; then
		eval "$(hsdk se "$env_id")"

		# Optionally exec new shell (for tmux new-window)
		if [[ "$exec_shell" == true ]]; then
			exec $SHELL
		fi
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
