#!/bin/bash

# Installation functions for gh-opencode

# Install GitHub PR template
#
# Extracts the markdown template from .opencode/template/gh.pr.create.md
# (content between ```markdown and ``` markers) and writes it to
# .github/pull_request_template.md in the current working directory.
# Creates the .github directory if it doesn't exist. Always overwrites
# existing template without prompting.
#
# Usage: _github_install
_github_install() {
    local target_dir="${1:-.github}"
    # shellcheck disable=SC2154
    local source_template="$source_dir/.opencode/template/gh.pr.create.md"
    local target_path="$target_dir/pull_request_template.md"

    # Check source exists
    if [[ ! -f "$source_template" ]]; then
        gum log --level=error "Template not found: $source_template"
        return 1
    fi

    # Create .github directory if needed
    mkdir -p "$target_dir"

    # Extract content between ```markdown and ``` markers
    # shellcheck disable=SC2167
    # shellcheck disable=SC2165
    # shellcheck disable=SC2016
    sed -n '/^```markdown$/,/^```$/p' "$source_template" | sed '1d;$d' >"$target_path"

    # Verify extraction succeeded
    if [[ ! -s "$target_path" ]]; then
        gum log --level=error "Failed to extract markdown template from $source_template"
        return 1
    fi

    # Success message
    gum log --level=info "Installing GitHub templates to .github/"
}

# Install OpenCode configuration (commands, context, templates)
#
# Copies command/, context/, and template/ directories from the source
# .opencode directory to the target directory. Creates directories as
# needed. Always overwrites existing files. Excludes prompt/
# directory.
#
# Usage: _opencode_install [target_dir]
#   target_dir: defaults to ".opencode"
_opencode_install() {
    local target_dir="${1:-.opencode}"
    local dirs=("command" "context" "template" "bin")

    # Create target directory
    mkdir -p "$target_dir"

    # Exclude prompt/ directory
    for dir in "${dirs[@]}"; do
        # shellcheck disable=SC2154
        local source_path="$source_dir/.opencode/$dir"
        local target_path="$target_dir/$dir"

        if [[ -d "$source_path" ]]; then
            mkdir -p "$target_path"
            cp -r "$source_path"/* "$target_path"/
        else
            gum log --level=warn "Directory not found: $source_path"
        fi
    done

    # Success summary
    gum log --level=info "Installing OpenCode config to $target_dir/"
}

# Show install help
_gh_install_help() {
    cat <<'EOF'
Install gh-opencode configuration files

USAGE:
    gh opencode install [options]

DESCRIPTION:
    By default performs a local install (requires git repository):
      - GitHub PR template to .github/pull_request_template.md
      - OpenCode config to .opencode/

    With --global, performs a global install:
      - OpenCode config to ~/.config/opencode/ (or $XDG_CONFIG_HOME/opencode/)
      - Skips GitHub templates

OPTIONS:
    -g, --global    Install globally to ~/.config/opencode/
    -h, --help      Show this help message
EOF
}

# Main install entry point
#
# Installs gh-opencode configuration files. By default performs a local
# install (requires git repository). Use -g/--global for global install.
#
# Usage: _gh_install [-g|--global] [-h|--help]
_gh_install() {
    local global=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -g | --global)
            global=true
            shift
            ;;
        -h | --help)
            _gh_install_help
            return 0
            ;;
        *) shift ;;
        esac
    done

    if [[ "$global" == true ]]; then
        # Global install
        local target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
        gum log --level=info "Skipping GitHub templates (global install)"
        _opencode_install "$target_dir"
    else
        # Local install - requires git repo
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            gum log --level=error "Not in a git repository"
            return 1
        fi
        _github_install ".github"
        _opencode_install ".opencode"
    fi
}
