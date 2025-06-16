#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
	DIR_PATH=$1
else
	DIR_PATH=$(find ~/go/src/github.com/hellohippo -mindepth 1 -maxdepth 1 -type d | fzf --tmux)
fi

if [[ -z $DIR_PATH ]]; then
	exit 0
fi

DIR_NAME=$(basename "$DIR_PATH" | tr . _)

if [[ -z $TMUX ]]; then
	tmux new-session -s "$DIR_NAME" -c "$DIR_PATH"
	exit 0
fi

if ! tmux has-session -t="$DIR_NAME" 2>/dev/null; then
	tmux new-session -ds "$DIR_NAME" -c "$DIR_PATH"
fi

tmux switch-client -t "$DIR_NAME"
