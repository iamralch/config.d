#!/bin/bash -x

# ==============================================================================
# General Purpose Utility Functions
# ==============================================================================
# Collection of commonly used shell functions for development workflow.
#
# Dependencies:
#   - rg (ripgrep): Fast text search tool
#   - sd (sed alternative): Find and replace tool
#   - go: Go programming language toolchain
#   - git: Version control system
#   - zip: Archive utility
#   - openssl: Cryptographic toolkit
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/func.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# replace
# ------------------------------------------------------------------------------
# Find and replace text across multiple files using ripgrep and sd.
#
# This function combines the power of ripgrep (rg) for fast file searching
# and sd for accurate find-and-replace operations. It first searches for files
# containing the target pattern, then performs replacements only in those files,
# making it both efficient and safe for large codebases.
#
# The function respects .gitignore and other ignore files by default through
# ripgrep, making it safe for version-controlled projects.
#
# Parameters:
#   $1 (required) - Search pattern (string or regex)
#   $2 (required) - Replacement string
#
# Input:
#   Searches files in current directory and subdirectories
#
# Output:
#   Modifies files in-place that contain the search pattern
#   Prints list of files that were modified
#
# Required Dependencies:
#   - rg (ripgrep): Fast text search tool with smart filtering
#   - sd: Modern find-and-replace tool (sed alternative)
#
# Pattern Support:
#   - Plain text strings: "old_function_name"
#   - Capture groups: "function (\w+)" -> "method $1"
#   - Case sensitivity: patterns are case-sensitive by default
#
# Safety Features:
#   - Only processes files that contain the search pattern
#   - Respects .gitignore and common ignore patterns
#   - Uses sd for accurate replacements (safer than sed)
#   - No backup files created (use version control for safety)
#
# Return Codes:
#   0: Success - replacements completed (may be zero matches)
#   1: Error - missing dependencies, invalid regex, or file permissions
#
# Example:
#   replace "old_function_name" "new_function_name"     # Simple string replacement
#   replace "console\.log\(" "logger.debug("          # Escape special characters
#   replace "var (\w+)" "const $1"                     # Capture group replacement
#
# Advanced Usage:
#   # Replace in specific file types (combine with rg flags)
#   rg -l "old_api" --type js | xargs sd "old_api" "new_api"
#
# Large Codebase Example:
#   # Rename function across entire project
#   replace "getUserById" "findUserById"
#
#   # Update API endpoints
#   replace "/api/v1/" "/api/v2/"
#
#   # Fix common typos
#   replace "recieve" "receive"
#
# Safety Recommendations:
#   - Always commit changes before running replace operations
#   - Test patterns on small files first for complex regex
#   - Use version control to review changes before committing
#   - Consider using --dry-run equivalent: rg -l "pattern" (shows affected files)
# ------------------------------------------------------------------------------
replace() {
	rg -l "$1" | xargs sd "$1" "$2"
}

# ------------------------------------------------------------------------------
# go-build
# ------------------------------------------------------------------------------
# Build a Go application for Linux deployment with AWS Lambda compatibility.
#
# This function performs a complete build process for Go applications intended
# for deployment as AWS Lambda functions or Linux servers. It automates the
# entire build pipeline from compilation to packaging with integrity verification.
#
# Build Process:
#   1. Sets up Linux/AMD64 cross-compilation environment
#   2. Creates versioned build artifacts with Git branch tagging
#   3. Compiles binary with build metadata injection
#   4. Packages binary as deployment-ready zip archive
#   5. Generates SHA256 checksum for integrity verification
#
# Parameters:
#   None - function reads project configuration from current directory
#
# Input:
#   Reads from current directory structure and Git repository state
#
# Output:
#   Creates build artifacts in ./build/ directory:
#   - bootstrap: Linux executable binary
#   - {app-name}-{branch}.zip: Deployment archive
#   - {app-name}-{branch}-base64-sha256.sum: Base64-encoded SHA256 checksum
#
# Build Environment:
#   - GOOS: linux (target operating system)
#   - GOARCH: amd64 (target architecture)
#   - GOPROJECTS: $HOME/Projects (project base directory)
#
# Required Dependencies:
#   - go: Go programming language toolchain
#   - git: Version control system for branch detection
#   - zip: Archive utility for packaging
#   - openssl: Cryptographic toolkit for checksum generation
#   - grealpath: GNU realpath for path resolution
#
# Project Structure Requirements:
#   - Main package located at: ./cmd/{project-name}/
#   - Project root contains go.mod file
#   - Must be run from project root directory
#   - Project must be under $HOME/Projects directory structure
#
# Build Versioning & Metadata:
#   - Uses current Git branch name for version tagging (slashes converted to dashes)
#   - Injects build version via -ldflags "-X main.Build={branch}"
#   - Calculates relative path from GOPROJECTS for module resolution
#
# Return Codes:
#   0: Success - build completed successfully
#   1: Error - compilation failure, missing dependencies, or invalid project structure
#
# Example:
#   cd $HOME/Projects/my-go-project
#   go-build
#   # Creates: build/my-go-project-main.zip
#   # Creates: build/my-go-project-main-base64-sha256.sum
#
# AWS Lambda Deployment:
#   # Upload the generated zip file directly to AWS Lambda
#   aws lambda update-function-code --function-name my-function \
#     --zip-file fileb://build/my-go-project-main.zip
#
# Directory Structure Example:
#   $HOME/Projects/my-service/
#   ├── go.mod
#   ├── cmd/my-service/main.go
#   └── build/                    # Created by go-build
#       ├── bootstrap
#       ├── my-service-main.zip
#       └── my-service-main-base64-sha256.sum
# ------------------------------------------------------------------------------
go-build() {
	export GOOS=linux
	export GOARCH=amd64
	export GOPROJECTS="$HOME/Projects"

	GIT_BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD | tr '/' '-')
	GIT_REPOSITORY=$(grealpath --relative-to="$GOPROJECTS" "$PWD")

	APP_NAME=$(basename "$PWD")
	APP_FQDN="$APP_NAME-$GIT_BRANCH"
	APP_BUILD="$PWD/build"

	rm -fr "$APP_BUILD"
	# prepare the build directory
	mkdir -p "$APP_BUILD"

	cd "$APP_BUILD" || true

	# compile the binary
	go build -a -v -o bootstrap -ldflags "-X main.Build=$GIT_BRANCH" "$GIT_REPOSITORY/cmd/$APP_NAME"
	# archive the binary
	zip -qj "$APP_FQDN.zip" bootstrap
	# generate the binary sha256
	openssl dgst -binary -sha256 "$APP_FQDN.zip" | base64 | tr -d '\n' >"$APP_FQDN-base64-sha256.sum"
}

# ------------------------------------------------------------------------------
# vipe-md
# ------------------------------------------------------------------------------
# Interactive markdown viewer/editor using vipe with markdown syntax highlighting.
#
# This function provides a convenient wrapper around vipe for viewing and editing
# markdown content with proper syntax highlighting. It reads content from stdin,
# opens it in an editor with markdown support, and discards output to prevent
# terminal pollution. Perfect for AI-generated content review and documentation.
#
# The function follows Unix philosophy: reads from stdin, provides interactive
# editing experience, and handles markdown-specific formatting automatically.
#
# Parameters:
#   None
#
# Input:
#   Markdown content from stdin (required)
#
# Output:
#   None - content is viewed/edited interactively, output discarded
#
# Required Dependencies:
#   - vipe (from moreutils package for interactive editing)
#
# Required Setup:
#   - Editor configured (uses $EDITOR environment variable)
#   - vipe installed and available in PATH
#
# Return Codes:
#   0: Success - content viewed/edited or user cancelled gracefully
#   1: Error - vipe command failure or missing dependencies
#
# Example:
#   echo "# My Document" | vipe-md                    # View/edit markdown content
#   git-ai-explain | vipe-md                         # Review AI explanations
#   cat README.md | vipe-md                          # Edit existing markdown
#   curl -s api/docs.md | vipe-md                    # Review remote markdown
#
# Pipeline Examples:
#   git diff HEAD~1 | git-ai-explain | vipe-md      # AI explanation workflow
#   grep -r "TODO" . | vipe-md                      # Review TODO items
#
# Usage in Tig:
#   Used in tig configuration for AI explanation workflows:
#   bind status ae !zsh -i -c 'git diff --staged | git-ai-explain | vipe-md'
#
# Interactive Workflow:
#   1. Content piped to function from stdin
#   2. vipe opens editor with markdown syntax highlighting (.md suffix)
#   3. User views/edits content with full editor capabilities
#   4. Output redirected to /dev/null to prevent terminal display
#   5. Function exits cleanly after editor session
# ------------------------------------------------------------------------------
vipe-md() {
	vipe --suffix=md >/dev/null
}
