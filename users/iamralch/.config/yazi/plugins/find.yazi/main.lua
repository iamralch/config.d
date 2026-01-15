--- @since 26.01.15
--- find.yazi - Interactive file and directory finder for Yazi
--- Based on find.sh script, uses fd and fzf for searching

-- Get shell and current working directory
local shell = os.getenv("SHELL"):match(".*/(.*)")

local get_cwd = ya.sync(function()
  return cx.active.current.cwd
end)

-- Error notification handler
local fail = function(s, ...)
  ya.notify({
    title = "find.yazi",
    content = string.format(s, ...),
    timeout = 5,
    level = "error",
  })
end

-- Get custom options from state
local get_custom_opts = ya.sync(function(state)
  local opts = state.custom_opts or {}
  return {
    fd = opts.fd or "",
    fzf = opts.fzf or "",
  }
end)

-- Check if required dependencies are installed
local check_dependencies = function()
  local fd_check, err = Command("fd"):arg("--version"):output()
  if not fd_check then
    return false, "fd", err
  end

  local fzf_check, err = Command("fzf"):arg("--version"):output()
  if not fzf_check then
    return false, "fzf", err
  end

  return true, nil, nil
end

-- Parse job arguments into mode and additional fd arguments
local parse_args = function(job_args)
  if #job_args == 0 then
    return nil, "Mode argument required (file or dir)"
  end

  local mode = job_args[1]
  if mode ~= "file" and mode ~= "dir" then
    return nil, string.format("Invalid mode '%s'. Use 'file' or 'dir'", mode)
  end

  local fd_args = {}
  for i = 2, #job_args do
    table.insert(fd_args, job_args[i])
  end

  return { mode = mode, fd_args = fd_args }, nil
end

-- Build fd command based on mode and arguments
local build_fd_command = function(mode, base_dir, additional_args, custom_opts)
  local fd_type = mode == "file" and "f" or "d"

  local fd_parts = {
    "fd",
    "-t",
    fd_type,
    "--base-directory",
    string.format("'%s'", tostring(base_dir)),
  }

  -- Add custom fd options from setup
  if custom_opts.fd ~= "" then
    table.insert(fd_parts, custom_opts.fd)
  end

  -- Add arguments passed from keymap/command
  if #additional_args > 0 then
    for _, arg in ipairs(additional_args) do
      table.insert(fd_parts, arg)
    end
  end

  return table.concat(fd_parts, " ")
end

-- Build fzf command with custom styling
local build_fzf_command = function(mode, base_dir, custom_opts)
  local icon = mode == "file" and "󰱼" or "󰥨"
  local label = mode == "file" and "Files" or "Directories"
  local footer = string.format(" %s %s · %s", icon, label, tostring(base_dir))

  local fzf_parts = {
    "fzf",
    "--ansi",
    "--color",
    "footer:red",
    "--footer-border",
    "sharp",
    "--footer",
    string.format("'%s'", footer),
  }

  -- Add custom fzf options from setup
  if custom_opts.fzf ~= "" then
    table.insert(fzf_parts, custom_opts.fzf)
  end

  return table.concat(fzf_parts, " ")
end

-- Build complete command pipeline
local build_command = function(mode, base_dir, fd_args, custom_opts)
  local fd_cmd = build_fd_command(mode, base_dir, fd_args, custom_opts)
  local fzf_cmd = build_fzf_command(mode, base_dir, custom_opts)

  return fd_cmd .. " | " .. fzf_cmd
end

-- Setup function for custom configuration
local function setup(state, opts)
  opts = opts or {}

  state.custom_opts = {
    fd = opts.fd or "",
    fzf = opts.fzf or "",
  }
end

-- Main entry point
local function entry(_, job)
  -- Hide Yazi UI to allow fzf interaction
  local _permit = ui.hide()

  -- Check dependencies
  local deps_ok, missing_tool, err = check_dependencies()
  if not deps_ok then
    return fail("`%s` was not found", missing_tool)
  end

  -- Parse arguments
  local parsed, parse_err = parse_args(job.args)
  if not parsed then
    return fail(parse_err)
  end

  local mode = parsed.mode
  local fd_args = parsed.fd_args

  -- Get current working directory
  local cwd = get_cwd()

  -- Get custom options
  local custom_opts = get_custom_opts()

  -- Build command pipeline
  local command = build_command(mode, cwd, fd_args, custom_opts)

  -- Execute command via shell
  local child, err = Command(shell)
      :arg({ "-c", command })
      :cwd(tostring(cwd))
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :stderr(Command.INHERIT)
      :spawn()

  if not child then
    return fail("Failed to spawn shell, error: %s", err)
  end

  -- Wait for output
  local output, err = child:wait_with_output()
  if not output then
    return fail("Cannot read command output, error: %s", err)
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
    return fail("Command exited with error code %s", output.status.code)
  end

  -- Parse output
  local target = output.stdout:gsub("\n$", "")
  if target ~= "" then
    -- Construct URL (handle relative paths from fd)
    local url = Url(target)
    if not url.is_absolute then
      url = cwd:join(url)
    end

    -- Navigate to selected file/directory
    ya.emit("reveal", { url })
  end
end

return { entry = entry, setup = setup }
