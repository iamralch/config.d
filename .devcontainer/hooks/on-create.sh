#!/bin/bash -e

# This command is the first of three (along with updateContentCommand and
# postCreateCommand) that finalizes container setup when a dev container is
# created. It and subsequent commands execute inside the container immediately
# after it has started for the first time.

[ -z "$DEBUG" ] || set -x

# Fix ownership of bind-mounted .claude directory so vscode user can write to it
sudo chown -R vscode:vscode ~/.claude

# Add alias to run claude with --dangerously-skip-permissions
echo 'alias claude="claude --dangerously-skip-permissions"' >>~/.bashrc
