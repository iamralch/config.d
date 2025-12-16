#!/bin/bash
# Installation functions for gh-opencode

# Install GitHub PR template
#
# Copies the pull request template from .opencode/template/gh.pr.create.md
# to .github/pull_request_template.md in the current working directory.
# Creates the .github directory if it doesn't exist. Always overwrites
# existing template without prompting.
#
# Usage: _gh_install
_gh_install() {
    # shellcheck disable=SC2154
    local source_template="$source_dir/.opencode/template/gh.pr.create.md"
    local target_path=".github/pull_request_template.md"

    # Check source exists
    if [[ ! -f "$source_template" ]]; then
        gum log --level=error "Template not found: $source_template"
        return 1
    fi

    # Create .github directory if needed
    mkdir -p ".github"

    # Copy template (always overwrite)
    cp "$source_template" "$target_path"
    # Success message
    gum log --level=info "Installed GitHub templates"
}

# Install OpenCode configuration (commands, context, templates)
#
# Copies command/, context/, and template/ directories from the source
# .opencode directory to the target project's .opencode directory.
# Creates directories as needed. Always overwrites existing files.
# Excludes bin/ and prompt/ directories.
#
# Usage: _oc_install
_oc_install() {
    local target_dir=".opencode"
    local dirs=("command" "context" "template")
    # Create target .opencode directory
    mkdir -p "$target_dir"

    # Copy each directory
    for dir in "${dirs[@]}"; do
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
    gum log --level=info "Installed OpenCode workflow"
}
