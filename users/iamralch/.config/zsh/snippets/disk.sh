#!/bin/zsh

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# Rclone Mount Configuration
# ------------------------------------------------------------------------------
RCLONE_STATE_DIR="$HOME/.local/state/rclone"
RCLONE_CACHE_DIR="$HOME/.cache/rclone"
RCLONE_MOUNT_DIR="$RCLONE_STATE_DIR/mnt"
RCLONE_PROC_DIR="$RCLONE_STATE_DIR/proc"

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
	local remote="$1"
	# Validate input
	if [[ -z "$remote" ]]; then
		gum log --level error "Remote required"
		gum log --level warn "Usage: rclone-mount <REMOTE>"
		return 1
	fi

	# Prepare mount
	local mount_dir="$RCLONE_MOUNT_DIR/$remote"
	# Create mount directory
	mkdir -p "$mount_dir"

	# Prepare cache
	local cache_dir="$RCLONE_CACHE_DIR/$remote"
	# Create cache directory
	mkdir -p "$cache_dir"

	# Prepare PID file
	local pid_file="$RCLONE_PROC_DIR/$remote.pid"
	# Create pid directory
	mkdir -p "$RCLONE_PROC_DIR"

	# Mount the remote
	gum spin --title="Mounting $remote..." -- rclone mount "$remote" "$mount_dir" \
		--daemon --umask 002 \
		--cache-dir "$cache_dir" \
		--vfs-cache-mode writes \
		--vfs-cache-max-age 24h \
		--vfs-cache-max-size 5G \
		--dir-cache-time 1h \
		--poll-interval 1m \
		--buffer-size 32M \
		--allow-other &
	echo $! >"$pid_file"

	gum log --level info "Successfully mounted $remote at $mount_dir"
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
		gum log --level warn "Usage: rclone-unmount <REMOTE>"
		return 1
	fi

	# Prepare the PID file
	local pid_file="$RCLONE_PROC_DIR/$remote.pid"

	if [[ -f "$pid_file" ]]; then
		local pid
		pid=$(cat "$pid_file")
		# Kill the rclone mount process
		if gum spin --title="Unmounting $remote..." -- kill -SIGTERM "$pid"; then
			rm "$pid_file"
			# Report the success
			gum log --level info "Successfully unmounted $remote"
		else
			gum log --level error "Failed to unmount $remote"
			return 1
		fi
	else
		gum log --level error "PID file not found for $remote"
		return 1
	fi
}
