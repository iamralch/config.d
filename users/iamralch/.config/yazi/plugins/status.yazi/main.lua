local set_state = ya.sync(function(state, data)
	for k, v in pairs(data) do
		state[k] = v
	end

	ui.render()
end)

local get_state = ya.sync(function(state)
	return state
end)

local emit_state = function(state)
	local cwd = cx.active.current.cwd
	if state.cwd ~= cwd then
		state.cwd = cwd
		-- refresh the state
		ya.emit("plugin", {
			state._id,
			ya.quote(tostring(cwd), true),
		})
	end
end

local load_state = function(cwd)
	local home = os.getenv("HOME") or ""
	local config_path = home .. "/.config/starship/yaziline.toml"
	-- Execute the prompt command
	local output = Command("starship")
			:stdin(Command.INHERIT)
			:env("STARSHIP_CONFIG", config_path)
			:env("STARSHIP_SHELL", "")
			:arg("prompt")
			:cwd(cwd)
			:output()
	-- sanitize output
	if output then
		set_state({ prompt = output.stdout:gsub("^%s+", ""):gsub("%s+$", "") })
	else
		set_state({ prompt = nil })
	end
end
local get_path = function(self)
	local home = os.getenv("HOME") or ""
	local file = self._current.hovered
	if not file then
		return ""
	end

	local prefix = " "
	local path = file.url
	-- make the path pretty
	if path:starts_with(home) then
		prefix = prefix .. "~/"
		path = path:strip_prefix(home)
	end

	return ui.Span(prefix .. ui.printable(tostring(path))):style(th.mgr.cwd)
end

local get_mtime = function(self)
	local file = self._current.hovered
	if not file then
		return ""
	end

	if not file.cha.mtime then
		return ""
	end

	local time = os.date("%Y-%m-%d %H:%M", file.cha.mtime // 1)
	return ui.printable(time .. " ")
end

local get_owner = function(self)
	local file = self._current.hovered
	if not file then
		return ""
	end

	if not file.cha.uid or not file.cha.gid then
		return ""
	end

	local user = ya.user_name(file.cha.uid) or file.cha.uid
	local group = ya.group_name(file.cha.gid) or file.cha.gid
	local owner = string.format("%s:%s", user, group)

	return ui.printable(" " .. owner .. " ")
end

local get_info = function()
	-- We need to get the state
	local state = get_state()
	local prompt = state["prompt"]
	-- Return the prompt
	return ui.Line.parse(prompt or "")
end

return {
	setup = function(state)
		-- left status
		Status.name = get_path
		-- right status
		Status:children_add(get_owner, 1300, Status.RIGHT)
		Status:children_add(get_mtime, 1400, Status.RIGHT)
		Status:children_add(get_info, 1500, Status.RIGHT)

		local handle = function()
			emit_state(state)
		end
		-- Emit state on cwd/tab change
		ps.sub("cd", handle)
		ps.sub("tab", handle)
		ps.sub("hover", handle)
	end,
	entry = function(_, job)
		local cwd = job.args[1]
		-- Load the state
		load_state(cwd)
	end,
}
