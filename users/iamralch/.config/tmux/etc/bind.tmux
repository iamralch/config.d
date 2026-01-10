# vim:ft=tmux

# C-b is not acceptable -- Vim uses it
set -g prefix C-space
# mouse mode
set -g mouse on
# use vim keybindings in copy mode
setw -g mode-keys vi

# reload configuration
bind r source-file ~/.config/tmux/tmux.conf

# edit configuration
bind e new-window "sh -c 'nvim ~/.config/tmux/tmux.conf'"

# tab navigation
bind Tab next-window
bind BTab previous-window

# github fzf repo search
bind -T fzf-menu g run-shell "gh fzf --tmux search repos > /dev/null || true"
# hsdk environment selection
bind -T fzf-menu e run-shell "~/.config/zsh/snippets/hsdk.sh > /dev/null || true"
