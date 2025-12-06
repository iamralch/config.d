#!/bin/bash

# ==============================================================================
# Git Utilities
# ==============================================================================
# Shell functions for AI-powered git operations and workflow automation
# using opencode for intelligent commit message generation following the
# Conventional Commits specification.
#
# Dependencies:
#   - git: Git version control system
#   - opencode: AI-powered code assistant
#   - gum: A tool for glamorous shell scripts (provides spinner)
#
# Authentication:
#   Requires opencode authentication and configuration:
#   - Properly configured opencode with model access
#   - Valid API credentials for the specified AI models
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/git.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# git-commit-message
# ------------------------------------------------------------------------------
# Generate AI-powered conventional commit messages with body from staged changes.
#
# This function analyzes staged git changes and uses opencode with AI to 
# generate a complete conventional commit message including both subject and body
# following the official specification. The generated message includes proper 
# type classification, optional scope, descriptive body content, and follows 
# best practices for imperative mood and character limits.
#
# The function uses real examples from the Conventional Commits specification
# to ensure high-quality, consistent output that complies with industry
# standards and semantic versioning principles.
#
# Parameters:
#   MODEL (optional): AI model to use for message generation
#                    Default: "github-copilot/claude-sonnet-4"
#                    Example: "anthropic/claude-haiku-3-5"
#                    Example: "github-copilot/gpt-4o"
#
# Output:
#   Generated conventional commit message with subject and body to stdout
#   Multi-line output with proper formatting for git commit
#   Error messages and warnings to stderr
#
# Required Dependencies:
#   - git (for repository operations and diff generation)
#   - opencode (for AI message generation)
#   - gum (for visual feedback and user experience)
#
# Required Setup:
#   - Git repository with staged changes
#   - Authenticated opencode configuration
#   - Valid AI model access permissions
#
# Return Codes:
#   0: Success - commit message generated and output to stdout
#   1: Error - dependency missing, no staged changes, or generation failed
#
# Example:
#   git-commit-message                                        # Use default model
#   git-commit-message "anthropic/claude-haiku-3-5"          # Use specific model  
#   git-commit-message "github-copilot/gpt-4o"               # Use different provider
#   git commit -F <(git-commit-message)                      # Direct commit with body
#   git-commit-message > /tmp/commit-msg && git commit -F /tmp/commit-msg  # Edit before use
#
# Troubleshooting:
#   - "Not in a git repository": Run from within a git repository
#   - "No staged changes found": Use `git add` to stage files before running
#   - "opencode command not found": Install and configure opencode
#   - "gum command not found": Install gum or function will work without spinners
#   - "Failed to generate commit message": Check opencode authentication and model access
# ------------------------------------------------------------------------------
git-commit-message() {
	local model="${1:-github-copilot/claude-sonnet-4}"
	local changes
	local raw_output
	local commit_message
	local use_gum=true

	# Check if gum is available for visual feedback
	if ! command -v gum >/dev/null 2>&1; then
		use_gum=false
		echo "Warning: gum not found - continuing without visual feedback" >&2
	fi

	# Validation: Check for git repository
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		echo "Error: Not in a git repository" >&2
		echo "Please run this command from within a git repository." >&2
		return 1
	fi

	# Validation: Check for opencode
	if ! command -v opencode >/dev/null 2>&1; then
		echo "Error: opencode command not found" >&2
		echo "Please install and configure opencode: https://opencode.dev" >&2
		return 1
	fi

	# Validation: Check for staged changes
	if git diff --staged --quiet; then
		echo "Error: No staged changes found" >&2
		echo "Use 'git add <files>' to stage changes before generating commit message." >&2
		return 1
	fi

	# Get staged changes with optional visual feedback
	if [ "$use_gum" = true ]; then
		changes=$(gum spin --title "Analyzing staged changes..." -- git diff --staged --patch)
	else
		echo "Analyzing staged changes..." >&2
		changes=$(git diff --staged --patch)
	fi

	# Validate we got diff content
	if [ -z "$changes" ]; then
		echo "Error: Unable to retrieve staged changes" >&2
		return 1
	fi

	# Generate commit message using Option C: Examples + Spec approach with body
	local prompt="Generate a conventional commit message with both subject and body following the official specification format:

<type>[optional scope]: <description>

[optional body]

Examples from spec:
• feat: allow provided config object to extend other configs

BREAKING CHANGE: \`extends\` key in config file is now used for extending other config files

• fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

• docs: correct spelling of CHANGELOG
• feat(lang): add Polish language

Add support for Polish language with proper translations
and locale-specific formatting rules.

• feat!: send an email when product is shipped (breaking)

Automatically send notification emails to customers when
their orders are shipped with tracking information.

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
Rules: 
- Subject: imperative mood, lowercase, under 72 chars, ! for breaking changes
- Body: explain what and why vs how, wrap at 72 chars
- Leave blank line between subject and body

Return the complete message (subject + blank line + body) in a code block.

Git diff:
$changes"

	# Generate commit message with optional visual feedback
	if [ "$use_gum" = true ]; then
		raw_output=$(gum spin --title "Generating commit message..." -- opencode run "$prompt" -m "$model")
	else
		echo "Generating commit message with model: $model..." >&2
		raw_output=$(opencode run "$prompt" -m "$model")
	fi

	# Check if opencode command succeeded
	if [ $? -ne 0 ]; then
		echo "Error: Failed to execute opencode command" >&2
		echo "Check your opencode configuration and model access." >&2
		return 1
	fi

	# Validate we got output from opencode
	if [ -z "$raw_output" ]; then
		echo "Error: No output received from opencode" >&2
		return 1
	fi

	# Extract complete commit message (subject + body) from code block using awk
	commit_message=$(echo "$raw_output" | awk '/^```/{flag=!flag; next} flag')

	# Fallback: if no code block found, try to extract complete conventional commit
	if [ -z "$commit_message" ]; then
		# Look for lines starting with conventional commit types
		local subject_line=$(echo "$raw_output" | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)[:(!]' | head -n1)
		if [ -n "$subject_line" ]; then
			# For fallback, just use the subject line without body
			commit_message="$subject_line"
		fi
	fi

	# Final validation that we got a commit message
	if [ -z "$commit_message" ]; then
		echo "Error: Failed to extract commit message from AI response" >&2
		echo "Raw output was:" >&2
		echo "$raw_output" >&2
		return 1
	fi

	# Trim any leading/trailing whitespace
	commit_message=$(echo "$commit_message" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

	# Output the clean commit message
	echo "$commit_message"
}