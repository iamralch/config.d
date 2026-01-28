#!/bin/bash

[ -z "$DEBUG" ] || set -x

_rclone_source_dir="$HOME/.config/rclone/scripts"

# ------------------------------------------------------------------------------
# FZF AWS S3 Bucket Configuration
# ------------------------------------------------------------------------------

_fzf_s3_opts=(
	"--bind 'alt-enter:execute-silent($_rclone_source_dir/rclone.sh mount --print s3:{1})'"
	"--bind 'alt-m:execute-silent($_rclone_source_dir/rclone.sh mount s3:{1})'"
	"--bind 'alt-u:execute-silent($_rclone_source_dir/rclone.sh unmount s3:{1})'"
)

# Combine options into a single string
export FZF_AWS_S3_BUCKET_OPTS="${_fzf_s3_opts[*]}"

# ------------------------------------------------------------------------------
# Rclone Mount Configuration
# ------------------------------------------------------------------------------
RCLONE_STATE_DIR="$HOME/.local/state/rclone"
RCLONE_CACHE_DIR="$HOME/.cache/rclone"
RCLONE_MOUNT_DIR="$RCLONE_STATE_DIR/mnt"

# ------------------------------------------------------------------------------
# _rclone_path
# ------------------------------------------------------------------------------
# Determines the mount path for a remote based on its naming pattern.
# For remotes with schema:resource pattern (e.g., s3:bucket), organizes them
# under schema/ subdirectory. Otherwise uses the remote name directly.
#
# Parameters:
#   $1 - The remote name (e.g., "s3:bucket" or "myremote")
#   $2 - The base directory (e.g., RCLONE_MOUNT_DIR or RCLONE_CACHE_DIR)
#
# Returns:
#   The full path where the remote should be mounted or cached
# ------------------------------------------------------------------------------
_rclone_path() {
	local remote="$1"
	local base_dir="$2"

	if [[ "$remote" == *:* ]]; then
		# For remotes with schema:resource pattern, organize under schema/ subdirectory
		local schema="${remote%%:*}"
		local resource="${remote#*:}"
		echo "$base_dir/$schema/$resource"
	else
		# For other remotes, use the remote name directly
		echo "$base_dir/$remote"
	fi
}

# ------------------------------------------------------------------------------
# rclone-mount
# ------------------------------------------------------------------------------
# Mounts a selected rclone remote.
#
# This function takes a remote name, creates the necessary directories, and
# mounts the remote using rclone with optimized settings. A PID file is
# created to track the mount process.
#
# Parameters:
#   $1 - The name of the remote to mount.
#
# Returns:
#   0 on success, 1 on failure.
# ------------------------------------------------------------------------------
rclone-mount() {
	local remote=""
	local print_path=false

	# Parse arguments
	for arg in "$@"; do
		case "$arg" in
		--print)
			print_path=true
			;;
		*)
			if [[ -z "$remote" ]]; then
				remote="$arg"
			fi
			;;
		esac
	done

	# Validate input
	if [[ -z "$remote" ]]; then
		gum log --level error "Remote required"
		gum log --level warn "Usage: disk.sh mount [--print] <REMOTE>"
		return 1
	fi

	# Determine mount and cache paths
	local mount_path
	local cache_path
	mount_path="$(_rclone_path "$remote" "$RCLONE_MOUNT_DIR")"
	cache_path="$(_rclone_path "$remote" "$RCLONE_CACHE_DIR")"

	# Prepare mount directory
	mkdir -p "$mount_path"

	# Prepare cache directory
	mkdir -p "$cache_path"

	local pid
	pid="$(pgrep -f "rclone mount $remote $mount_path")"

	# Check if not mounted, then mount it
	if [[ -z "$pid" ]]; then
		gum spin --title="Mounting $remote..." --show-output --show-error -- \
			rclone mount "$remote" "$mount_path" --daemon \
			--cache-dir "$cache_path" \
			--vfs-cache-mode writes \
			--vfs-cache-max-age 24h \
			--vfs-cache-max-size 5G \
			--dir-cache-time 1h \
			--poll-interval 1m \
			--buffer-size 32M \
			--umask 002 \
			--allow-other
	else
		gum log --level debug "$remote is already mounted at $mount_path"
	fi

	# Print the mount path if requested
	if [[ "$print_path" == true ]]; then
		echo "$mount_path"
	fi
}

# ------------------------------------------------------------------------------
# rclone-unmount
# ------------------------------------------------------------------------------
# Unmounts a selected rclone mount.
#
# This function takes a remote name, finds the corresponding PID file, and
# terminates the rclone process.
#
# Parameters:
#   $1 - The name of the remote to unmount.
#
# Returns:
#   0 on success, 1 on failure.
# ------------------------------------------------------------------------------
rclone-unmount() {
	local remote="$1"
	# Validate input
	if [[ -z "$remote" ]]; then
		gum log --level error "Remote required"
		gum log --level warn "Usage: disk.sh unmount <REMOTE>"
		return 1
	fi

	# Determine mount path
	local mount_path
	mount_path="$(_rclone_path "$remote" "$RCLONE_MOUNT_DIR")"

	# Unmount the directory
	umount "$mount_path"
}

# main()
#
# Main entry point
_rclone_main() {
	local command="${1:-}"
	# Process command
	case "$command" in
	unmount)
		shift
		rclone-unmount "$@"
		;;
	mount)
		shift
		rclone-mount "$@"
		;;
	help | --help | -h | "")
		_show_help
		;;
	*)
		gum log --level error "Unknown command '$command'"
		gum log --level info "Available commands: mount, unmount, help"
		exit 1
		;;
	esac
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to hsdk-env.
# This enables tmux integration and scripted usage.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	_rclone_main "$@"
fi
