# vim:ft=tmux

# C-b is not acceptable -- Vim uses it
set-option -g prefix C-space

# reload configuration
bind r source-file ~/.config/tmux/tmux.conf

# edit configuration
bind e new-window "sh -c 'nvim ~/.config/tmux/tmux.conf'"

# mouse mode
set -g mouse on
# use vim keybindings in copy mode
setw -g mode-keys vi

# create session
bind C-c new-session

# find session
bind C-f command-prompt -p find-session 'switch-client -t %%'

# session navigation
bind BTab switch-client -l

# window navigation
bind Tab last-window

# hsdk environment selection
bind -n M-h run-shell "~/.config/zsh/snippets/hsdk.sh || true"
