#!/usr/bin/env bash
#
# fuse.sh - Create FUSE mount configuration files for vifm
#
# This script generates temporary mount configuration files (.s3 or .ssh)
# that are used by vifm's FUSE plugin to mount remote filesystems.
#
# Usage:
#   fuse.sh [--print-path] s3://bucket-name[/path]
#   fuse.sh [--print-path] ssh://user@host[/path]
#
# Options:
#   --print-path    Output the created file path instead of mount content
#
# Examples:
#   fuse.sh "s3://my-bucket/data"              # Outputs: my-bucket:/data
#   fuse.sh --print-path "s3://my-bucket/data" # Outputs: /path/to/mount-XXXXX.s3
#   fuse.sh "ssh://user@server.com/home"       # Outputs: user@server.com:/home
#
# How it works:
#   1. Parses the URL to extract mount parameters
#   2. Creates a temporary file in ~/.cache/vifm/
#   3. Writes the formatted mount parameter as the first line
#   4. Outputs the content to stdout (or file path with --print-path)
#
# The created files work with vifm's FUSE_MOUNT2 plugin:
#   - .s3 files are mounted using: s3fs <content> <mount_point>
#   - .ssh files are mounted using: sshfs <content> <mount_point>
#

#######################################
# Strip protocol prefix and return the rest
# Arguments:
#   $1 - URL (e.g., s3://bucket:/path or ssh://user@host:/path)
# Outputs:
#   Content without protocol (e.g., bucket:/path or user@host:/path)
#######################################
_strip_protocol() {
  local url="$1"

  # Strip s3:// or ssh:// prefix and return the rest as-is
  if [[ "$url" == s3://* ]]; then
    echo "${url#s3://}"
  elif [[ "$url" == ssh://* ]]; then
    echo "${url#ssh://}"
  else
    echo "$url"
  fi
}

#######################################
# Main function - Parse URL and create mount file
# Arguments:
#   --print-path (optional) - Output file path instead of content
#   URL - Mount URL (s3://... or ssh://...)
# Outputs:
#   Mount parameter to stdout (or file path with --print-path)
# Side effects:
#   Creates temporary .s3 or .ssh file in ~/.cache/vifm/
#######################################
main() {
  local print_path=false
  local url=""

  # Parse arguments - check for --print-path flag
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --print-path)
      print_path=true
      shift
      ;;
    *)
      url="$1"
      shift
      ;;
    esac
  done

  # Validate that a URL was provided
  if [[ -z "$url" ]]; then
    echo "Usage: $0 [--print-path] <s3://bucket[/path] | ssh://user@host[/path]>" >&2
    exit 1
  fi

  # Use system temp directory for mount files
  # Strip trailing slash from TMPDIR if present
  local cache_dir="${TMPDIR:-/tmp}"
  cache_dir="${cache_dir%/}"

  # Determine protocol type and strip it
  local content
  local extension

  if [[ "$url" == s3://* ]]; then
    # S3 URL - create .s3 file for s3fs mounting
    content=$(_strip_protocol "$url")
    extension="s3"
  elif [[ "$url" == ssh://* ]]; then
    # SSH URL - create .ssh file for sshfs mounting
    content=$(_strip_protocol "$url")
    extension="ssh"
  else
    # Invalid URL - must start with s3:// or ssh://
    echo "Error: URL must start with s3:// or ssh://" >&2
    exit 1
  fi

  # Create temporary file with unique name
  # mktemp ensures no file conflicts with concurrent runs
  local temp_file
  temp_file=$(mktemp "${cache_dir}/mount-XXXXXX")

  # Add appropriate extension (.s3 or .ssh) to the file
  # vifm's FUSE plugin recognizes files by extension
  mv "$temp_file" "${temp_file}.${extension}"
  temp_file="${temp_file}.${extension}"

  # Write mount parameter as first line of file
  # vifm reads this line and passes it as %PARAM to the mount command
  echo "$content" >"$temp_file"

  # Output based on flag: file path or mount content
  if [[ "$print_path" == true ]]; then
    # Output the file path for use in vifm commands (no newline)
    printf '%s' "$temp_file"
  else
    # Echo content to stdout for verification/scripting
    echo "$content"
  fi
}

# Execute main function with all script arguments
main "$@"
