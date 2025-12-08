#!/bin/bash

# ==============================================================================
# Git AI Utilities
# ==============================================================================
# Simple, composable shell functions for AI-powered git operations following
# Unix philosophy: do one thing well, work with text streams, compose via pipes.
#
# These functions read git diffs from stdin and output processed results to stdout,
# making them perfect for use in pipelines with standard git commands.
#
# Dependencies:
#   - opencode: AI-powered code assistant
#   - gum: A tool for glamorous shell scripts (for spinners)
#
# Authentication:
#   Requires opencode authentication and configuration:
#   - Properly configured opencode with model access
#   - Valid API credentials for the specified AI models
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/git.sh
#
# Philosophy:
#   Each function does ONE thing well and can be composed with pipes:
#   git diff --staged | git-ai-commit
#   git show HEAD | git-ai-explain
#   git diff main..feature | git-ai-review
# ==============================================================================

# ------------------------------------------------------------------------------
# git-ai-commit
# ------------------------------------------------------------------------------
# Generate AI-powered conventional commit messages from git diff input.
#
# This function reads a git diff from stdin and uses opencode with AI to generate
# a conventional commit message following the official specification. The output
# includes both subject line and body, formatted for direct use with git commit.
#
# The function follows Unix philosophy: reads from stdin, writes to stdout,
# does one thing well, and composes easily with other tools.
#
# Parameters:
#   MODEL (optional): AI model to use for message generation
#                    Default: "google/gemini-2.0-flash"
#                    Example: "anthropic/claude-haiku-3-5"
#
# Input:
#   Git diff content from stdin (patch format)
#
# Output:
#   Generated conventional commit message to stdout
#   Error messages to stderr
#
# Required Dependencies:
#   - opencode (for AI message generation)
#   - gum (for visual feedback)
#
# Required Setup:
#   - Authenticated opencode configuration
#   - Valid AI model access permissions
#
# Return Codes:
#   0: Success - commit message generated and output to stdout
#   1: Error - no input or generation failed
#
# Example:
#   git diff --staged | git-ai-commit                         # Default model
#   git show HEAD | git-ai-commit "anthropic/claude-haiku-3-5"  # Custom model
#   git diff main..feature | git-ai-commit > commit-msg.txt  # Save to file
#   git commit -F <(git diff --staged | git-ai-commit)       # Direct commit
#
# Pipeline Examples:
#   git diff --staged | git-ai-commit | head -n1            # Subject only
#   git diff HEAD~5..HEAD | git-ai-commit | tee commit.txt  # Save and display
# ------------------------------------------------------------------------------
git-ai-commit() {
  local model="${1:-google/gemini-2.0-flash}"
  local changes
  local raw_output
  local commit_message

  # Read diff from stdin
  if [ -t 0 ]; then
    echo "Error: No input provided. Please pipe git diff content." >&2
    echo "Example: git diff --staged | git-ai-commit" >&2
    return 1
  fi

  changes=$(cat)

  # Validate we got content
  if [ -z "$changes" ]; then
    echo "Error: No diff content received from stdin" >&2
    return 1
  fi

  # Load commit message prompt from file
  local prompt
  if ! prompt=$(_load_git_ai_prompt "git-ai-commit" "$changes"); then
    return 1
  fi

  # Generate commit message with visual feedback
  raw_output=$(gum spin --title "Generating commit message..." -- opencode run "$prompt" -m "$model")

  # Check if opencode command succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Failed to execute opencode command" >&2
    return 1
  fi

  # Validate we got output
  if [ -z "$raw_output" ]; then
    echo "Error: No output received from opencode" >&2
    return 1
  fi

  # Extract commit message from code block using awk
  commit_message=$(echo "$raw_output" | awk '/^```/{flag=!flag; next} flag')

  # Fallback: if no code block found, try to extract conventional commit pattern
  if [ -z "$commit_message" ]; then
    commit_message=$(echo "$raw_output" | grep -E '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)[:(!]' | head -n1)
  fi

  # Final validation
  if [ -z "$commit_message" ]; then
    echo "Error: Failed to extract commit message from AI response" >&2
    return 1
  fi

  # Output clean commit message to stdout
  echo "$commit_message"
}

# ------------------------------------------------------------------------------
# git-ai-explain
# ------------------------------------------------------------------------------
# Generate AI-powered explanations of git changes from diff input.
#
# This function reads a git diff from stdin and uses opencode with AI to generate
# a clear, human-readable explanation of what the changes accomplish, why they
# matter, and their potential impact. Perfect for understanding complex changes.
#
# The function follows Unix philosophy: reads from stdin, writes to stdout,
# does one thing well, and composes easily with other tools.
#
# Parameters:
#   MODEL (optional): AI model to use for explanation generation
#                    Default: "anthropic/claude-opus-4-5"
#                    Example: "google/gemini-2.0-flash"
#
# Input:
#   Git diff content from stdin (patch format)
#
# Output:
#   Human-readable explanation of changes to stdout
#   Error messages to stderr
#
# Required Dependencies:
#   - opencode (for AI explanation generation)
#   - gum (for visual feedback)
#
# Required Setup:
#   - Authenticated opencode configuration
#   - Valid AI model access permissions
#
# Return Codes:
#   0: Success - explanation generated and output to stdout
#   1: Error - no input or generation failed
#
# Example:
#   git diff --staged | git-ai-explain                       # Explain staged changes
#   git show HEAD | git-ai-explain "google/gemini-2.0-flash"  # Custom model
#   git diff main..feature | git-ai-explain > explanation.md # Save to file
#   git diff HEAD~3..HEAD | git-ai-explain | less           # Page through explanation
#
# Pipeline Examples:
#   git show HEAD | git-ai-explain | grep -i "security"     # Find security mentions
#   git diff --staged | tee changes.patch | git-ai-explain  # Save diff and explain
# ------------------------------------------------------------------------------
git-ai-explain() {
  local model="${1:-anthropic/claude-opus-4-5}"
  local changes
  local raw_output

  # Read diff from stdin
  if [ -t 0 ]; then
    echo "Error: No input provided. Please pipe git diff content." >&2
    echo "Example: git diff --staged | git-ai-explain" >&2
    return 1
  fi

  changes=$(cat)

  # Validate we got content
  if [ -z "$changes" ]; then
    echo "Error: No diff content received from stdin" >&2
    return 1
  fi

  # Load explanation prompt from file
  local prompt
  if ! prompt=$(_load_git_ai_prompt "git-ai-explain" "$changes"); then
    return 1
  fi

  # Generate explanation with visual feedback
  raw_output=$(gum spin --title "Generating explanation..." -- opencode run "$prompt" -m "$model")

  # Check if opencode command succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Failed to execute opencode command" >&2
    return 1
  fi

  # Validate we got output
  if [ -z "$raw_output" ]; then
    echo "Error: No output received from opencode" >&2
    return 1
  fi

  # Output explanation directly to stdout
  echo "$raw_output"
}

# ------------------------------------------------------------------------------
# git-ai-describe
# ------------------------------------------------------------------------------
# Generate AI-powered pull request descriptions from git diff input.
#
# This function reads a git diff from stdin and uses opencode with AI to generate
# professional, structured pull request descriptions following GitHub best
# practices. Perfect for creating comprehensive PR descriptions that explain
# what changed, why it changed, and the impact of the changes.
#
# The function follows Unix philosophy: reads from stdin, writes to stdout,
# does one thing well, and composes easily with other tools.
#
# Parameters:
#   MODEL (optional): AI model to use for description generation
#                    Default: "anthropic/claude-opus-4-5"
#                    Example: "google/gemini-2.0-flash"
#
# Input:
#   Git diff content from stdin (patch format)
#
# Output:
#   Professional pull request description to stdout
#   Error messages to stderr
#
# Required Dependencies:
#   - opencode (for AI description generation)
#   - gum (for visual feedback)
#
# Required Setup:
#   - Authenticated opencode configuration
#   - Valid AI model access permissions
#
# Return Codes:
#   0: Success - description generated and output to stdout
#   1: Error - no input or generation failed
#
# Example:
#   git diff main..feature | git-ai-describe                    # Generate PR description
#   git diff --staged | git-ai-describe "google/gemini-2.0-flash"  # Custom model
#   git diff HEAD~3..HEAD | git-ai-describe > pr-template.md   # Save to file
#   git diff origin/main..HEAD | git-ai-describe | less        # Page through description
#
# Pipeline Examples:
#   git diff main..feature | git-ai-describe | gh pr create --body-file - # Create PR with description
#   git diff --staged | tee changes.patch | git-ai-describe    # Save diff and describe
#   git log --oneline -n 5 && git diff HEAD~5..HEAD | git-ai-describe # Show commits and describe
# ------------------------------------------------------------------------------
git-ai-describe() {
  local model="${1:-anthropic/claude-opus-4-5}"
  local changes
  local raw_output

  # Read diff from stdin
  if [ -t 0 ]; then
    echo "Error: No input provided. Please pipe git diff content." >&2
    echo "Example: git diff main..feature | git-ai-describe" >&2
    return 1
  fi

  changes=$(cat)

  # Validate we got content
  if [ -z "$changes" ]; then
    echo "Error: No diff content received from stdin" >&2
    return 1
  fi

  # Load description prompt from file
  local prompt
  if ! prompt=$(_load_git_ai_prompt "git-ai-describe" "$changes"); then
    return 1
  fi

  # Generate description with visual feedback
  raw_output=$(gum spin --title "Generating PR description..." -- opencode run "$prompt" -m "$model")

  # Check if opencode command succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Failed to execute opencode command" >&2
    return 1
  fi

  # Validate we got output
  if [ -z "$raw_output" ]; then
    echo "Error: No output received from opencode" >&2
    return 1
  fi

  # Output description directly to stdout
  echo "$raw_output"
}

# ------------------------------------------------------------------------------
# git-ai-review
# ------------------------------------------------------------------------------
# Generate AI-powered code reviews from git diff input.
#
# This function reads a git diff from stdin and uses opencode with AI to provide
# comprehensive code review feedback including potential issues, improvements,
# best practices, and security concerns. Perfect for self-review before commits.
#
# The function follows Unix philosophy: reads from stdin, writes to stdout,
# does one thing well, and composes easily with other tools.
#
# Parameters:
#   MODEL (optional): AI model to use for review generation
#                    Default: "anthropic/claude-opus-4-5"
#                    Example: "google/gemini-2.0-flash"
#
# Input:
#   Git diff content from stdin (patch format)
#
# Output:
#   Comprehensive code review feedback to stdout
#   Error messages to stderr
#
# Required Dependencies:
#   - opencode (for AI review generation)
#   - gum (for visual feedback)
#
# Required Setup:
#   - Authenticated opencode configuration
#   - Valid AI model access permissions
#
# Return Codes:
#   0: Success - review generated and output to stdout
#   1: Error - no input or generation failed
#
# Example:
#   git diff --staged | git-ai-review                        # Review staged changes
#   git show HEAD | git-ai-review "google/gemini-2.0-flash"  # Custom model
#   git diff main..feature | git-ai-review > review.md      # Save review to file
#   git diff HEAD~3..HEAD | git-ai-review | grep -E "(Issue|Problem|Bug)"  # Find issues
#
# Pipeline Examples:
#   git diff --staged | git-ai-review | less                # Page through review
#   git show HEAD | tee last-commit.patch | git-ai-review   # Save diff and review
# ------------------------------------------------------------------------------
git-ai-review() {
  local model="${1:-anthropic/claude-opus-4-5}"
  local changes
  local raw_output

  # Read diff from stdin
  if [ -t 0 ]; then
    echo "Error: No input provided. Please pipe git diff content." >&2
    echo "Example: git diff --staged | git-ai-review" >&2
    return 1
  fi

  changes=$(cat)

  # Validate we got content
  if [ -z "$changes" ]; then
    echo "Error: No diff content received from stdin" >&2
    return 1
  fi

  # Load review prompt from file
  local prompt
  if ! prompt=$(_load_git_ai_prompt "git-ai-review" "$changes"); then
    return 1
  fi

  # Generate review with visual feedback
  raw_output=$(gum spin --title "Generating code review..." -- opencode run "$prompt" -m "$model")

  # Check if opencode command succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Failed to execute opencode command" >&2
    return 1
  fi

  # Validate we got output
  if [ -z "$raw_output" ]; then
    echo "Error: No output received from opencode" >&2
    return 1
  fi

  # Output review directly to stdout
  echo "$raw_output"
}

# ------------------------------------------------------------------------------
# git-commit
# ------------------------------------------------------------------------------
# Interactive git commit with optional content from stdin as initial message.
#
# This function allows for composing git commit messages interactively, with
# optional initial content from stdin. Always opens an editor for final message
# composition and commits with --signoff flag. Perfect for AI-generated commit
# messages that need manual review before committing.
#
# The function follows Unix philosophy: reads from stdin, composes with pipes,
# and provides a clean interactive editing experience for commit workflows.
#
# Parameters:
#   None
#
# Input:
#   Commit message content from stdin (optional - uses default template if no stdin)
#
# Output:
#   Creates a git commit if user saves content in editor
#
# Required Dependencies:
#   - git (for commit functionality)
#   - Editor set in $EDITOR environment variable (or system default)
#
# Required Setup:
#   - Must be run from within a git repository
#   - Repository should have staged changes to commit
#
# Return Codes:
#   0: Success - commit created or user cancelled gracefully
#   1: Error - git command failure or repository issues
#
# Example:
#   echo "Initial commit message" | git-commit              # Commit with initial content
#   git-commit                                              # Commit with default template
#   git-ai-commit staged | git-commit                       # AI-generated message for review
#   git diff --staged | git-ai-commit | git-commit         # Full AI-assisted commit workflow
#
# Pipeline Examples:
#   git-ai-commit staged | git-commit                       # Review AI commit message
#   echo "feat: add new feature" | git-commit               # Commit with initial message
#
# Interactive Workflow:
#   1. Input piped to function becomes initial content or default template is used
#   2. Editor opens with commit message template (.gitcommit suffix)
#   3. User edits commit message (or quits without saving to cancel)
#   4. If user saves, creates commit with --signoff flag
#   5. Temporary files cleaned up automatically
# ------------------------------------------------------------------------------
git-commit() {
  local input_content
  local temp_file

  if [ -t 0 ]; then
    # No stdin - use default
    input_content="<!-- Write your commit message below -->"
  else
    # Read from stdin
    input_content=$(cat)
  fi

  # Create temporary file and edit
  temp_file=$(mktemp).gitcommit
  echo "$input_content" >"$temp_file"

  # Submit only if content changed and file is not empty
  git commit --signoff --edit -F "$temp_file"
  rm -f "$temp_file"
}

# ------------------------------------------------------------------------------
# git-br-delete
# ------------------------------------------------------------------------------
# Delete git branch locally and remotely from tig interface.
#
# Designed for use with tig keybinding where branch name is provided via %(branch).
# Performs essential safety checks and confirms deletion before proceeding.
#
# Parameters:
#   BRANCH (required): Name of branch to delete (provided by tig via %(branch))
#
# Usage from tig:
#   bind refs gX !zsh -i -c 'git-br-delete %(branch)' # Delete branch locally and on GitHub
#
# Safety Features:
#   - Prevents deletion of protected branches (main, master, develop)
#   - Prevents deletion of current branch
#   - Confirms before destructive operations
#
# Return Codes:
#   0: Success - branch deleted successfully
#   1: Error - validation failed, user cancelled, or git command failed
# ------------------------------------------------------------------------------
git-br-delete() {
  local branch="$1"
  local protected_branches="main master develop"

  # Validate branch parameter
  if [[ -z "$branch" ]]; then
    echo "Error: Branch name required" >&2
    return 1
  fi

  # Check for protected branches
  if echo "$protected_branches" | grep -q "\b$branch\b"; then
    echo "Error: Cannot delete protected branch '$branch'" >&2
    return 1
  fi

  # Check if trying to delete current branch
  local current_branch
  current_branch=$(git branch --show-current)
  if [[ "$branch" == "$current_branch" ]]; then
    echo "Error: Cannot delete current branch '$branch'" >&2
    echo "Switch to another branch first" >&2
    return 1
  fi

  # Check if branch exists locally
  local local_exists=false
  if git branch --list "$branch" | grep -q "^"; then
    local_exists=true
  fi

  # Check if branch exists remotely
  local remote_exists=false
  if git branch -r --list "origin/$branch" | grep -q "^"; then
    remote_exists=true
  fi

  # Validate branch exists somewhere
  if [[ "$local_exists" == false && "$remote_exists" == false ]]; then
    echo "Error: Branch '$branch' does not exist" >&2
    return 1
  fi

  # Confirm deletion
  if ! gum confirm "Delete branch '$branch' locally and remotely?"; then
    echo "Cancelled"
    return 1
  fi

  local errors=0

  # Delete local branch if it exists
  if [[ "$local_exists" == true ]]; then
    if gum spin --title "Deleting local branch '$branch'..." -- git branch -D "$branch" 2>/dev/null; then
      echo "✓ Deleted local branch '$branch'"
    else
      echo "✗ Failed to delete local branch '$branch'" >&2
      ((errors++))
    fi
  fi

  # Delete remote branch if it exists
  if [[ "$remote_exists" == true ]]; then
    if gum spin --title "Deleting remote branch '$branch'..." -- git push origin --delete "$branch" 2>/dev/null; then
      echo "✓ Deleted remote branch '$branch'"
    else
      echo "✗ Failed to delete remote branch '$branch'" >&2
      ((errors++))
    fi
  fi

  if [[ $errors -eq 0 ]]; then
    echo "✓ Branch '$branch' deleted successfully"
    return 0
  else
    return 1
  fi
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# _load_git_ai_prompt
# ------------------------------------------------------------------------------
# Load and substitute variables in AI prompt files
# Parameters:
#   $1: prompt file name (e.g., "git-ai-commit")
#   $2: changes content to substitute
_load_git_ai_prompt() {
  local prompt_name="$1"
  local changes="$2"
  local prompt_file="$HOME/.config/zsh/prompts/${prompt_name}.md"

  # Check if prompt file exists
  if [ ! -f "$prompt_file" ]; then
    echo "Error: Prompt file not found: $prompt_file" >&2
    return 1
  fi

  # Load prompt template and substitute variables using a more robust approach
  # Create a temporary file with the changes to avoid sed escaping issues
  local temp_file
  temp_file=$(mktemp)
  echo "$changes" >"$temp_file"

  # Use awk to replace ${CHANGES} with the file content
  awk -v changes_file="$temp_file" '
		/\${CHANGES}/ {
			while ((getline line < changes_file) > 0) {
				print line
			}
			close(changes_file)
			next
		}
		{ print }
	' "$prompt_file"

  # Clean up temp file
  rm "$temp_file"
}
