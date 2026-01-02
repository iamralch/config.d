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
	# Column 3: Environment Type
	# Column 4: Description
	# Column 5: AWS Console URL (SSO URL + account info)
	hsdk_env_list_columns='(["ID", "NAME", "TYPE", "DESCRIPTION", "URL"] | @tsv),
	                       (.[] | [.Id, .Name, (.Type // "none" | select(. != "") // "none"), .Description, .AWSSsoUrl + "/#/console?account_id=" + .AWSAccountId + "&role_name=AdministratorAccess"] | @tsv)'

	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r "$hsdk_env_list_columns" | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1..-2: Show all columns except the last (hide URL)
	# --accept-nth=1,3: Return Environment ID and Type on selection
	# --bind 'ctrl-o:...': Open browser with URL on ctrl-o
	# --bind 'ctrl-n:...': Open new tmux window with selected environment
	echo "$hsdk_env_list" | fzf --ansi \
		--border none \
		--accept-nth 1,3 \
		--with-nth 1..-2 \
		--tmux 100%,100% \
		--color header:cyan \
		--color footer:cyan \
		--header-lines 1 \
		--header-border sharp \
		--footer '  Environment' \
		--footer-border sharp \
		--input-border sharp \
		--layout 'reverse-list' \
		--bind 'ctrl-o:execute-silent(open {-1})' \
		--bind 'ctrl-n:become(tmux new-window -n {1} "~/.config/zsh/snippets/hsdk.sh --exec {1}")'
}

# ------------------------------------------------------------------------------
# _hsdk_get_color_from_type (private)
# ------------------------------------------------------------------------------
# Map HSDK environment type to tmux theme color variable.
#
# This function performs case-insensitive partial matching to determine the
# appropriate color for tmux window styling based on environment type:
#   - Development environments (dev, development) → @thm_yellow
#   - Stage environments (stage, staging, stag) → @thm_peach
#   - Production environments (prod, production) → @thm_red
#   - Unknown/missing type → empty string (no styling)
#
# Arguments:
#   $1: Environment type string (e.g., "development", "production", "stage")
#
# Output:
#   Tmux theme color variable name or empty string
# ------------------------------------------------------------------------------
_hsdk_get_color_from_type() {
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

	echo "$env_color"
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
	local env_id
	local env_type

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
		local env_item
		# get the environment
		env_item=$(_hsdk_env_fzf)
		# Extract ID (first field) and Type (second field) from selection
		env_id=$(echo "$env_item" | awk '{print $1}')
		env_type=$(echo "$env_item" | awk '{print $2}')
	fi

	# If env_id was provided directly (not from fzf), fetch the Type
	if [[ -n "$env_id" ]] && [[ -z "$env_type" ]]; then
		env_type=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r ".[] | select(.Id == \"$env_id\") | .Type")
	fi

	# Set the environment
	if [[ -n "$env_id" ]]; then
		# Determine color based on environment type

		# Apply custom tmux window styling if in a tmux session and color is set
		if [[ "$exec_shell" == true ]] && [[ -n "$TMUX" ]]; then
			local env_color
			# get the environment color
			env_color=$(_hsdk_get_color_from_type "$env_type")
			# Style active window with environment-specific color, bold text, and AWS icon
			tmux set-window-option window-status-current-format "#[fg=#{@thm_bg},bg=#{${env_color}},bold] #I:   #W #F "
			# Style inactive window with environment-specific color and AWS icon
			tmux set-window-option window-status-format "#[fg=#{${env_color}},bg=#{@thm_bg}] #I:   #W #F "
		fi

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
