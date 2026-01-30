local M = {}

-- State
M.state = {}
-- Positions
M.positions = {
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

-- Margin
M.margin = {
	x = 18,
	y = 18,
}

-- Animation
M.animation = {
	duration = 0.0,
}

-- Snapback the window state
function M.snapback()
	local window = hs.window.focusedWindow()
	local previous_state = M.state[window:id()]

	if previous_state then
		window:setFrame(previous_state, M.animation.duration)
	end

	M.state[window:id()] = nil
end

-- Arrange the window
function M.arrange(window, position)
	local previous_state = M.state[window:id()]

	if not previous_state then
		M.state[window:id()] = window:frame()
	end

	local screen = window:screen()
	local screenFrame = screen:frame()

	-- Calculate absolute frame from position
	local x = screenFrame.x + (screenFrame.w * position.x)
	local y = screenFrame.y + (screenFrame.h * position.y)
	local w = screenFrame.w * position.w
	local h = screenFrame.h * position.h

	local margin = {
		x = M.margin.x,
		y = M.margin.y,
		w = 2 * M.margin.x,
		h = 2 * M.margin.y,
	}

	if position == M.positions.center then
		margin.x = 0
		margin.y = 0
		margin.w = 0
		margin.h = 0
	elseif position == M.positions.center_full_width then
		margin.y = 0
		margin.h = 0
	elseif position == M.positions.center_full_height then
		margin.x = 0
		margin.w = 0
	elseif position == M.positions.left then
		margin.w = M.margin.x + M.margin.x / 2
	elseif position == M.positions.right then
		margin.x = M.margin.x - M.margin.x / 2
		margin.w = M.margin.x + M.margin.x / 2
	elseif position == M.positions.top then
		margin.h = M.margin.y + M.margin.y / 2
	elseif position == M.positions.top_left then
		margin.w = M.margin.x + M.margin.x / 2
		margin.h = M.margin.y + M.margin.y / 2
	elseif position == M.positions.top_right then
		margin.x = M.margin.x - M.margin.x / 2
		margin.w = M.margin.x + M.margin.x / 2
		margin.h = M.margin.y + M.margin.y / 2
	elseif position == M.positions.bottom then
		margin.y = M.margin.y / 2
		margin.h = M.margin.y + M.margin.y / 2
	elseif position == M.positions.bottom_left then
		margin.w = M.margin.x + M.margin.x / 2
		margin.y = M.margin.y / 2
		margin.h = M.margin.y + M.margin.y / 2
	elseif position == M.positions.bottom_right then
		margin.x = M.margin.x - M.margin.x / 2
		margin.w = M.margin.x + M.margin.x / 2
		margin.y = M.margin.y / 2
		margin.h = M.margin.y + M.margin.y / 2
	end

	-- Apply margins
	local frame = {
		x = x + margin.x,
		y = y + margin.y,
		w = w - margin.w,
		h = h - margin.h,
	}

	window:setFrame(frame, M.animation.duration)
end

-- Main function: Launch/focus app with space switching
function M.launchOrFocus(appName)
	local app = hs.application.find(appName)
	if not app then
		return hs.application.launchOrFocus(appName)
	end

	if not app:activate(true) then
		return false
	end

	-- After activate, give it a moment to potentially switch Spaces
	-- 100ms
	hs.timer.usleep(100000)

	-- Get the window first to check if it's fullscreen
	local window = app:mainWindow() or app:focusedWindow()
	if not window then
		return false
	end

	if not window:focus() then
		return false
	end

	-- Raise the window
	if not window:raise() then
		return false
	end
end

return M
