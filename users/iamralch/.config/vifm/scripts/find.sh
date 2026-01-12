#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

set -euo pipefail

_find_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# _show_help()
#
# Display help information
_show_help() {
	cat <<'EOF'
find.sh - Interactive file, directory, and S3 bucket finder

USAGE:
    find.sh file [base-dir] [fd-args...]
    find.sh dir [base-dir] [fd-args...]
    find.sh bucket

SUBCOMMANDS:
    file        Search for files interactively
    dir         Search for directories interactively
    bucket    Search for S3 buckets and create rclone config

EXAMPLES:
    find.sh file /home/user "*.txt"
    find.sh dir .
    find.sh bucket
EOF
}

# _cmd_file()
#
# Search for files interactively
_cmd_file() {
	local base_dir="${1:-$PWD}"
	shift || true

	fd -t f --base-directory "$base_dir" "$@" |
		fzf --ansi --color footer:red --footer-border sharp --footer " 󰱼 Files · $base_dir"
}

# _cmd_dir()
#
# Search for directories interactively
_cmd_dir() {
	local base_dir="${1:-$PWD}"
	shift || true

	fd -t d --base-directory "$base_dir" "$@" |
		fzf --ansi --color footer:red --footer-border sharp --footer " 󰥨 Directories · $base_dir"
}

# _cmd_bucket()
#
# Search for S3 buckets and create rclone config
_cmd_bucket() {
	local bucket
	bucket="$(CLICOLOR=1 aws fzf s3 bucket list 2>/dev/tty)"

	if [[ -n "$bucket" ]]; then
		"$_find_script_dir/rclone.sh" config "s3:$bucket"
	fi
}

# main()
#
# Main entry point
main() {
	local command="${1:-}"
	# Process the command
	case "$command" in
	bucket)
		shift
		_cmd_bucket "$@"
		;;
	file)
		shift
		_cmd_file "$@"
		;;
	dir)
		shift
		_cmd_dir "$@"
		;;
	help | --help | -h)
		_show_help
		;;
	"")
		echo "Error: Subcommand required" >&2
		_show_help
		exit 1
		;;
	*)
		echo "Error: Unknown subcommand '$1'" >&2
		_show_help
		exit 1
		;;
	esac
}

main "$@"
