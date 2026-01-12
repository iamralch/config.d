#!/usr/bin/env bash

set -euo pipefail

# Create an rclone configuration file
#
# USAGE:
#   rclone.sh config <type:name>
#
# DESCRIPTION:
#   Creates a file named <name>.rclone in $PWD/.rclone/ with content <type:name>
#   The prefix (<type>:) is stripped from the filename but preserved in the content
#   This file can be used with vifm's FUSE plugin to mount remote filesystems
#
# PARAMETERS:
#   <type:name>    Remote specification (e.g., s3:bucket, ssh:server)
#
# EXAMPLE:
#   rclone.sh config s3:my-bucket
#   # Creates: $PWD/.rclone/my-bucket.rclone (containing: s3:my-bucket)
#
#   rclone.sh config ssh:my-server
#   # Creates: $PWD/.rclone/my-server.rclone (containing: ssh:my-server)

# Configuration
RCLONE_DIR="$PWD/.rclone"

# _show_help()
#
# Display help information
_show_help() {
	cat <<'EOF'
rclone.sh - Create rclone mount configuration files

USAGE:
    rclone.sh config <type:name>

COMMANDS:
    config      Create configuration file

PARAMETERS:
    <type:name>    Remote specification with format <type>:<name>
                   Examples: s3:bucket, ssh:server, sftp:host

DESCRIPTION:
    Creates a file named <name>.rclone in $PWD/.rclone/
    The prefix is stripped from filename but kept in content

EXAMPLES:
    rclone.sh config s3:my-bucket
    # Creates: $PWD/.rclone/my-bucket.rclone
    # Content: s3:my-bucket

    rclone.sh config ssh:my-server
    # Creates: $PWD/.rclone/my-server.rclone
    # Content: ssh:my-server
EOF
}

# _cmd_config()
#
# Create rclone configuration file
_cmd_config() {
	local remote="$1"

	if [[ -z "$remote" ]]; then
		echo "Error: Remote specification required" >&2
		echo "Usage: rclone.sh config <type:name>" >&2
		return 1
	fi

	# Strip prefix to get name for filename
	local name
	name="${remote#*:}"

	if [[ -n "$name" ]]; then
		# Create rclone directory if it doesn't exist
		mkdir -p "$RCLONE_DIR"

		# Create filename
		local path="${RCLONE_DIR}/${name}.rclone"

		# Write full remote specification to file
		echo "$remote" >"$path"

		# Output the filename (for vifm to capture)
		printf '%s' "$path"
	fi

}

# main()
#
# Main entry point
main() {
	local command="${1:-}"

	case "$command" in
	config)
		shift
		_cmd_config "$@"
		;;
	help | --help | -h | "")
		_show_help
		;;
	*)
		echo "Error: Unknown command '$command'" >&2
		echo "Available commands: config, help" >&2
		exit 1
		;;
	esac
}

main "$@"
