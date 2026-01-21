local mouse = require("mouse")
local power = require("power")
local space = require("space")

-- Layout
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "/", function()
	space.snapback()
end)

-- Make Window Full Screen
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.max)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Center
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.center)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Center with Full Height
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.center_full_height)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Center with Full Width
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "W", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.center_full_width)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Left
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Left", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.left)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Right
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Right", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.right)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Top
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Up", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.top)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Upper Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Left", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.top_left)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Upper Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Up", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.top_right)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Lower Left
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Down", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.bottom_left)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Lower Right
hs.hotkey.bind({ "shift", "alt", "ctrl" }, "Right", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.bottom_right)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window Bottom
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Down", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	space.arrange(window, space.positions.bottom)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window to Previous Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Left", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	window:moveOneScreenWest(false, true, space.animation.duration)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window to Previous Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Up", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	window:moveOneScreenNorth(false, true, space.animation.duration)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window to Next Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Right", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	window:moveOneScreenEast(false, true, space.animation.duration)
	-- update the mouse
	mouse.focus(window)
end)

-- Send Window to Next Monitor
hs.hotkey.bind({ "alt", "ctrl" }, "Down", function()
	local window = hs.window.focusedWindow()
	-- update the screen
	window:moveOneScreenSouth(false, true, space.animation.duration)
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
	space.launchOrFocus("Finder")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "m", function()
	-- Start the app
	space.launchOrFocus("zoom.us")
	-- Find focus all zoom windows
	local windows = hs.application("zoom.us"):allWindows()
	-- Focus all windows except "Zoom Workplace"
	for _, w in ipairs(windows) do
		if w:title() ~= "Zoom Workplace" then
			w:focus()
		end
	end
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "k", function()
	-- start the app
	space.launchOrFocus("Slack")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "r", function()
	-- start the app
	space.launchOrFocus("Discord")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "s", function()
	-- start the app
	space.launchOrFocus("Spotify")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "b", function()
	-- start the app
	space.launchOrFocus("Brave Browser")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "x", function()
	-- start the app
	space.launchOrFocus("Firefox Developer Edition")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "g", function()
	-- start the app
	space.launchOrFocus("Ghostty")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "z", function()
	-- start the app
	space.launchOrFocus("Zed")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "t", function()
	-- start the app
	space.launchOrFocus("TradingView")
	-- update the mouse position
	mouse.focus()
end)

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "o", function()
	-- start the app
	space.launchOrFocus("Obsidian")
	-- update the mouse position
	mouse.focus()
end)
