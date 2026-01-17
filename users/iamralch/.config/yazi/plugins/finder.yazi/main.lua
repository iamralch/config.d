-- Get the current working directory
local get_cwd = ya.sync(function()
  return cx.active.current.cwd
end)

local has_prefix = function(str, start)
  return string.sub(str, 1, #start) == start
end

-- Notify about errors
local notify_error = function(s, ...)
  ya.notify({
    title = "find.yazi",
    content = string.format(s, ...),
    timeout = 5,
    level = "error",
  })
end

-- Notify about info
local notify_info = function(s, ...)
  return ya.notify({
    title = "find.yazi",
    content = string.format(s, ...),
    timeout = 5,
  })
end

-- Check for dependencies
local check_deps = function()
  local ok, err = Command("fzf"):arg("--version"):output()
  if not ok then
    return false, "fzf", err
  end

  return true, nil, nil
end

-- Parse job arguments into mode
local parse_args = function(args)
  if #args == 0 then
    return nil, "Mode argument required (file or dir)"
  end

  local mode = args[1]
  -- Check for valid mode
  if mode ~= "file" and mode ~= "dir" then
    return nil, string.format("Invalid mode '%s'. Use 'file' or 'dir'", mode)
  end

  return { mode = mode }, nil
end

local get_fzf_env = function(mode)
  local config = {}

  if mode == "file" then
    config = {
      commands = os.getenv("FZF_CTRL_T_COMMAND") or "",
      options = os.getenv("FZF_CTRL_T_OPTS") or "",
      cwd = os.getenv("FZF_CWD") or "",
    }
  end

  if mode == "dir" then
    config = {
      commands = os.getenv("FZF_ALT_C_COMMAND") or "",
      options = os.getenv("FZF_ALT_C_OPTS") or "",
      cwd = os.getenv("FZF_CWD") or "",
    }
  end

  local cwd = tostring(get_cwd())
  local options = os.getenv("FZF_DEFAULT_OPTS") or ""

  -- Make sure it starts in the correct directory
  config.options = config.options:gsub(config.cwd, cwd)
  config.options = options .. " " .. config.options
  -- Make sure the command uses the correct base directory
  if has_prefix(config.commands, "fd") then
    config.commands = config.commands .. " --base-directory " .. cwd
  end

  return config
end

-- Main entry point
local function entry(_, job)
  local _permit = ui.hide()

  local ok, tool, _ = check_deps()
  -- Check dependencies
  if not ok then
    return notify_error("'%s' was not found", tool)
  end

  -- Parse arguments
  local args, err = parse_args(job.args)
  if not args then
    return notify_error(err)
  end

  local config = get_fzf_env(args.mode)
  -- Execute the finder
  local child, err = Command("fzf")
      :env("FZF_DEFAULT_COMMAND", config.commands)
      :env("FZF_DEFAULT_OPTS", config.options)
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :stderr(Command.INHERIT)
      :spawn()

  if not child then
    return notify_error("Failed to spawn fzf: %s", err)
  end

  -- Wait for output
  local output, err = child:wait_with_output()
  if not output then
    return notify_error("Cannot read command output: %s", err)
  elseif output.status.code == 130 then
    return
  elseif output.status.code == 1 then
    return notify_info("No " .. args.mode .. " selected")
  elseif output.status.code ~= 0 then
    return notify_error("Command exited: %s", output.status.code)
  end

  local target = output.stdout:gsub("\n$", "")
  -- Parse output
  if target ~= "" then
    local url = Url(target)
    if not url.is_absolute then
      url = fs.cwd():join(url)
    end
    ya.emit("reveal", { url })
  end
end

return { entry = entry }
