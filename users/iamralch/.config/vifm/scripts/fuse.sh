#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -eo pipefail

# _strip_protocol()
#
# Strip protocol prefix from URL and return the rest
#
# DESCRIPTION:
#   Removes the s3:// or ssh:// protocol prefix from a URL and returns
#   the remaining path. Used to extract mount parameters from URLs.
#
# PARAMETERS:
#   $1 - URL (e.g., s3://bucket/path or ssh://user@host/path)
#
# RETURNS:
#   0 - Success
#
# OUTPUT:
#   Content without protocol (e.g., bucket/path or user@host/path)
#
# EXAMPLE:
#   _strip_protocol "s3://my-bucket/data"  # Returns: my-bucket/data
#   _strip_protocol "ssh://user@host/home" # Returns: user@host/home
#
_strip_protocol() {
	local url="$1"

	if [[ "$url" == s3://* ]]; then
		echo "${url#s3://}"
	elif [[ "$url" == ssh://* ]]; then
		echo "${url#ssh://}"
	else
		echo "$url"
	fi
}

# _parse_url()
#
# Parse URL and extract mount parameters
#
# DESCRIPTION:
#   Validates the URL format, determines the protocol type (s3 or ssh),
#   strips the protocol prefix, and sets the extension accordingly.
#   Exits with error code 1 if URL format is invalid.
#
# PARAMETERS:
#   $1 - URL to parse (s3://... or ssh://...)
#
# RETURNS:
#   0 - Success (valid URL)
#   1 - Error (invalid URL format)
#
# OUTPUT:
#   Sets global variables:
#   - _mount_param: The mount parameter without protocol
#   - _file_extension: Either "s3" or "ssh"
#
# ERROR HANDLING:
#   Prints error message to stderr and exits if URL doesn't start
#   with s3:// or ssh://
#
# EXAMPLE:
#   _parse_url "s3://my-bucket/data"
#   echo "$_mount_param"     # Outputs: my-bucket/data
#   echo "$_file_extension"  # Outputs: s3
#
_parse_url() {
	local url="$1"

	if [[ -z "$url" ]]; then
		echo "Error: URL required" >&2
		return 1
	fi

	if [[ "$url" == s3:* ]]; then
		_mount_param=$(_strip_protocol "$url")
		_file_extension="s3"
	elif [[ "$url" == ssh:* ]]; then
		_mount_param=$(_strip_protocol "$url")
		_file_extension="ssh"
	else
		echo "Error: URL must start with s3:// or ssh://" >&2
		return 1
	fi
}

# _show_help()
#
# Display help information for fuse.sh
#
# DESCRIPTION:
#   Prints the main help documentation for the fuse.sh tool, including
#   usage instructions, available commands, and examples.
#
# PARAMETERS:
#   None
#
# RETURNS:
#   0 - Always returns success
#
# OUTPUT:
#   Writes help text to stdout
#
# EXAMPLE:
#   fuse.sh help
#   fuse.sh --help
#   fuse.sh -h
#
_show_help() {
	cat <<'EOF'
fuse.sh - Create FUSE mount configuration files for vifm

USAGE:
    fuse.sh <command> <url>

COMMANDS:
    create-config   Create configuration file and output file path
    help            Show this help message

PARAMETERS:
    url             Mount URL in format:
                    - s3://bucket-name[/path]
                    - ssh://user@host[/path]

DESCRIPTION:
    This script generates mount configuration files (.s3 or .ssh) that are
    used by vifm's FUSE plugin to mount remote filesystems.

    The created files work with vifm's FUSE_MOUNT2 plugin:
    - .s3 files are mounted using: s3fs <content> <mount_point>
    - .ssh files are mounted using: sshfs <content> <mount_point>

EXAMPLES:
    # Create config file and output file path
    fuse.sh create-config "s3://my-bucket/data"
    # Output: my-bucket-data.s3
    # Creates file: my-bucket-data.s3 (containing: my-bucket/data)

    # Create SSH config file
    fuse.sh create-config "ssh://user@server.com/home"
    # Output: user@server.com-home.ssh
    # Creates file: user@server.com-home.ssh (containing: user@server.com/home)
EOF
}

# _cmd_create_config()
#
# Create configuration file and output file path
#
# DESCRIPTION:
#   Parses the URL, creates a configuration file with the mount parameter,
#   and outputs the file path. The file is always overwritten if it exists.
#   The filename is derived from the mount parameter with the appropriate
#   extension (.s3 or .ssh).
#
# PARAMETERS:
#   $1 - URL to create config for
#
# RETURNS:
#   0 - Success
#   1 - Error (invalid URL or file creation failed)
#
# OUTPUT:
#   File path to stdout (without trailing newline)
#
# SIDE EFFECTS:
#   Creates/overwrites configuration file in current directory
#
# DEPENDENCIES:
#   - _parse_url function
#
# EXAMPLE:
#   _cmd_create_config "s3://my-bucket/data"
#   # Creates: my-bucket-data.s3
#   # Output: my-bucket-data.s3
#
_cmd_create_config() {
	local url="$1"

	_parse_url "$url" || return 1

	# Create filename from mount parameter (replace / with -)
	local config_file
	config_file="${_mount_param//\//-}.${_file_extension}"

	# Write mount parameter to file (always overwrite)
	echo "$_mount_param" >"$config_file"

	# Output file path without newline
	printf '%s' "$config_file"
}

# main()
#
# Main entry point for fuse.sh
#
# DESCRIPTION:
#   Processes command line arguments and dispatches to appropriate
#   sub-commands (create-config, help).
#
# PARAMETERS:
#   $1 - Command (create-config, help, --help, -h)
#   $2 - URL (required for create-config command)
#
# RETURNS:
#   0 - Success
#   1 - Error (unknown command, missing URL, or command failed)
#
# COMMANDS:
#   create-config   - Create configuration file and output file path
#   help            - Show help information
#   --help          - Show help information
#   -h              - Show help information
#   (empty)         - Show help information
#
# ERROR HANDLING:
#   - Unknown commands trigger an error message
#   - Missing URLs trigger an error message
#   - Command failures propagate error codes
#
# EXAMPLE:
#   main "create-config" "s3://my-bucket/data"
#   main "create-config" "ssh://user@host/home"
#   main "help"
#
main() {
	local command="$1"
	local url="$2"

	case "$command" in
	create-config)
		if [[ -z "$url" ]]; then
			echo "Error: URL required for create-config command" >&2
			echo "Run 'fuse.sh help' for usage information" >&2
			exit 1
		fi
		_cmd_create_config "$url"
		;;
	help | --help | -h | "")
		_show_help
		;;
	*)
		echo "Error: Unknown command '$command'" >&2
		echo "Available commands: create-config, help" >&2
		echo "Run 'fuse.sh help' for detailed usage information" >&2
		exit 1
		;;
	esac
}

main "$@"
