# vim:set ft=tmux:

# Separators
set -g @separator ""

# status style
set -g status-style "fg=#{@thm_fg},bg=#{@thm_bg}"

set -g status-left "#[fg=#{@thm_blue}] #{keyboard_layout} #[fg=#{@thm_fg}]#{@separator} #{?@is_upterm_session,#[fg=#{@thm_red}],#[fg=#{@thm_blue}]}#S #[fg=#{@thm_fg}]#{@separator}"
set -g status-left-length 100

set -g status-right "#{@separator}#[fg=#{@thm_yellow}]   #{cpu_percentage} #[fg=#{@thm_fg}]#{@separator} #[fg=#{@thm_peach}]#{battery_icon} #{battery_percentage} #{battery_remain} #[fg=#{@thm_fg}]#{@separator} 󰚭 #{uptime} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #{world_clock_status} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #[fg=#{@thm_maroon}]  %H:%M:%S "
set -g status-right-length 240

set -gF window-status-activity-style "fg=#{@thm_lavender},bg=#{@thm_bg}"
set -gF window-status-bell-style "fg=#{@thm_yellow},bg=#{@thm_bg}"

set -g window-status-format "#[fg=#{@thm_fg},bg=#{@thm_bg}] #I: #W #F "
set -g window-status-current-format "#[fg=#{@thm_mauve},bg=#{@thm_bg},bold]  #I: #W #F "
set -g window-status-separator ""

set -g pane-border-style "fg=#{@thm_overlay_0}"
set -g pane-active-border-style "fg=#{@thm_lavender}"

set -g message-style "fg=#{@thm_bg},bg=#{@thm_yellow}"
set -g mode-style "fg=#{@thm_bg},bg=#{@thm_yellow}"

set -g popup-border-style "fg=#{@thm_lavender},bg=#{@thm_bg}"
set -g popup-style "fg=#{@thm_fg},bg=#{@thm_bg}"

# Colors for focused panes
set-hook -g pane-focus-in 'select-pane -P "bg=#{@thm_bg}"'
# Colors for unfocused panes
set-hook -g pane-focus-out 'select-pane -P "bg=#{@thm_mantle}"'
