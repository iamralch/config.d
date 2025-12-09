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
#   - nvim: Neovim editor (for gh-pr-create and gh-pr-review)
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
#   - gh-pr-select: Ctrl-K (checkout), Ctrl-M (merge), Ctrl-R (review), Ctrl-W (watch checks)
#   - gh-run-select: Ctrl-W to watch the selected workflow run
# ==============================================================================

# ------------------------------------------------------------------------------
# get-file-mtime
# ------------------------------------------------------------------------------
# Cross-platform file modification time function for save detection.
#
# Returns file modification time in seconds since epoch. This will change
# whenever the file is saved in an editor (even without content changes),
# making it suitable for detecting user interaction with the file.
#
# Parameters:
#   $1 (required): Path to file to check
#
# Output:
#   Unix timestamp (seconds since epoch)
#
# Platform Support:
#   - Linux: Uses stat -c "%Y"
#   - macOS: Uses stat -f "%m"
#   - Automatic detection with fallback
# ------------------------------------------------------------------------------
get-file-mtime() {
	stat -c "%Y" "$1" 2>/dev/null || stat -f "%m" "$1"
}

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
		gum log --level=warn "No GitHub Issues found"
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
#   - Ctrl-M: Merge the selected pull request (rebase and delete branch)
#   - Ctrl-O: Open selected PR in web browser
#   - Ctrl-R: Review the selected pull request (interactive editor)
#   - Ctrl-V: View selected PR in terminal
#   - Ctrl-W: Watch PR checks (live updates)
#   - Ctrl-Shift-W: Open PR checks in web browser
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
		gum log --level=warn "No GitHub Pull Requests found"
		return 1
	fi

	# Transform and present in fzf
	echo "$pr_list" | fzf --ansi \
		--with-nth=1.. \
		--accept-nth=1 \
		--header="  GitHub Pull Requests" \
		--color=header:blue \
		--bind 'ctrl-o:execute(gh pr view {1} --web)+abort' \
		--bind 'ctrl-w:execute(gh pr checks {1} --watch)+abort' \
		--bind 'ctrl-v:execute(gh pr view {1})+abort'
}

# ------------------------------------------------------------------------------
# gh-pr-review
# ------------------------------------------------------------------------------
# Interactive PR review submission using nvim editor integration.
#
# This function opens nvim for interactive review composition, with optional
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
#   - nvim: Neovim editor with markdown support
#   - gh: GitHub CLI (for gh pr review functionality)
#   - gum: For spinner visual feedback
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
#   2. nvim opens with markdown syntax highlighting (.md suffix)
#   3. User edits review content (or quits without saving to cancel)
#   4. If file is saved (detected via modification time) and not empty, submits via `gh pr review -c -F {file}`
#   5. Temporary files cleaned up automatically
# ------------------------------------------------------------------------------
gh-pr-review() {
	local input_content
	local target="$1"
	local temp_file
	local initial_mtime
	local final_mtime

	if [ -t 0 ]; then
		# No stdin - use default
		input_content="<!-- Write your code review below -->"
	else
		# Read from stdin
		input_content=$(cat)
	fi

	# Create temporary file with initial content
	temp_file=$(mktemp).md
	echo "$input_content" >"$temp_file"

	# Get initial modification time before editing
	initial_mtime=$(get-file-mtime "$temp_file")

	# Open in nvim for editing
	nvim "$temp_file"

	# Get final modification time after editing
	final_mtime=$(get-file-mtime "$temp_file")

	# Submit if file was saved (mtime changed) and file is not empty
	if [ "$initial_mtime" != "$final_mtime" ] && [ -s "$temp_file" ]; then
		gum spin --title "Creating GitHub Pull Request Review..." -- gh pr review "$target" -c -F "$temp_file"
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
	run_list=$(gum spin --title "Loading GitHub Runs..." -- gh run list --limit 30 --json databaseId,status,name,headBranch,headSha --jq '.[] | "\(.databaseId)\t\(.status)\t\(.name)\t\(.headBranch)\t\(.headSha[0:7])"' | column -t -s $'\t')

	# Check if we got any runs
	if [ -z "$run_list" ]; then
		gum log --level=warn "No GitHub Runs found"
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
# Create a GitHub pull request with interactive nvim editor integration.
#
# This function opens nvim for PR composition, with optional
# content from stdin as initial content. Extracts the first line as the PR title (if it
# starts with '#') and uses the full content as the PR body. Creates the PR from the
# specified source branch and automatically opens it in the web browser.
#
# The function follows the same pattern as gh-pr-review: reads from stdin, provides
# interactive editing with nvim, and submits only if content is modified.
#
# Parameters:
#   $1 (required): Source branch name for the pull request
#
# Input:
#   Markdown content from stdin (optional - uses default template if no stdin)
#
# Output:
#   Creates a GitHub pull request and opens it in web browser
#   Returns exit code from 'gh pr create' command
#
# Required Dependencies:
#   - gh: GitHub CLI (authenticated)
#   - nvim: Neovim editor with markdown support
#   - gum: For spinner visual feedback
#   - Access to current git repository with remote on GitHub
#
# Return Codes:
#   0: Success - PR created successfully
#   1: Cancelled - no changes made to template or editor error
#
# Example Usage:
#   gh-pr-create feature-branch                                    # Create PR with interactive editor
#   echo "# Fix bug" | gh-pr-create feature-branch                # Create PR with initial content
#   git diff main..feature | git-ai-describe | gh-pr-create feature-branch   # AI-assisted PR creation
#
# Integration with tig:
#   bind refs gC !zsh -i -c 'gh-pr-create %(branch)'
#   bind refs aC !zsh -i -c 'git diff main...%(branch) | git-ai-describe | gh-pr-create %(branch)'
#
# Interactive Workflow:
#   1. Input piped to function becomes initial content or default template is used
#   2. nvim opens with markdown syntax highlighting (.md suffix)
#   3. User edits PR content (or quits without saving to cancel)
#   4. Title extracted from first line if it starts with '#', fallback to "Pull Request from {branch}"
#   5. If file is saved (detected via modification time), creates PR with --head {branch} --web flags
#   6. Temporary files cleaned up automatically
#
# Error Conditions:
#   - Editor cancelled without saving changes
#   - GitHub CLI errors (authentication, repository access, etc.)
# ------------------------------------------------------------------------------
gh-pr-create() {
	local title
	local target="$1"
	local input_content
	local temp_file
	local initial_mtime
	local final_mtime

	# Read markdown content from stdin
	if [ -t 0 ]; then
		input_content="<!-- Write your GitHub Pull Request description below. -->"
	else
		input_content=$(cat)
	fi

	# Create temporary file with initial content
	temp_file=$(mktemp).md
	echo "$input_content" >"$temp_file"

	# Get initial modification time before editing
	initial_mtime=$(get-file-mtime "$temp_file")

	# Open in nvim for editing
	nvim "$temp_file"

	# Get final modification time after editing
	final_mtime=$(get-file-mtime "$temp_file")

	# Submit if file was saved (mtime changed) and file is not empty
	if [ "$initial_mtime" != "$final_mtime" ] && [ -s "$temp_file" ]; then
		# Extract title from first heading line, fallback to default if none found
		title=$(cat "$temp_file" | head -n 1 | sed -e "s/#\s*//")

		# Use fallback title if no heading found or title is empty
		if [ -z "$title" ]; then
			title="Pull Request from $target"
		fi

		# Create PR using GitHub CLI with extracted title and body
		# Pass through all additional arguments provided by user
		gum spin --title "Creating GitHub Pull Request..." -- gh pr create --head "$target" --title "$title" -F "$temp_file" --web
	else
		gum log --level=error "Creating GitHub Pull Request cancelled - file was not saved or is empty"
		rm -f "$temp_file"
		return 1
	fi

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
