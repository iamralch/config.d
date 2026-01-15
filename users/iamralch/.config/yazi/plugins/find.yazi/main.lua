--- @since 26.01.15
--- find.yazi - Interactive file and directory finder for Yazi
--- Uses FZF environment variables for consistency with shell scripts

-- Get shell name
local shell = os.getenv("SHELL"):match(".*/(.*)")

-- Get current working directory from Yazi
local get_cwd = ya.sync(function()
  return cx.active.current.cwd
end)

-- Error notification handler
local notify_error = function(s, ...)
  ya.notify({
    title = "find.yazi",
    content = string.format(s, ...),
    timeout = 5,
    level = "error",
  })
end

-- Get FZF configuration from environment variables
local get_fzf_config = function(mode)
  if mode == "file" then
    return {
      commands = os.getenv("FZF_CTRL_T_COMMAND") or "fd -t f",
      options = os.getenv("FZF_CTRL_T_OPTS") or "",
    }
  else -- mode == "dir"
    return {
      commands = os.getenv("FZF_ALT_C_COMMAND") or "fd -t d",
      options = os.getenv("FZF_ALT_C_OPTS") or "",
    }
  end
end

-- Substitute $PWD with actual directory path
local substitute_pwd = function(str, base_dir)
  if not str then
    return ""
  end
  -- Replace all occurrences of $PWD with base_dir
  return str:gsub("%$PWD", tostring(base_dir))
end

-- Check if fzf is installed
local check_dependencies = function()
  local fzf_check, err = Command("fzf"):arg("--version"):output()
  if not fzf_check then
    return false, "fzf", err
  end

  return true, nil, nil
end

-- Parse job arguments into mode
local parse_args = function(job_args)
  if #job_args == 0 then
    return nil, "Mode argument required (file or dir)"
  end

  local mode = job_args[1]
  if mode ~= "file" and mode ~= "dir" then
    return nil, string.format("Invalid mode '%s'. Use 'file' or 'dir'", mode)
  end

  return { mode = mode }, nil
end

-- Build complete command using environment variables (replicates bash find.sh)
local build_command = function(mode, base_dir)
  local fzf_config = get_fzf_config(mode)

  -- Substitute $PWD in both commands and options
  local options = substitute_pwd(fzf_config.options, base_dir)
  local commands = substitute_pwd(fzf_config.commands, base_dir)

  -- Get existing FZF_DEFAULT_OPTS
  local default_options = os.getenv("FZF_DEFAULT_OPTS") or ""
  -- append mode-specific options
  if options ~= "" then
    options = default_options .. " " .. options
  else
    options = default_options
  end

  -- Construct shell command that changes to base_dir and executes fzf
  -- Matches the bash script: cd "$base_dir" && FZF_DEFAULT_COMMAND="$cmd" FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $opts" fzf
  local shell_cmd = string.format(
    'cd \'%s\' && FZF_DEFAULT_COMMAND="%s" FZF_DEFAULT_OPTS="%s" fzf',
    tostring(base_dir),
    commands,
    options
  )

  return shell_cmd
end

-- Main entry point
local function entry(_, job)
  -- Hide Yazi UI to allow fzf interaction
  local _permit = ui.hide()

  local ok, missing_tool, err = check_dependencies()
  -- Check dependencies
  if not ok then
    return notify_error("`%s` was not found", missing_tool)
  end

  -- Parse arguments
  local parsed, parse_err = parse_args(job.args)
  if not parsed then
    return notify_error(parse_err)
  end

  local mode = parsed.mode
  -- Get current working directory
  local cwd = get_cwd()
  -- Build command using environment variables
  local command = build_command(mode, cwd)

  -- Execute command via shell
  local child, err = Command(shell)
      :arg({ "-c", command })
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :stderr(Command.INHERIT)
      :spawn()

  if not child then
    return notify_error("Failed to spawn shell, error: %s", err)
  end

  -- Wait for output
  local output, err = child:wait_with_output()
  if not output then
    return notify_error("Cannot read command output, error: %s", err)
  elseif output.status.code == 130 then
    -- User cancelled with <ctrl-c> or <esc>
    return
  elseif output.status.code == 1 then
    -- No match found
    return ya.notify({
      title = "find.yazi",
      content = "No " .. (mode == "file" and "file" or "directory") .. " selected",
      timeout = 5,
    })
  elseif output.status.code ~= 0 then
    -- Other error
    return notify_error("Command exited with error code %s", output.status.code)
  end

  local target = output.stdout:gsub("\n$", "")
  -- Parse output
  if target ~= "" then
    local url = Url(target)
    -- Construct URL (handle relative paths)
    if not url.is_absolute then
      url = cwd:join(url)
    end
    -- Navigate to selected file/directory
    ya.emit("reveal", { url })
  end
end

return { entry = entry }
