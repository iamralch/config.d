local M = {}

M.id = 8008

function M.caffeinate()
  local ok = hs.caffeinate.toggle("displayIdle")

  if ok then
    -- start the timer
    M.timer = hs.timer.doAfter(10, function()
      hs.caffeinate.declareUserActivity(M.id)
    end)

    local image = hs.image.imageFromName("NSQuickLookTemplate")
    -- create the menu item
    M.menu = hs.menubar.new()
    M.menu:setIcon(image)
    -- show an alert
    hs.alert.show("Keep Awake")
  else
    -- stop the timer
    M.timer:stop()
    M.timer = nil
    -- delete the menu item
    M.menu:delete()
    M.menu = nil
    -- show an alert
    hs.alert.show("Auto Sleep")
  end
end

return M
