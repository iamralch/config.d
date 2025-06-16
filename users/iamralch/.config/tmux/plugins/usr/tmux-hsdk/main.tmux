#!/bin/bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux bind C-e run-shell "$CURRENT_DIR/scripts/hsdk-fzf-env.sh"
