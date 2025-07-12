local mouse = require("mouse")
local power = require("power")
local layout = require("window")

-- Layout
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "/", function()
  layout.snapback()
end)

-- Make Window Full Screen
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.max)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Center
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.center)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Center with Full Height
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.center_full_height)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Center with Full Width
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "W", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.center_full_width)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Left
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Left", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.left)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Right
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Right", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.right)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Top
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Up", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.top)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Upper Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Left", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.top_left)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Upper Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Up", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.top_right)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Lower Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Down", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.bottom_left)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Lower Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Right", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.bottom_right)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window Bottom
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Down", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  layout.arrange(window, layout.positions.bottom)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window to Previous Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Left", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  window:moveOneScreenWest(false, true, layout.animation.duration)
  -- update the mouse
  mouse.focus(window)
end)

-- Send Window to Next Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Right", function()
  local window = hs.window.focusedWindow()
  -- update the screen
  window:moveOneScreenEast(false, true, layout.animation.duration)
  -- update the mouse
  mouse.focus(window)
end)

-- Show Window Hints
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "space", function()
  hs.hints.windowHints(nil, mouse.focus, false)
end)

-- Keep Awake
hs.hotkey.bind({ "cmd", "alt", "ctrl", "shift" }, "C", function()
  power.caffeinate()
end)

-- Applications
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "f", function()
  -- start the app
  hs.application.launchOrFocus("Finder")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "m", function()
  hs.application.launchOrFocus("zoom.us")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "k", function()
  -- start the app
  hs.application.launchOrFocus("Slack")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "r", function()
  -- start the app
  hs.application.launchOrFocus("Discord")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "s", function()
  -- start the app
  hs.application.launchOrFocus("Spotify")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "b", function()
  -- start the app
  hs.application.launchOrFocus("Brave Browser")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "g", function()
  -- start the app
  hs.application.launchOrFocus("Ghostty")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "z", function()
  -- start the app
  hs.application.launchOrFocus("Zed")
  -- update the mouse position
  mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "t", function()
  -- start the app
  hs.application.launchOrFocus("TradingView")
  -- update the mouse position
  mouse.focus()
end)
