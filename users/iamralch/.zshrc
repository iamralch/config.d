# Configure the language
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# Configure the editor
export EDITOR="nvim"
# Configure the man viewer
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# Set the configuration directories
export XDG_CONFIG_HOME="${HOME}/.config"
# Set the directory we want to store zinit and plugins
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# shellcheck disable=SC2155
export GOPATH="$HOME/.local/share/go"
export PSQLRC="$HOME/.config/pspg/psqlrc"
export GOPRIVATE="github.com/clichepress/*,github.com/hellohippo/*"

# seutp git-duet
export GIT_DUET_GLOBAL=true
export GIT_DUET_SET_GIT_USER_CONFIG=1
export GIT_DUET_AUTHORS_FILE="$XDG_CONFIG_HOME/git/ralch.duet.yaml"

# Set the application configuration files
export PSPG_CONF="$XDG_CONFIG_HOME/pspg/config.toml"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config.toml"

# configure languages
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.pyenv/bin"
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
zinit snippet "$HOME/.config/zsh/snippets/func.sh"
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
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# key bindings
bindkey -v

# we have to bind the history search to the same keys as the vi-mode
zle -N history-incremental-search-backward  _atuin_search_viins
