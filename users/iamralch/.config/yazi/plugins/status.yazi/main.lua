local name = function(self)
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

local mtime = function()
  local file = cx.active.current.hovered
  if not file then
    return ""
  end

  if not file.cha.mtime then
    return ""
  end

  local time = os.date("%Y-%m-%d %H:%M", file.cha.mtime // 1)
  return ui.printable(time .. " ")
end

local owner = function()
  local file = cx.active.current.hovered
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

return {
  setup = function()
    Status.name = name
    Status:children_add(owner, 1300, Status.RIGHT)
    Status:children_add(mtime, 1400, Status.RIGHT)
  end,
}
