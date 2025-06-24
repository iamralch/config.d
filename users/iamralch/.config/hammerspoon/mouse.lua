local M = {}

-- Mouse set position
function M.focus(window)
  window = window or hs.window.focusedWindow()
  local current_pos = hs.geometry(hs.mouse.absolutePosition())
  local frame = window:frame()

  if not current_pos:inside(frame) then
    local window_screen = window:screen()
    local current_screen = hs.mouse.getCurrentScreen()

    if current_screen and window_screen and current_screen ~= window_screen then
      -- Avoid getting the mouse stuck on a screen corner by moving through the center of each screen
      hs.mouse.absolutePosition(current_screen:frame().center)
      hs.mouse.absolutePosition(window_screen:frame().center)
    end

    hs.mouse.absolutePosition(frame.center)
  end
end

return M
