#!/bin/bash

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# Rclone Mount Configuration
# ------------------------------------------------------------------------------
RCLONE_STATE_DIR="$HOME/.local/state/rclone"
RCLONE_CACHE_DIR="$HOME/.cache/rclone"
RCLONE_MOUNT_DIR="$RCLONE_STATE_DIR/mnt"

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

	local mount_path="$RCLONE_MOUNT_DIR/$remote"
	# Prepare mount directory
	mkdir -p "$mount_path"

	local cache_path="$RCLONE_CACHE_DIR/$remote"
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

	local mount_path="$RCLONE_MOUNT_DIR/$remote"
	# Prepare mount directory
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
