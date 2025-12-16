#!/bin/bash
# Commit-related functions for gh-opencode

# Extract commit message from dry-run output
#
# Parses the output from `opencode run --command="gh.commit"` with --dry-run flag
# and extracts the commit message between the delimiters.
#
# Usage: _extract_commit_message "$dry_run_output"
_extract_commit_message() {
	local output="$1"

	# Extract content between <!-- COMMIT_MESSAGE_START --> and <!-- COMMIT_MESSAGE_END -->
	echo "$output" | sed -n '/<!-- COMMIT_MESSAGE_START -->/,/<!-- COMMIT_MESSAGE_END -->/p' | sed '1d;$d'
}

# Filter out OpenCode-managed arguments for commit
#
# Removes arguments that OpenCode manages internally (-m, --message, -F, --file, --model)
# and returns the remaining arguments. This allows users to pass other git commit
# flags while OpenCode handles the commit message.
#
# Example: _filter_gh_commit_args --all -m "message" --signoff
# Returns: --all --signoff
_filter_gh_commit_args() {
	local input_args=("$@")
	local filtered_args=()
	local i=0

	while [[ $i -lt ${#input_args[@]} ]]; do
		case "${input_args[$i]}" in
		# Arguments to filter out (OpenCode manages these)
		-m | --message | -F | --file | --model)
			# Skip this argument and its value
			if [[ $((i + 1)) -lt ${#input_args[@]} ]] && [[ "${input_args[$((i + 1))]}" != -* ]]; then
				((i++)) # Skip the value too
			fi
			;;
		*)
			# Pass through all other arguments
			filtered_args+=("${input_args[$i]}")
			;;
		esac
		((i++))
	done

	# Output the filtered arguments
	printf '%s\n' "${filtered_args[@]}"
}

# Extract model from arguments
#
# Searches for --model flag in arguments and returns the specified model.
# Returns empty string if not found (caller should use default).
#
# Usage: _get_model "$@"
_get_commit_model() {
	local args=("$@")
	local i=0

	while [[ $i -lt ${#args[@]} ]]; do
		case "${args[$i]}" in
		--model)
			if [[ $((i + 1)) -lt ${#args[@]} ]]; then
				echo "${args[$((i + 1))]}"
				return 0
			fi
			;;
		esac
		((i++))
	done

	# Return default model
	echo "$GH_OPENCODE_COMMIT_MODEL"
}

# Main commit command implementation
#
# Creates a git commit with an AI-generated message based on staged changes.
# Uses opencode run with --command="gh.commit" and --dry-run to generate the message,
# then executes git commit with the generated message.
#
# Usage: _gh_commit [GIT_COMMIT_OPTIONS] [--model MODEL]
# Example: _gh_commit --signoff --no-verify
# Example: _gh_commit --model "github-copilot/gpt-4o"
_gh_commit() {
	local args=("$@")
	local clean_args
	local dry_run_output
	local commit_message
	local model

	# Extract model from arguments (or use default)
	model="anthropic/claude-3-5-haiku-latest"

	# Filter out OpenCode-managed arguments
	local filtered_output
	filtered_output=$(_filter_gh_commit_args "${args[@]}")
	IFS=$'\n' read -rd '' -a clean_args <<<"$filtered_output" || true

	# Generate commit message using opencode run with dry-run
	dry_run_output=$(gum spin --title "Generating Git commit message with OpenCode..." -- \
		opencode run \
		--command="gh.commit" \
		--model="$model" \
		--agent="build" \
		--log-level="ERROR" \
		-- "--dry-run")

	# Check execution success
	# shellcheck disable=SC2181
	if [ $? -ne 0 ]; then
		gum log --level=error "Failed to generate commit message"
		return 1
	fi

	# Extract commit message from dry-run output
	commit_message=$(_extract_commit_message "$dry_run_output")

	# Validate we got a commit message
	if [[ -z "$commit_message" ]]; then
		gum log --level=error "Failed to extract commit message from OpenCode output"
		return 1
	fi

	# Commit with the generated message and pass through any extra args
	git commit -m "$commit_message" --edit "${clean_args[@]}"
}
