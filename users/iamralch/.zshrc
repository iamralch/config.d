#!/bin/bash
#
# Configure the language
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export TMP_CONFIG="$TMPDIR/config"

# shellcheck disable=SC2155
export PYTHON_BIN="$(readlink -f /run/current-system/sw/bin/python3)"
export PYTHONPATH="${PYTHON_BIN}/lib/python3.13/site-packages"

# Configure the editor
export EDITOR="nvim"
# Set the configuration directories
export XDG_CONFIG_HOME="$HOME/.config"
# Set the directory we want to store zinit and plugins
export ZINIT_HOME="$XDG_DATA_HOME/zinit/zinit.git"
# Disable any telemetry
export VECTORCODE_LOG_LEVEL="ERROR"

# shellcheck disable=SC2155
export GOPATH="$HOME/.local/share/go"
export PSQLRC="$HOME/.config/pspg/psqlrc"
export GOPRIVATE="github.com/clichepress/*,github.com/hellohippo/*"

if ssh-add -l >/dev/null 2>&1; then
  # shellcheck disable=SC2155
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
fi

if [ -f "$TMP_CONFIG" ]; then
	# shellcheck disable=SC1090
	source "$TMP_CONFIG"
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
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.orbstack/bin"

# Set up MacOS tools
if [ "$(uname)" = "Darwin" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv --zsh)"
fi

# limit how much of history to download
zinit ice depth=1

# Add community plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode
zinit light Aloxaf/fzf-tab
# Add personal plugins
zinit load zsh-contrib/zsh-fzf

if [[ "$TERM" != "xterm-ghossty" ]]; then
  zinit load zsh-contrib/zsh-vivid
fi

# Add in snippets
zinit snippet OMZP::eza
zinit snippet OMZP::git
zinit snippet OMZP::git-commit
zinit snippet OMZP::golang

# local snippets
zinit snippet "$HOME/.config/zsh/snippets/aws.sh"
zinit snippet "$HOME/.config/zsh/snippets/func.sh"
zinit snippet "$HOME/.config/zsh/snippets/github.sh"
zinit snippet "$HOME/.config/zsh/snippets/hsdk.sh"
zinit snippet "$HOME/.config/zsh/snippets/sshd.sh"

# Load completions
autoload -Uz compinit && compinit

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
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(batman --export-env)"
eval "$(atuin init zsh)"

function zvm_after_init() {
  zvm_bindkey viins '^R' atuin-search
  zvm_bindkey vicmd '^R' atuin-search
}

# Options
setopt PROMPT_SUBST
