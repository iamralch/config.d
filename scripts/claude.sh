#!/usr/bin/env bash

[ -z "$DEBUG" ] || set -x

# Merge mcpServers from settings.json into .claude.json

SETTINGS_FILE="$HOME/.claude/settings.json"
CLAUDE_FILE="$HOME/.claude.json"

if [ -f "$SETTINGS_FILE" ] && [ -f "$CLAUDE_FILE" ]; then
  jq --slurpfile settings "$SETTINGS_FILE" '.mcpServers = ($settings[0].mcpServers // {})' "$CLAUDE_FILE" >"$CLAUDE_FILE.tmp" && mv "$CLAUDE_FILE.tmp" "$CLAUDE_FILE"
fi
