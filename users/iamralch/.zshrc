# vim: ft=zsh

# Allow parameter, command, and arithmetic expansion inside the prompt
# Enables things like $(git_branch), $VAR, $((1+2)) in PROMPT/RPROMPT
setopt PROMPT_SUBST

# Clear the right prompt (RPROMPT) after a command is accepted
# Keeps the terminal clean once you start typing/output appears
setopt TRANSIENT_RPROMPT

# Print a space if command output doesn't end with a newline
# Prevents the prompt from overwriting the last line of output
setopt PROMPT_SP

# Ensure the prompt starts on a new line
# Avoids prompt corruption after multiline or partial output
setopt PROMPT_CR

# Enable advanced globbing patterns (e.g. **, ^, (#i), (N))
# Extremely useful for powerful file matching and scripting
setopt EXTENDED_GLOB

# Allow comments (# ...) in interactive shell commands
# Useful for annotating one-off commands in the terminal
setopt INTERACTIVE_COMMENTS

# Configure the language
export LANG="en_US.UTF-8"

# Configure the tail
export LESS="-R -F -X -S -J"
# Configure the editor
export EDITOR="nvim"
# Set the configuration directories
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_HOME="$HOME/.config"
# Set the directory we want to store zinit and plugins
export ZINIT_HOME="$XDG_DATA_HOME/zinit/zinit.git"
# Hardcoded project configuration
export AWS_FZF_LOG_VIEWER="lnav"
export GOOGLE_CLOUD_PROJECT="hippo-dev-analytics"
export OPENCODE_GEMINI_PROJECT_ID="$GOOGLE_CLOUD_PROJECT"

# shellcheck disable=SC2155
export GOPATH="$HOME/.local/share/go"
export PSQLRC="$HOME/.config/pspg/psqlrc"
export GOPRIVATE="github.com/clichepress/*,github.com/hellohippo/*"

if ssh-add -l >/dev/null 2>&1; then
  # shellcheck disable=SC2155
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
fi

# Set the application configuration files
export PSPG_CONF="$XDG_CONFIG_HOME/pspg/config.toml"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config.ini"
export NPM_PATH="$HOME/.local/share/npm"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export MATPLOTLIBRC="$XDG_CONFIG_HOME/matplotlib"

# Set up MacOS tools
if [ "$(uname)" = "Darwin" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv --zsh)"
fi

# configure languages
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$NPM_PATH/bin"
export PATH="$PATH:$HOME/.bun/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.orbstack/bin"

# limit how much of history to download
zinit ice depth=1

# Add community plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode
zinit light Aloxaf/fzf-tab
# Add personal plugins
zinit light zsh-contrib/zsh-op
zinit light zsh-contrib/zsh-aws
zinit light zsh-contrib/zsh-fzf

if [[ "$TERM" != "tmux-256color" ]]; then
  zinit light zsh-contrib/zsh-vivid
fi

# Add in snippets
zinit snippet OMZP::eza
zinit snippet OMZP::git
zinit snippet OMZP::git-commit
zinit snippet OMZP::golang

script_dirs=(
  "$HOME/.config/zsh/snippets"
  "$HOME/.config/tmux/scripts"
  "$HOME/.config/rclone/scripts"
)

# Load local scripts
for scripts_dir in "${script_dirs[@]}"; do
  for script in "$scripts_dir"/*.sh; do
    # shellcheck disable=SC1090
    [ -r "$script" ] && source "$script"
  done
done

# Load hsdk secrets from macOS Keychain (populated by hsdk)
_export_hsdk_secrets

# Load completions
autoload -Uz compinit && compinit -C

zinit cdreplay -q

# Completion styling
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# shellcheck disable=2296
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:complete:cd:*' fzf-command fzf-tmux
# shellcheck disable=2016
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'

eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(batman --export-env)"

function zvm_after_init() {
  zvm_bindkey viins '^R' atuin-search
  zvm_bindkey vicmd '^R' atuin-search
}
