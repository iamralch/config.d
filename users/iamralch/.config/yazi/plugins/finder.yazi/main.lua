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
  if mode ~= "file" and mode ~= "dir" and mode ~= "s3" then
    return nil, string.format("Invalid mode '%s'. Use 'file' or 'dir' or 's3'", mode)
  end

  return { mode = mode }, nil
end

local get_fzf_disk = function(config)
  local cwd = tostring(get_cwd())
  local options = os.getenv("FZF_DEFAULT_OPTS") or ""

  -- Make sure it starts in the correct directory
  config.environment.FZF_DEFAULT_OPTS = config.environment.FZF_DEFAULT_OPTS:gsub(config.environment.FZF_CMD, cwd)
  config.environment.FZF_DEFAULT_OPTS = options .. " " .. config.environment.FZF_DEFAULT_OPTS
  -- Make sure the command uses the correct base directory
  if has_prefix(config.environment.FZF_DEFAULT_COMMAND, "fd") then
    config.environment.FZF_DEFAULT_COMMAND = config.environment.FZF_DEFAULT_COMMAND .. " --base-directory " .. cwd
  end

  return config
end

local get_fzf_file = function()
  local config = {
    cmd = "fzf",
    arguments = {},
    environment = {
      FZF_DEFAULT_COMMAND = os.getenv("FZF_CTRL_T_COMMAND") or "",
      FZF_DEFAULT_OPTS = os.getenv("FZF_CTRL_T_OPTS") or "",
      FZF_CMD = os.getenv("FZF_CWD") or "",
    },
  }

  return get_fzf_disk(config)
end

local get_fzf_dir = function()
  local config = {
    cmd = "fzf",
    arguments = {},
    environment = {
      FZF_DEFAULT_COMMAND = os.getenv("FZF_ALT_C_COMMAND") or "",
      FZF_DEFAULT_OPTS = os.getenv("FZF_ALT_C_OPTS") or "",
      FZF_CMD = os.getenv("FZF_CWD") or "",
    },
  }

  return get_fzf_disk(config)
end

local get_fzf_s3 = function()
  local config = {
    cmd = "aws",
    arguments = {
      "fzf",
      "--bind=enter:become(~/.config/zsh/snippets/disk.sh mount --print s3:{1})",
      "--bind=alt-u:execute-silent(~/.config/zsh/snippets/disk.sh unmount s3:{1})",
      "s3",
      "bucket",
      "list",
    },
    environment = {},
  }

  return config
end

local get_fzf_env = function(mode)
  local config = {}

  if mode == "file" then
    config = get_fzf_file()
  end

  if mode == "dir" then
    config = get_fzf_dir()
  end

  if mode == "s3" then
    config = get_fzf_s3()
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
  local command = Command(config.cmd):stdin(Command.INHERIT):stdout(Command.PIPED):stderr(Command.INHERIT)

  -- Prepare the command arguments
  for _, v in ipairs(config.arguments) do
    command = command:arg(v)
  end

  -- Prepare the command environment variables
  for k, v in pairs(config.environment) do
    command = command:env(k, v)
  end

  -- Execute the command
  local child, err = command:spawn()
  if not child then
    return notify_error("Failed to spawn %s: %s", config.cmd, err)
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
