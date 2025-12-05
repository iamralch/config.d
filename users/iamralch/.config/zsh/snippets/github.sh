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
# Example:
#   gh-issue-select | xargs gh issue view
#   gh issue view $(gh-issue-select)
#   issue=$(gh-issue-select) && gh issue view "$issue" --web
# ------------------------------------------------------------------------------
gh-issue-select() {
	local issue_list

	# Query GitHub for issues with spinner feedback
	# Format: number | state | title | author | created_at
	issue_list=$(gum spin --title "Loading GitHub issues..." -- gh issue list --limit 30 --json number,state,title,author,createdAt --jq '.[] | "\(.number)\t\(.state)\t\(.title)\t\(.author.login)\t\(.createdAt)"' | column -t -s $'\t')

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
# Example:
#   gh-pr-select | xargs gh pr view
#   gh pr view $(gh-pr-select)
#   pr=$(gh-pr-select) && gh pr view "$pr" --web
# ------------------------------------------------------------------------------
gh-pr-select() {
	local pr_list

	# Query GitHub for pull requests with spinner feedback
	# Format: number | state | title | branch | author | created_at
	pr_list=$(gum spin --title "Loading GitHub pull requests..." -- gh pr list --limit 30 --json number,state,title,headRefName,author,createdAt --jq '.[] | "\(.number)\t\(.state)\t\(.title)\t\(.headRefName)\t\(.author.login)\t\(.createdAt)"' | column -t -s $'\t')

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
		--bind 'ctrl-o:execute(gh pr view {1} --web)+abort' \
		--bind 'ctrl-v:execute(gh pr view {1})+abort'
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
