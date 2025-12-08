#!/bin/bash

# ==============================================================================
# GitHub CLI Utilities
# ==============================================================================
# Shell functions for interactively working with GitHub issues, pull requests,
# and workflow runs using fuzzy finding (fzf) with visual feedback via gum
# spinner.
#
# Dependencies:
#   - gh: GitHub CLI
#   - fzf: Fuzzy finder for terminal
#   - gum: A tool for glamorous shell scripts (provides spinner)
#
# Authentication:
#   Requires GitHub CLI authentication:
#   - gh auth login
#   - GITHUB_TOKEN environment variable
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/gh.sh
#
# Keybindings:
#   All functions support interactive selection with fzf and these keybindings:
#   - Enter: Select item and return its number/ID
#   - Escape/Ctrl-C: Cancel selection
#   - Ctrl-O: Open selected item in web browser
#   - Ctrl-V: View selected item in terminal
#
#   Function-specific keybindings:
#   - gh-pr-select: Ctrl-K to checkout the selected pull request
#   - gh-run-select: Ctrl-W to watch the selected workflow run
# ==============================================================================

# ------------------------------------------------------------------------------
# gh-issue-select
# ------------------------------------------------------------------------------
# Interactively select a GitHub issue using fzf.
#
# This function retrieves issues from the current repository and presents them
# in an interactive fuzzy finder with detailed information including number,
# state, title, author, and creation date.
#
# The output format is optimized for both human readability and parsing:
# - Column 1: Issue number (#123)
# - Column 2: State ([open] or [closed])
# - Column 3: Issue title
# - Column 4: Author and relative date
#
# Output:
#   The selected issue number to stdout (e.g., "123")
#   Returns nothing if no selection made
#
# Required Permissions:
#   - Repository read access
#
# Keybindings:
#   - Enter: Select issue and return its number
#   - Escape/Ctrl-C: Cancel selection
#   - Ctrl-O: Open selected issue in web browser
#   - Ctrl-V: View selected issue in terminal
#
# Example:
#   gh-issue-select | xargs gh issue view
#   gh issue view $(gh-issue-select)
#   issue=$(gh-issue-select) && gh issue view "$issue" --web
# ------------------------------------------------------------------------------
gh-issue-select() {
	local issue_list

	# Query GitHub for issues with spinner feedback
	# Format: number | state | title | author | created_at
	issue_list=$(gum spin --title "Loading GitHub Issues..." -- gh issue list --limit 30 --json number,state,title,author,createdAt --jq '.[] | "\(.number)\t\(.state)\t\(.title)\t\(.author.login)\t\(.createdAt)"' | column -t -s $'\t')

	# Check if we got any issues
	if [ -z "$issue_list" ]; then
		echo "No GitHub issues found" >&2
		return 1
	fi

	# Transform and present in fzf
	echo "$issue_list" | fzf --ansi \
		--with-nth=2.. \
		--accept-nth=1 \
		--header="  GitHub Issues" \
		--color=header:blue \
		--bind 'ctrl-o:execute(gh issue view {1} --web)+abort' \
		--bind 'ctrl-v:execute(gh issue view {1})+abort'
}

# ------------------------------------------------------------------------------
# gh-pr-select
# ------------------------------------------------------------------------------
# Interactively select a GitHub pull request using fzf.
#
# This function retrieves pull requests from the current repository and
# presents them in an interactive fuzzy finder with detailed information
# including number, state, title, branch, author, and creation date.
#
# The output format is optimized for both human readability and parsing:
# - Column 1: PR number (#456)
# - Column 2: State ([open], [closed], or [merged])
# - Column 3: PR title
# - Column 4: Branch name
# - Column 5: Author and relative date
#
# Output:
#   The selected PR number to stdout (e.g., "456")
#   Returns nothing if no selection made
#
# Required Permissions:
#   - Repository read access
#
# Keybindings:
#   - Enter: Select PR and return its number
#   - Escape/Ctrl-C: Cancel selection
#   - Ctrl-K: Checkout the selected pull request branch
#   - Ctrl-O: Open selected PR in web browser
#   - Ctrl-V: View selected PR in terminal
#
# Example:
#   gh-pr-select | xargs gh pr view
#   gh pr view $(gh-pr-select)
#   pr=$(gh-pr-select) && gh pr view "$pr" --web
# ------------------------------------------------------------------------------
gh-pr-select() {
	local pr_list

	# Query GitHub for pull requests with spinner feedback
	# Format: number | state | title | branch | author | created_at
	pr_list=$(gum spin --title "Loading GitHub Pull Requests..." -- gh pr list --limit 30 --json number,state,title,headRefName,author,createdAt --jq '.[] | "\(.number)\t\(.state)\t\(.title)\t\(.headRefName)\t\(.author.login)\t\(.createdAt)"' | column -t -s $'\t')

	# Check if we got any PRs
	if [ -z "$pr_list" ]; then
		echo "No GitHub pull requests found" >&2
		return 1
	fi

	# Transform and present in fzf
	echo "$pr_list" | fzf --ansi \
		--with-nth=1.. \
		--accept-nth=1 \
		--header="  GitHub Pull Requests" \
		--color=header:blue \
		--bind 'ctrl-k:execute(gh pr checkout {1})+abort' \
		--bind 'ctrl-o:execute(gh pr view {1} --web)+abort' \
		--bind 'ctrl-v:execute(gh pr view {1})+abort'
}

# ------------------------------------------------------------------------------
# gh-pr-review
# ------------------------------------------------------------------------------
# Interactive PR review submission using editor integration.
#
# This function opens an editor for interactive review composition, with optional
# content from stdin as initial content. Uses markdown syntax highlighting and
# submits the final review via `gh pr review` only if content is modified. Perfect
# for editing AI-generated reviews before submission or creating reviews from scratch.
#
# The function follows Unix philosophy: reads from stdin, composes with pipes,
# and provides a clean interactive editing experience for code review workflows.
#
# Parameters:
#   $1 (required): Branch name or PR number to review
#
# Input:
#   Review content from stdin (optional - uses default template if no stdin)
#
# Output:
#   Submits review via `gh pr review` command if content is modified
#
# Required Dependencies:
#   - vipe (from moreutils package for interactive editing)
#   - gh CLI (for gh pr review functionality)
#
# Required Setup:
#   - Authenticated gh CLI configuration
#   - Must be run from within a repository with an active PR
#
# Return Codes:
#   0: Success - review submitted or user cancelled gracefully
#   1: Error - editor or submission failure
#
# Example:
#   echo "LGTM! Great work." | gh-pr-review 123               # Review PR #123 with initial content
#   echo "Great work!" | gh-pr-review main                    # Review PR for main branch
#   gh-pr-review 456                                          # Review PR #456 with default template
#   git diff main..feature | git-ai-review | gh-pr-review feature  # Review feature branch
#
# Pipeline Examples:
#   git-ai-review < changes.patch | gh-pr-review 456          # Review specific PR
#   git show HEAD | git-ai-review | gh-pr-review main         # Review main branch PR
#
# Interactive Workflow:
#   1. Input piped to function becomes initial content or default template is used
#   2. Editor opens with markdown syntax highlighting (.md suffix)
#   3. User edits review content (or quits without saving to cancel)
#   4. If content is modified and not empty, submits via `gh pr review -c -F $(file)`
#   5. Temporary files cleaned up automatically
# ------------------------------------------------------------------------------
gh-pr-review() {
	local input_content
	local target="$1"
	local temp_file
	local input_hash
	local output_hash

	if [ -t 0 ]; then
		# No stdin - use default
		input_content="<!-- Write your code review below -->"
	else
		# Read from stdin
		input_content=$(cat)
	fi

	# Calculate hash of input content
	input_hash=$(echo "$input_content" | md5sum | awk '{print $1}')

	# Create temporary file and edit
	temp_file=$(mktemp).md
	echo "$input_content" | vipe --suffix=md >"$temp_file"

	# Calculate hash of edited content
	output_hash=$(md5sum "$temp_file" | awk '{print $1}')

	# Submit only if content changed and file is not empty
	if [ "$input_hash" != "$output_hash" ] && [ -s "$temp_file" ]; then
		gh pr review "$target" -c -F "$temp_file"
	fi

	rm -f "$temp_file"
}

# ------------------------------------------------------------------------------
# gh-run-select
# ------------------------------------------------------------------------------
# Interactively select a GitHub Actions workflow run using fzf.
#
# This function retrieves recent workflow runs from the current repository
# and presents them in an interactive fuzzy finder with detailed information
# including status, workflow name, branch, and commit details.
#
# The output format is optimized for both human readability and parsing:
# - Column 1: Status icon (✓ success, ✗ failure, ⊙ in_progress, etc.)
# - Column 2: Workflow name
# - Column 3: Branch name
# - Column 4: Commit SHA (short)
# - Column 5: Run ID (used for selection)
#
# Status Icons:
#   ✓ - completed/success
#   ✗ - failure/failed
#   ⊙ - in_progress
#   ◷ - queued
#   ⊘ - cancelled
#
# Output:
#   The selected run ID to stdout (e.g., "1234567890")
#   Returns nothing if no selection made
#
# Required Permissions:
#   - actions:read (repository scope)
#
# Keybindings:
#   - Enter: Select run and return its ID
#   - Escape/Ctrl-C: Cancel selection
#   - Ctrl-O: Open selected run in web browser
#   - Ctrl-V: View selected run in terminal
#   - Ctrl-W: Watch the selected workflow run (live updates)
#
# Example:
#   gh-run-select | xargs gh run view
#   gh run view $(gh-run-select)
#   run=$(gh-run-select) && gh run view "$run" --web
# ------------------------------------------------------------------------------
gh-run-select() {
	local run_list

	# Query GitHub for recent workflow runs with spinner feedback
	# Format: status | workflow_name | branch | commit_sha | run_id
	run_list=$(gum spin --title "Loading GitHub runs..." -- gh run list --limit 30 --json databaseId,status,name,headBranch,headSha --jq '.[] | "\(.databaseId)\t\(.status)\t\(.name)\t\(.headBranch)\t\(.headSha[0:7])"' | column -t -s $'\t')

	# Check if we got any runs
	if [ -z "$run_list" ]; then
		echo "No GitHub runs found" >&2
		return 1
	fi

	# Transform status to icons and present in fzf
	echo "$run_list" | fzf --ansi \
		--with-nth=1.. \
		--accept-nth=1 \
		--header="  GitHub Actions Runs" \
		--color=header:blue \
		--bind 'ctrl-o:execute(gh run view {1} --web)+abort' \
		--bind 'ctrl-v:execute(gh run view {1})+abort' \
		--bind 'ctrl-w:execute(gh run watch {1})+abort'
}

# ------------------------------------------------------------------------------
# gh-pr-create
# ------------------------------------------------------------------------------
# Create a GitHub pull request from AI-generated markdown content.
#
# This function reads markdown content from stdin (typically output from
# git-ai-describe), extracts the first heading as the PR title and the
# remaining content as the PR body, then creates a GitHub pull request
# using the GitHub CLI.
#
# The function expects markdown content with the following structure:
# - First line starting with '#' becomes the PR title (# removed)
# - All content after the first '#' line becomes the PR body
# - Supports all standard 'gh pr create' arguments via "$@"
#
# Input Format:
#   Markdown content from stdin with structure like:
#   # Fix authentication bug in user login
#
#   ## Summary
#   This change resolves...
#   [rest of markdown content]
#
# Output:
#   Creates a GitHub pull request and displays the result
#   Returns exit code from 'gh pr create' command
#
# Required Dependencies:
#   - gh: GitHub CLI (authenticated)
#   - Access to current git repository with remote on GitHub
#
# Arguments:
#   All arguments are passed directly to 'gh pr create'
#   Common useful arguments:
#   - --assignee @me: Assign PR to yourself
#   - --web: Open PR in web browser after creation
#   - --draft: Create as draft PR
#   - --reviewer user: Add reviewer
#
# Example Usage:
#   git diff main..feature | git-ai-describe | gh-pr-create
#   git diff main..feature | git-ai-describe | gh-pr-create --assignee @me --web
#   git diff main..feature | git-ai-describe | gh-pr-create --draft
#
# Integration with tig:
#   bind status aC !zsh -i -c 'git diff --staged | git-ai-describe | gh-pr-create --assignee @me --web'
#
# Error Conditions:
#   - No input provided (stdin is empty)
#   - No heading found in markdown content
#   - GitHub CLI errors (authentication, repository access, etc.)
# ------------------------------------------------------------------------------
gh-pr-create() {
	local body
	local temp_file

	# Read markdown content from stdin
	if [ -t 0 ]; then
		body="<!-- Write your GitHub Pull Request description below -->"
	else
		body=$(cat)
	fi

	temp_file=$(mktemp).md
	echo "$body" >"$temp_file"

	# Create PR using GitHub CLI with extracted title and body
	# Pass through all additional arguments
	gum spin --title "Creating GitHub Pull Request..." -- gh pr create -F "$temp_file" "$@"
	rm -f "$temp_file"
}

# ------------------------------------------------------------------------------
# gh-browse-url
# ------------------------------------------------------------------------------
# Generate GitHub URLs using gh browse with visual feedback.
#
# This function wraps `gh browse -n` with a gum spinner for visual feedback
# during GitHub API calls. It outputs the generated URL to stdout, making it
# suitable for piping to other commands like pbcopy, or for use in scripts.
#
# The function accepts all arguments that `gh browse` supports, making it
# versatile for various GitHub URL generation scenarios including commits,
# branches, files, and line-specific links.
#
# Arguments:
#   All arguments passed directly to `gh browse -n`
#   Common patterns:
#   - COMMIT_SHA: Generate URL for specific commit
#   - --branch BRANCH_NAME: Generate URL for branch
#   - FILE_PATH: Generate URL for file
#   - FILE_PATH:LINE_NUMBER: Generate URL for specific line
#
# Output:
#   GitHub URL to stdout
#   Gum spinner feedback during API call
#   Returns same exit code as `gh browse`
#
# Required Dependencies:
#   - gh: GitHub CLI (authenticated)
#   - gum: For spinner visual feedback
#
# Example Usage:
#   gh-browse-url abc123                           # Output commit URL
#   gh-browse-url --branch feature/auth            # Output branch URL
#   gh-browse-url src/main.js:42 | pbcopy          # Copy line URL to clipboard
#   echo $(gh-browse-url README.md)                # Store file URL in variable
#
# Integration Examples:
#   # Tig keybinding usage
#   bind main gY !zsh -i -c 'gh-browse-url %(commit) | pbcopy'
#   bind refs gY !zsh -i -c 'gh-browse-url --branch %(branch) | pbcopy'
#
#   # Script usage
#   url=$(gh-browse-url $(git rev-parse HEAD))     # Get current commit URL
#   gh-browse-url --branch main | xargs open       # Open main branch in browser
# ------------------------------------------------------------------------------
gh-browse-url() {
	gum spin --title "Getting GitHub URL..." -- gh browse -n "$@"
}
