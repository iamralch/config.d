local M = {}

M.id = 8008

local style = hs.alert.defaultStyle
style.strokeColor = { white = 0, alpha = 0.75 }
style.textSize = 54
style.radius = 12

function M.caffeinate()
  local ok = hs.caffeinate.toggle("displayIdle")
  -- close any alerts
  hs.alert.closeSpecific(M.alert, 0)
  -- show alerts
  if ok then
    -- start the timer
    M.timer = hs.timer.doAfter(10, function()
      hs.caffeinate.declareUserActivity(M.id)
    end)

    local image = hs.image.imageFromName("NSTouchBarAlarmTemplate")
    -- create the menu item
    M.menu = hs.menubar.new()
    M.menu:setIcon(image)
    -- show an alert
    M.alert = hs.alert.show("☼", style)
  else
    -- stop the timer
    M.timer:stop()
    M.timer = nil
    -- delete the menu item
    M.menu:delete()
    M.menu = nil
    -- show an alert
    M.alert = hs.alert.show("☽", style)
  end
end

return M
