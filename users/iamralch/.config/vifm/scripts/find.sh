#!/usr/bin/env bash
set -euo pipefail

# fzf picker
#
# All arguments are passed directly to fzf.
# Example:
#   fzf.sh --header 'Select a file'
#   fzf.sh --footer 'Press Ctrl-C to exit'
#
_fzf() {
  fzf --ansi --color footer:red --footer-border sharp "$@"
}

_fzf "$@"
