# vim:set ft=tmux:

# Separators
set -g @separator ""

# Status Style
set -g status-style "fg=#{@thm_fg},bg=#{@thm_bg}"
# Status Left Format and Styles
set -g status-left "#[fg=#{@thm_blue}] #{keyboard_layout} #[fg=#{@thm_fg}]#{@separator} #{?@is_upterm_session,#[fg=#{@thm_red}],#[fg=#{@thm_blue}]}#S #{?@aws_profile,#[fg=#{@thm_fg}]#{@separator} #[fg=#{@thm_yellow}]  #{aws_credential_ttl} ,}#[fg=#{@thm_fg}]#{@separator}"

set -g status-left-length 100
# Status Right Format and Styles
set -g status-right "#[fg=#{@thm_fg}]#{@separator}#[fg=#{@thm_peach}]   #{cpu_percentage} #[fg=#{@thm_fg}]#{@separator} #[fg=#{@thm_green}]#{battery_icon} #{battery_percentage} #{battery_remain} #[fg=#{@thm_fg}]#{@separator} #{pomodoro_status} #[fg=#{@thm_fg}]#{@separator} 󰚭 #{uptime} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #{world_clock_status} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #[fg=#{@thm_maroon}]  %H:%M:%S "
set -g status-right-length 240

# Window Styles
set -gF window-status-activity-style "fg=#{@thm_lavender},bg=#{@thm_bg},italics"
set -gF window-status-bell-style "fg=#{@thm_yellow},bg=#{@thm_bg}"
set -gF window-status-style "fg=#{@thm_fg},bg=#{@thm_bg}"
set -gF window-status-current-style "fg=#{@thm_mauve},bg=#{@thm_bg},bold"
# Window Formats
set -g window-status-format " #I: #W #F "
set -g window-status-current-format "#{?#{aws_profile},#[fg=#{@thm_yellow}],} #I: #W #F "
# Window Status Separator
set -gF window-status-separator "#{@separator}"

# Pane Styles
set -gF pane-border-style "fg=#{@thm_overlay_0}"
set -gF pane-active-border-style "fg=#{@thm_lavender}"
# Popup Styles
set -gF popup-border-style "fg=#{@thm_lavender},bg=#{@thm_bg}"
set -gF popup-style "fg=#{@thm_fg},bg=#{@thm_bg}"

# Misc Styles
set -gF message-style "fg=#{@thm_bg},bg=#{@thm_yellow}"
set -gF mode-style "fg=#{@thm_bg},bg=#{@thm_yellow}"

# Colors for focused panes
set-hook -g pane-focus-in 'select-pane -P "bg=#{@thm_bg}"'
# Colors for unfocused panes
set-hook -g pane-focus-out 'select-pane -P "bg=#{@thm_crust}"'
