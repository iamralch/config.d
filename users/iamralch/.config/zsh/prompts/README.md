# Git AI Prompts

This directory contains markdown prompt files for the Git AI utilities in `../snippets/git.sh`.

## Files

- **git-ai-commit.md** - Prompt for generating conventional commit messages
- **git-ai-explain.md** - Prompt for explaining git changes in human-readable terms  
- **git-ai-review.md** - Prompt for comprehensive code reviews

## Usage

The shell functions automatically load these prompt files and substitute the `${CHANGES}` placeholder with the actual git diff content.

## Customization

You can customize the prompts by editing these markdown files. Changes take effect immediately when the functions are sourced again.

### Variables Available

- `${CHANGES}` - The git diff content passed from the shell functions

### Examples

To test a prompt modification:

```bash
# Edit the prompt file
vim git-ai-commit.md

# Source the updated functions
source ~/.config/zsh/snippets/git.sh

# Test with your changes
git diff --staged | git-ai-commit
```

## Format

The prompt files are in markdown format for better readability and editing experience. The shell functions process them as plain text with variable substitution.