#!/bin/bash
# PR-related functions for gh-opencode

# Extract PR number from arguments
#
# Searches through command line arguments to find a numeric PR number.
# Returns the first numeric argument found, or exits with code 1 if none found.
#
# Example: _get_pr_number review 123 --body "test"  # Returns: 123
_get_pr_number() {
	local args=("$@")
	local i=0

	# Look for a numeric argument (PR number)
	while [[ $i -lt ${#args[@]} ]]; do
		if [[ "${args[$i]}" =~ ^[0-9]+$ ]]; then
			echo "${args[$i]}"
			return 0
		fi
		((i++))
	done

	# No PR number found - will let gh pr review handle this
	return 1
}

# Auto-detect PR number for current branch
#
# Uses gh pr view to get the PR number associated with the current branch.
# Returns the PR number or exits with code 1 if no PR found.
#
# Usage: _detect_pr_number
_detect_pr_number() {
	local pr_number

	pr_number=$(gh pr view --json number -q '.number' 2>/dev/null)

	if [[ -n "$pr_number" ]]; then
		echo "$pr_number"
		return 0
	fi

	return 1
}

# Extract model from arguments
#
# Searches for --model flag in arguments and returns the specified model.
# Returns empty string if not found (caller should use default).
#
# Usage: _get_model "$@"
_get_pr_model() {
	local args=("$@")
	local default="$1"
	shift
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
	echo "$default"
}

# Extract title from AI response
#
# Gets the PR title from AI-generated content by taking the first line
# and removing any markdown heading prefix (#).
#
# Example: _get_pr_title "# Fix bug in parser\n\nDescription..."
# Returns: "Fix bug in parser"
_get_pr_title() {
	local ai_content="$1"
	local title

	# Extract title (first line with # prefix removed)
	title=$(echo "$ai_content" | head -n 1 | sed 's/^# *//')

	# Validate we got a title
	if [[ -z "$title" ]]; then
		gum log --level=error "Failed to extract title from AI content"
		return 1
	fi

	echo "$title"
}

# Extract body from AI response and save to file
#
# Takes everything after the first line of AI content (skipping the title)
# and saves it to a temporary markdown file. Removes any leading blank lines
# to ensure clean formatting. This avoids duplicating the title which is
# already set in the PR title field.
# Caller must handle cleanup of the temporary file.
_get_pr_body() {
	local ai_content="$1"
	local body_file

	# Create temporary file for body content
	body_file=$(mktemp).md

	# Extract body (skip first line) and remove leading blank lines
	echo "$ai_content" | tail -n +2 | sed '/./,$!d' >"$body_file"

	# Return the file path
	echo "$body_file"
}

# Extract PR content from dry-run output
#
# Parses the output from `opencode run --command="gh.pr.create"` with --dry-run flag
# and extracts the PR content between the delimiters.
#
# Usage: _extract_pr_content "$dry_run_output"
_extract_pr_content() {
	local output="$1"

	# Extract content between <!-- PR_CONTENT_START --> and <!-- PR_CONTENT_END -->
	echo "$output" | sed -n '/<!-- PR_CONTENT_START -->/,/<!-- PR_CONTENT_END -->/p' | sed '1d;$d'
}

# Extract review content from dry-run output
#
# Parses the output from `opencode run --command="gh.pr.review"` with --dry-run flag
# and extracts the review content between the delimiters.
#
# Usage: _extract_review_content "$dry_run_output"
_extract_review_content() {
	local output="$1"

	# Extract content between <!-- REVIEW_CONTENT_START --> and <!-- REVIEW_CONTENT_END -->
	echo "$output" | sed -n '/<!-- REVIEW_CONTENT_START -->/,/<!-- REVIEW_CONTENT_END -->/p' | sed '1d;$d'
}

# Filter out OpenCode-managed arguments for PR create
#
# Removes PR create arguments that OpenCode handles (title, body, fill flags, model)
# so users can still pass other options like --draft, --base, etc.
#
# Filters out: --title/-t, --body/-b, --body-file/-F, --fill variants, --model
# Example: _filter_gh_pr_create_args --title "test" --draft --base main
# Returns: --draft --base main
_filter_gh_pr_create_args() {
	local input_args=("$@")
	local filtered_args=()
	local i=0

	while [[ $i -lt ${#input_args[@]} ]]; do
		case "${input_args[$i]}" in
		# Arguments to filter out (OpenCode manages these)
		--title | -t | --body | -b | --body-file | -F | --model)
			# Skip this argument and its value
			if [[ $((i + 1)) -lt ${#input_args[@]} ]] && [[ "${input_args[$((i + 1))]}" != -* ]]; then
				((i++)) # Skip the value too
			fi
			;;
		--fill | --fill-first | --fill-verbose)
			# These flags don't have values, just skip
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

# Filter arguments for PR review (remove OpenCode-managed ones)
#
# Removes review arguments that OpenCode handles (body, comment flags, model)
# while preserving other options like PR number and --approve.
#
# Filters out: --body/-b, --body-file/-F, --comment/-c, --model
# Example: _filter_gh_pr_review_args 123 --body "test" --approve
# Returns: 123 --approve
_filter_gh_pr_review_args() {
	local input_args=("$@")
	local filtered_args=()
	local i=0

	while [[ $i -lt ${#input_args[@]} ]]; do
		case "${input_args[$i]}" in
		# Arguments to filter out (OpenCode manages these)
		--body | -b | --body-file | -F | --comment | -c | --model)
			# Skip this argument and its value
			if [[ $((i + 1)) -lt ${#input_args[@]} ]] && [[ "${input_args[$((i + 1))]}" != -* ]]; then
				((i++)) # Skip the value too
			fi
			;;
		*)
			# Pass through all other arguments (including PR number)
			filtered_args+=("${input_args[$i]}")
			;;
		esac
		((i++))
	done

	# Output the filtered arguments
	printf '%s\n' "${filtered_args[@]}"
}

# PR Create implementation
#
# Creates a GitHub PR with AI-generated title and description.
# Uses opencode run with --command="gh.pr.create" and --dry-run to generate content,
# then executes gh pr create with the generated content.
# Falls back to manual PR creation if AI generation fails.
#
# Usage: _gh_pr_create [GH_PR_CREATE_OPTIONS] [--model MODEL]
_gh_pr_create() {
	local args=("$@")
	local clean_args
	local dry_run_output
	local pr_content
	local title
	local body_file
	local model

	# Extract model from arguments (or use default)
	model="github-copilot/claude-sonnet-4"

	# Filter out OpenCode-managed arguments
	local filtered_output
	filtered_output=$(_filter_gh_pr_create_args "${args[@]}")
	IFS=$'\n' read -rd '' -a clean_args <<<"$filtered_output" || true

	# Generate PR content using opencode run with dry-run
	dry_run_output=$(gum spin --title "Generating GitHub Pull Request with OpenCode..." -- \
		opencode run \
		--command="gh.pr.create" \
		--model="$model" \
		--agent="build" \
		--log-level="ERROR" \
		-- "--dry-run")

	# Check execution success
	# shellcheck disable=SC2181
	if [ $? -ne 0 ]; then
		gum log --level=warn "AI content generation failed. Falling back to manual PR creation."
		gh pr create "${clean_args[@]}"
		return 1
	fi

	# Extract PR content from dry-run output
	pr_content=$(_extract_pr_content "$dry_run_output")

	if [[ -z "$pr_content" ]]; then
		gum log --level=warn "Failed to extract PR content. Falling back to manual PR creation."
		gh pr create "${clean_args[@]}"
		return 1
	fi

	# Parse title and body from PR content
	if ! title=$(_get_pr_title "$pr_content"); then
		return 1
	fi

	body_file=$(_get_pr_body "$pr_content")
	trap 'rm -f "$body_file"' EXIT INT TERM

	# Create PR with AI-generated content
	gh pr create --title "$title" --body-file "$body_file" "${clean_args[@]}"
}

# PR Review implementation
#
# Submits a GitHub PR review with AI-generated feedback.
# Uses opencode run with --command="gh.pr.review" and --dry-run to generate content,
# then executes gh pr review with the generated content.
# Auto-detects PR number from current branch if not provided.
#
# Usage: _gh_pr_review [PR_NUMBER] [GH_PR_REVIEW_OPTIONS] [--model MODEL]
_gh_pr_review() {
	local args=("$@")
	local clean_args
	local pr_number
	local dry_run_output
	local review_content
	local review_file
	local model

	# Extract model from arguments (or use default)
	model="github-copilot/claude-sonnet-4"

	# Extract PR number from arguments or auto-detect
	pr_number=$(_get_pr_number "${args[@]}")
	if [[ -z "$pr_number" ]]; then
		pr_number=$(_detect_pr_number)
		if [[ -z "$pr_number" ]]; then
			gum log --level=error "No PR number provided and could not detect PR for current branch"
			gum log --level=info "Usage: gh opencode pr review <PR_NUMBER> [OPTIONS]"
			return 1
		fi
		gum log --level=info "Auto-detected PR #$pr_number for current branch"
	fi

	# Filter out OpenCode-managed arguments
	local filtered_output
	filtered_output=$(_filter_gh_pr_review_args "${args[@]}")
	IFS=$'\n' read -rd '' -a clean_args <<<"$filtered_output" || true

	# Generate review content using opencode run with dry-run
	# Pass PR number as argument to the command
	dry_run_output=$(gum spin --title "Generating GitHub Pull Request review with OpenCode..." -- \
		opencode run \
		--command="gh.pr.review" \
		--model="$model" \
		--agent="build" \
		--log-level="ERROR" \
		-- "$pr_number --dry-run")

	# Check execution success
	# shellcheck disable=SC2181
	if [ $? -ne 0 ]; then
		gum log --level=error "Failed to generate AI review. Aborting."
		return 1
	fi

	# Extract review content from dry-run output
	review_content=$(_extract_review_content "$dry_run_output")

	if [[ -z "$review_content" ]]; then
		gum log --level=error "Failed to extract review content from OpenCode output"
		return 1
	fi

	# Create review file from content
	review_file=$(mktemp).md
	echo "$review_content" >"$review_file"
	trap 'rm -f "$review_file"' EXIT INT TERM

	# Submit review with AI-generated content
	gum log --level=info "Submitting PR review..."
	gum spin --title "Submitting GitHub Pull Request review..." -- \
		gh pr review "$pr_number" --body-file "$review_file" "${clean_args[@]}"
}

# PR help function
#
# Displays comprehensive help information for all PR subcommands
# including usage examples and available options.
_show_pr_help() {
	cat <<'EOF'
gh opencode pr - Pull request commands with AI assistance

USAGE:
    gh opencode pr create [GH_PR_CREATE_OPTIONS] [--model MODEL]
    gh opencode pr review [PR_NUMBER] [GH_PR_REVIEW_OPTIONS] [--model MODEL]

DESCRIPTION:
    Creates and reviews GitHub pull requests with AI-generated content.

COMMANDS:
    create      Create PRs with AI-generated titles and descriptions
    review      Review PRs with AI-generated feedback

OPTIONS:
    --model MODEL    Override the AI model (default: github-copilot/claude-sonnet-4)

ENVIRONMENT VARIABLES:
    GH_OPENCODE_PR_CREATE_MODEL    Model for PR creation
    GH_OPENCODE_PR_REVIEW_MODEL    Model for PR review

SEE ALSO:
    gh pr create --help    # Full list of gh pr create options
    gh pr review --help    # Full list of gh pr review options
EOF
}

# PR subcommand handler
#
# Routes PR subcommands (create, review) to their appropriate
# handler functions. Shows help for unknown commands.
#
# Usage: _gh_pr <subcommand> [OPTIONS]
# Subcommands: create, review, help
_gh_pr() {
	local subcommand="$1"
	shift

	case $subcommand in
	create)
		_gh_pr_create "$@"
		;;
	review)
		_gh_pr_review "$@"
		;;
	--help | -h | help | "")
		_show_pr_help
		;;
	*)
		gum log --level=error "Unknown pr command '$subcommand'"
		gum log --level=info "Available commands: create, review"
		gum log --level=info "Run 'gh opencode pr --help' for usage information"
		exit 1
		;;
	esac
}
