# vim:ft=tmux

# set terminal options
set -g default-terminal "tmux-256color"
# set the terminal-overrides
set -sa terminal-overrides ",tmux-256color:RGB"
set -ga terminal-features '*:RGB:hyperlinks:usstyle'

# set the titles dynamically
set -g set-titles on
set -g focus-events on
set -g allow-rename on

# sound and indicators
set -g bell-action none
set -g visual-bell off
set -g visual-activity off
set -g visual-silence off

# status line
set -g status-position top
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

# clipboard management
set -gq allow-passthrough on
