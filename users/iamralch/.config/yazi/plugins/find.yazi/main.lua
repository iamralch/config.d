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

local get_fzf_config = function(mode)
  if mode == "file" then
    return {
      commands = os.getenv("FZF_CTRL_T_COMMAND") or "fd -t f",
      options = os.getenv("FZF_CTRL_T_OPTS") or "",
      args = "--walker=dir,file,follow --scheme=path",
    }
  end

  if mode == "dir" then
    return {
      commands = os.getenv("FZF_ALT_C_COMMAND") or "fd -t d",
      options = os.getenv("FZF_ALT_C_OPTS") or "",
      args = "--walker=dir,follow --scheme=path",
    }
  end

  return nil
end

-- Get the fzf environment variables
local get_fzf_env = function(config)
  local args = config.args
  local options = config.options
  local commands = config.commands -- Fixed: was config.command

  local options_default = os.getenv("FZF_DEFAULT_OPTS") or ""
  -- Append mode-specific options to default options
  if options ~= "" then
    options = options_default .. " " .. options
  else
    options = options_default
  end

  return {
    FZF_DEFAULT_OPTS = options .. " " .. args,
    FZF_DEFAULT_COMMAND = commands,
  }
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

  local config = get_fzf_config(args.mode)
  local environment = get_fzf_env(config)

  -- Execute fzf via shell (needed to run FZF_DEFAULT_COMMAND)
  local child, err = Command("fzf")
      :env("FZF_DEFAULT_COMMAND", environment.FZF_DEFAULT_COMMAND)
      :env("FZF_DEFAULT_OPTS", environment.FZF_DEFAULT_OPTS)
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
