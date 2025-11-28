# vim:set ft=tmux:

# Separators
set -g @separator ""

# status style
set -g status-style "fg=#{@thm_fg},bg=#{@thm_bg}"

set -g status-left "#[fg=#{@thm_blue}] #{keyboard_layout} #{@separator} #S #{@separator}"
set -g status-left-length 100

set -g status-right "#{@separator}#[fg=#{@thm_yellow}]   #[fg=#{@thm_fg}]#{cpu_percentage} #{@separator} #{battery_icon} #{battery_percentage} #{battery_remain} #[fg=#{@thm_fg}]#{@separator} 󰚭 #{uptime} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #{world_clock_status} #[fg=#{@thm_fg},nobold,noitalics,nounderscore]#{@separator} #[fg=#{@thm_maroon}]  %H:%M:%S "
set -g status-right-length 240

set -gF window-status-activity-style "fg=#{@thm_lavender}"
set -gF window-status-bell-style "fg=#{@thm_yellow}"

set -g window-status-format "#[fg=#{@thm_fg},bg=#{@thm_bg}] #I #W #F "
set -g window-status-current-format "#[fg=#{@thm_mauve}] #I #W #F "
set -g window-status-separator ""
