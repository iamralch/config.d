# vim:ft=tmux

# shell options
set -g default-shell "/bin/zsh"
# set terminal options
set -g default-terminal "tmux-256color"
# set the terminal-overrides
set-option -sa terminal-overrides ",tmux-256color:RGB"

# set the titles dynamically
set-option -g set-titles on
set-option -g focus-events on

# sound and indicators
set-option -g bell-action none
set-option -g visual-bell off
set-option -g visual-activity off
set-option -g visual-silence off

# status line
set -g status-justify left
set -g status-interval 1

# window mode
setw -g monitor-activity on
setw -g aggressive-resize on
setw -g automatic-rename on

# window navigation
set -g base-index 1
set -g renumber-windows on

# keyboard management
set -s escape-time 10
set -sg repeat-time 600

# kitty
set -gq allow-passthrough on
