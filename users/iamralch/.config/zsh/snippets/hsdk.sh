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
	hsdk_env_list_columns='(["ID", "NAME", "TYPE", "DESCRIPTION", "URL"] | @tsv),
	                       (.[] | [.Id, .Name, (.Type // "none" | select(. != "") // "none"), .Description, .AWSSsoUrl + "/#/console?account_id=" + .AWSAccountId + "&role_name=AdministratorAccess"] | @tsv)'

	hsdk_env_list=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r "$hsdk_env_list_columns" | column -t -s $'\t')

	# Display in fzf with:
	# --with-nth=1..-2: Show all columns except the last (hide URL)
	# --accept-nth=1,3: Return Environment ID and Type on selection
	# --bind 'ctrl-o:...': Open browser with URL on ctrl-o
	# --bind 'ctrl-n:...': Open new tmux window with selected environment
	echo "$hsdk_env_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1,3 --with-nth 1..-2 \
		--footer "$_fzf_icon Environment" \
		--bind 'ctrl-o:execute-silent(open {-1})' \
		--bind 'ctrl-n:become(tmux new-window -n {1} "~/.config/zsh/snippets/hsdk.sh --exec {1}")'
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

	# Style active window with environment-specific color, bold text, and AWS icon
	tmux set-window-option window-status-current-format "#[fg=#{@thm_bg},bg=#{${env_color}},bold] #I:   #W #F "
	# Style inactive window with environment-specific color and AWS icon
	tmux set-window-option window-status-format "#[fg=#{${env_color}},bg=#{@thm_bg}] #I:   #W #F "
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
			_hsdk_env_tmux "$env_type"
		fi

		if eval "$(hsdk se "$env_id")"; then
			# Optionally exec new shell (for tmux new-window)
			if [[ "$exec_shell" == true ]]; then
				exec "$SHELL"
			fi
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
