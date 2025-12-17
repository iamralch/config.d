#!/bin/bash
# Commit-related functions for gh-opencode

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
# Uses opencode run with the template content directly injected into the prompt,
# and passes the staged diff as a file attachment.
#
# Usage: _gh_commit [GIT_COMMIT_OPTIONS] [--model MODEL]
# Example: _gh_commit --signoff --no-verify
# Example: _gh_commit --model "github-copilot/gpt-4o"
_gh_commit() {
	local args=("$@")
	local clean_args
	local output
	local commit_message
	local model
	local diff_file
	local template_dir

	# Template directory (relative to source_dir from main script)
	template_dir=$(_get_template_dir)

	# Model for commit message generation
	model="google/gemini-2.5-flash"

	# Filter out OpenCode-managed arguments
	local filtered_output
	filtered_output=$(_filter_gh_commit_args "${args[@]}")
	IFS=$'\n' read -rd '' -a clean_args <<<"$filtered_output" || true

	# Create temporary file for diff
	diff_file=$(_create_temp_file "gh-opencode-diff")
	# shellcheck disable=SC2064
	trap "rm -f '$diff_file'" RETURN

	# Get staged diff
	if ! git diff --staged >"$diff_file"; then
		gum log --level=error "Failed to get staged changes"
		return 1
	fi

	# Check if there are staged changes
	_require_file_not_empty "$diff_file" "No staged changes found. Please stage your changes with 'git add' first." || return 1

	# Build the prompt from template
	local prompt
	prompt="$(cat "$template_dir/gh.commit.md")"

	# Generate commit message using opencode run
	output=$(gum spin --title "Generating Git commit message with OpenCode..." -- \
		opencode run "$prompt" \
		--file="$diff_file" \
		--model="$model" \
		--log-level="ERROR")

	# Check execution success
	# shellcheck disable=SC2181
	if [[ $? -ne 0 ]]; then
		gum log --level=error "Failed to generate commit message"
		return 1
	fi

	# Extract commit message from output
	commit_message=$(_extract_delimited_content "$output" "COMMIT_MESSAGE")

	# Validate we got a commit message
	if [[ -z "$commit_message" ]]; then
		gum log --level=error "Failed to extract commit message from OpenCode output"
		return 1
	fi

	# Commit with the generated message and pass through any extra args
	git commit -m "$commit_message" --edit "${clean_args[@]}"
}
