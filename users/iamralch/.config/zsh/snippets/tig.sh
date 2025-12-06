#!/bin/bash

# ------------------------------------------------------------------------------
# tig-ai-commit (Public Operation)
# ------------------------------------------------------------------------------
# Generate AI-powered commit messages for tig integration.
# Outputs plain text suitable for git commit -F usage. Does not use glow
# display as commit messages are meant for programmatic consumption.
#
# Parameters:
#   $1: context - "staged" for staged changes, "commit" for specific commit
#   $2: commit  - commit hash/ref (when context="commit", defaults to HEAD)
#   $3: model   - optional AI model override
#
# Output:
#   Generated commit message to stdout
#   Error messages to stderr
#
# Example Usage:
#   tig-ai-commit staged                    # Commit message for staged changes
#   tig-ai-commit commit HEAD              # Commit message for HEAD commit
#   tig-ai-commit staged "" custom-model   # Custom model for staged changes
# ------------------------------------------------------------------------------
tig-ai-commit() {
    local context="$1"
    local commit="$2"
    local model="$3"

    _tig_ai_source "$context" "$commit" | git-ai-commit "$model"
}

# ------------------------------------------------------------------------------
# tig-ai-explain (Public Operation)
# ------------------------------------------------------------------------------
# Generate AI-powered explanations of git changes with glow display.
# Creates human-readable explanations of code changes and displays them
# using glow for optimal readability within tig.
#
# Parameters:
#   $1: context - "staged" for staged changes, "commit" for specific commit
#   $2: commit  - commit hash/ref (when context="commit", defaults to HEAD)
#   $3: model   - optional AI model override
#
# Side Effects:
#   Displays explanation using glow in temporary file
#   Temporary file cleanup handled automatically
#
# Example Usage:
#   tig-ai-explain staged                   # Explain staged changes
#   tig-ai-explain commit abc123           # Explain specific commit
#   tig-ai-explain commit HEAD custom-model # Custom model for HEAD
# ------------------------------------------------------------------------------
tig-ai-explain() {
    local context="$1"
    local commit="$2"
    local model="$3"

    local content
    content=$(_tig_ai_source "$context" "$commit" | git-ai-explain "$model")
    _tig_ai_display "$content"
}

# ------------------------------------------------------------------------------
# tig-ai-review (Public Operation)
# ------------------------------------------------------------------------------
# Generate AI-powered code reviews with glow display.
# Creates comprehensive code reviews of git changes and displays them
# using glow for optimal readability within tig.
#
# Parameters:
#   $1: context - "staged" for staged changes, "commit" for specific commit
#   $2: commit  - commit hash/ref (when context="commit", defaults to HEAD)
#   $3: model   - optional AI model override
#
# Side Effects:
#   Displays review using glow in temporary file
#   Temporary file cleanup handled automatically
#
# Example Usage:
#   tig-ai-review staged                    # Review staged changes
#   tig-ai-review commit abc123            # Review specific commit
#   tig-ai-review commit HEAD custom-model # Custom model for HEAD
# ------------------------------------------------------------------------------
tig-ai-review() {
    local context="$1"
    local commit="$2"
    local model="$3"
    local content
    content=$(_tig_ai_source "$context" "$commit" | git-ai-review "$model")
    _tig_ai_display "$content"
}

# ==============================================================================
# Tig AI Integration Functions
# ==============================================================================
# Specialized functions for AI-powered git operations within tig
# Depends on: git-ai-* functions from ~/.config/zsh/snippets/git.sh
#
# This file provides a clean interface between tig keybindings and the core
# git-ai-* functions, handling temp file management and glow display for
# optimal user experience within tig.
#
# Private Functions (prefixed with _):
#   _tig_ai_source   - Get git content (staged changes or specific commit)
#   _tig_ai_display  - Handle temp file creation and glow display
#
# Public Functions:
#   tig-ai-commit    - Generate commit messages (plain text output)
#   tig-ai-explain   - Explain changes with glow display
#   tig-ai-review    - Review code with glow display
# ==============================================================================

# ------------------------------------------------------------------------------
# _tig_ai_source (Private Helper)
# ------------------------------------------------------------------------------
# Retrieves git content based on context (staged changes or specific commit).
# This function abstracts the git command differences between staged changes
# and commit viewing, providing a consistent interface for AI operations.
#
# Parameters:
#   $1: context - "staged" for staged changes, "commit" for specific commit
#   $2: commit  - commit hash/ref (only used when context="commit", defaults to HEAD)
#
# Output:
#   Git diff content to stdout
#   Error messages to stderr
#
# Return Codes:
#   0: Success - git content retrieved
#   1: Error - invalid context or git command failed
# ------------------------------------------------------------------------------
_tig_ai_source() {
    local context="$1"
    local commit="$2"

    case "$context" in
    "staged")
        git diff --staged
        ;;
    "commit")
        git show "${commit:-HEAD}"
        ;;
    *)
        echo "Error: Invalid context '$context'. Use 'staged' or 'commit'." >&2
        return 1
        ;;
    esac
}

# ------------------------------------------------------------------------------
# _tig_ai_display (Private Helper)
# ------------------------------------------------------------------------------
# Handles temporary file creation and glow display for AI-generated content.
# Creates a markdown temp file, writes content to it, displays with glow,
# and cleans up automatically. This ensures glow works optimally with actual
# files on disk rather than piped content.
#
# Parameters:
#   $1: content - The AI-generated content to display
#
# Side Effects:
#   Creates and removes temporary .md file
#   Displays content using glow with theme
#
# Dependencies:
#   glow - for markdown rendering and display
# ------------------------------------------------------------------------------
_tig_ai_display() {
    local content="$1"
    local temp_file
    temp_file=$(mktemp).md

    echo "$content" >"$temp_file"
    glow -t "$temp_file"
    rm "$temp_file"
}
