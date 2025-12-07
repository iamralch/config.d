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
# and sd for accurate find-and-replace operations. It searches for files
# containing the target pattern and performs replacements only in those files.
#
# Arguments:
#   $1 - Search pattern (string or regex)
#   $2 - Replacement string
#
# Example:
#   replace "old_function_name" "new_function_name"
#   replace "TODO.*FIXME" "DONE"
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
# for deployment as AWS Lambda functions or Linux servers. It:
#   1. Sets up Linux/AMD64 build environment
#   2. Creates versioned build artifacts
#   3. Packages binary as zip archive
#   4. Generates SHA256 checksum for integrity verification
#
# Build Environment:
#   - GOOS: linux (target operating system)
#   - GOARCH: amd64 (target architecture)
#   - Build artifacts stored in ./build/ directory
#
# Generated Files:
#   - bootstrap: Linux executable binary
#   - {app-name}-{branch}.zip: Deployment archive
#   - {app-name}-{branch}-base64-sha256.sum: Base64-encoded SHA256 checksum
#
# Project Structure Expectations:
#   - Main package located at: ./cmd/{project-name}/
#   - Project root contains go.mod file
#   - Must be run from project root directory
#
# Build Versioning:
#   - Uses current Git branch name for version tagging
#   - Injects build version via -ldflags "-X main.Build={branch}"
#
# Example:
#   cd my-go-project
#   go-build
#   # Creates: build/my-go-project-main.zip
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

vipe-md() {
	vipe --suffix=md >/dev/null
}
