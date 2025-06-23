local obj = {}
-- Index
obj.__index = obj

-- Options: position
obj.positions = {
  max = hs.layout.maximized,
  left = hs.layout.left50,
  right = hs.layout.right50,
  -- top positions
  top = { x = 0, y = 0, w = 1, h = 0.5 },
  top_left = { x = 0, y = 0, w = 0.5, h = 0.5 },
  top_right = { x = 0.5, y = 0, w = 0.5, h = 0.5 },
  -- bottom positions
  bottom = { x = 0, y = 0.5, w = 1, h = 0.5 },
  bottom_left = { x = 0, y = 0.5, w = 0.5, h = 0.5 },
  bottom_right = { x = 0.5, y = 0.5, w = 0.5, h = 0.5 },
  -- center positions
  center = { x = 0.25, y = 0.125, w = 0.5, h = 0.75 },
  center_full_height = { x = 0.25, y = 0, w = 0.5, h = 1 },
  center_full_width = { x = 0, y = 0.25, w = 1, h = 0.5 },
}

-- Options: margin
obj.margin = {
  x = 12,
  y = 12,
}

-- Options: animation
obj.animation = {
  duration = 0.0,
}

-- State
obj.windows = {}

function obj.set_mouse_position(window)
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

-- Mouse should follow the focus
function obj.mouse_follow_focus()
  local window = hs.window.focusedWindow()
  obj.set_mouse_position(window)
end

-- Apply margin adjustment after the move
function obj.set_window_frame(window, position)
  local screen = window:screen()
  local screenFrame = screen:frame()

  -- Calculate absolute frame from position
  local x = screenFrame.x + (screenFrame.w * position.x)
  local y = screenFrame.y + (screenFrame.h * position.y)
  local w = screenFrame.w * position.w
  local h = screenFrame.h * position.h

  local margin = {
    x = obj.margin.x,
    y = obj.margin.y,
    w = 2 * obj.margin.x,
    h = 2 * obj.margin.y,
  }

  if position == obj.positions.center then
    margin.x = 0
    margin.y = 0
    margin.w = 0
    margin.h = 0
  elseif position == obj.positions.center_full_width then
    margin.y = 0
    margin.h = 0
  elseif position == obj.positions.center_full_height then
    margin.x = 0
    margin.w = 0
  elseif position == obj.positions.left then
    margin.w = obj.margin.x + obj.margin.x / 2
  elseif position == obj.positions.right then
    margin.x = obj.margin.x - obj.margin.x / 2
    margin.w = obj.margin.x + obj.margin.x / 2
  elseif position == obj.positions.top then
    margin.h = obj.margin.y + obj.margin.y / 2
  elseif position == obj.positions.top_left then
    margin.w = obj.margin.x + obj.margin.x / 2
    margin.h = obj.margin.y + obj.margin.y / 2
  elseif position == obj.positions.top_right then
    margin.x = obj.margin.x - obj.margin.x / 2
    margin.w = obj.margin.x + obj.margin.x / 2
    margin.h = obj.margin.y + obj.margin.y / 2
  elseif position == obj.positions.bottom then
    margin.y = obj.margin.y / 2
    margin.h = obj.margin.y + obj.margin.y / 2
  elseif position == obj.positions.bottom_left then
    margin.w = obj.margin.x + obj.margin.x / 2
    margin.y = obj.margin.y / 2
    margin.h = obj.margin.y + obj.margin.y / 2
  elseif position == obj.positions.bottom_right then
    margin.x = obj.margin.x - obj.margin.x / 2
    margin.w = obj.margin.x + obj.margin.x / 2
    margin.y = obj.margin.y / 2
    margin.h = obj.margin.y + obj.margin.y / 2
  end

  -- Apply margins
  local frame = {
    x = x + margin.x,
    y = y + margin.y,
    w = w - margin.w,
    h = h - margin.h,
  }

  window:setFrame(frame, obj.animation.duration)
end

function obj.set_window_position(position)
  local window = hs.window.focusedWindow()
  local previous_state = obj.windows[window:id()]

  if not previous_state then
    obj.windows[window:id()] = window:frame()
  end

  -- update the margin
  obj.set_window_frame(window, position)
  -- move the mouse
  obj.set_mouse_position(window)
end

function obj.snapback()
  local window = hs.window.focusedWindow()
  local previous_state = obj.windows[window:id()]

  if previous_state then
    window:setFrame(previous_state, obj.animation.duration)
  end

  obj.windows[window:id()] = nil
end

-- Snap back Window
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "/", function()
  obj.snapback()
end)

-- Make Window Full Screen
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
  obj.set_window_position(obj.positions.max)
end)

-- Send Window Center
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
  obj.set_window_position(obj.positions.center)
end)

-- Send Window Center with Full Height
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
  obj.set_window_position(obj.positions.center_full_height)
end)

-- Send Window Center with Full Width
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "W", function()
  obj.set_window_position(obj.positions.center_full_width)
end)

-- Send Window Left
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Left", function()
  obj.set_window_position(obj.positions.left)
end)

-- Send Window Right
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Right", function()
  obj.set_window_position(obj.positions.right)
end)

-- Send Window Top
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Up", function()
  obj.set_window_position(obj.positions.top)
end)

-- Send Window Upper Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Left", function()
  obj.set_window_position(obj.positions.top_left)
end)

-- Send Window Upper Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Up", function()
  obj.set_window_position(obj.positions.top_right)
end)

-- Send Window Lower Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Down", function()
  obj.set_window_position(obj.positions.bottom_left)
end)

-- Send Window Lower Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Right", function()
  obj.set_window_position(obj.positions.bottom_right)
end)

-- Send Window Bottom
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Down", function()
  obj.set_window_position(obj.positions.bottom)
end)

-- Send Window to Previous Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Left", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  window:moveOneScreenWest(false, true, obj.animation.duration)
  -- update the mouse
  obj.set_mouse_position(window)
end)

-- Send Window to Next Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Right", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  window:moveOneScreenEast(false, true, obj.animation.duration)
  -- update the mouse
  obj.set_mouse_position(window)
end)

return obj
