#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x
set -euo pipefail

# Symlink target directory to home directory
# Usage: symlink.sh <absolute_path> [dry-run-cmd]

dir="$1"
dry_run="${2:-}"
# Iterate over all files and directories in the user's home directory
for item in "$dir"/.* "$dir"/*; do
  name=$(basename "$item")

  # Skip special entries and .nix files
  [[ "$name" == "." || "$name" == ".." ]] && continue
  [[ "$name" == *.nix ]] && continue

  $dry_run ln -sfn "$item" "$HOME/$name"
done
