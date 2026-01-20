# vim:ft=tmux


# Terminal inside tmux
set -g default-terminal "tmux-256color"

# Capabilities (modern)
set -ga terminal-features ",tmux-256color:RGB,clipboard,extkeys,focus,hyperlinks,mouse,strikethrough,sync,title,usstyle"

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

# Enable OSC 52 clipboard
set -g set-clipboard on

# Enable locking with cmatrix
set -g lock-command "/run/current-system/sw/bin/cmatrix -s -b"
