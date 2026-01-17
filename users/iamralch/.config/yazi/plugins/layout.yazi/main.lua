--- @sync entry

local function setup()
  Root.layout = function(self)
    self._chunks = ui.Layout()
        :direction(ui.Layout.VERTICAL)
        :constraints({
          ui.Constraint.Length(Tabs.height()),
          ui.Constraint.Fill(1),
          ui.Constraint.Length(1),
        })
        :split(self._area)
  end

  Root.build = function(self)
    self._children = {
      Tabs:new(self._chunks[1]),
      Tab:new(self._chunks[2], cx.active),
      Status:new(self._chunks[3], cx.active),
      Modal:new(self._area),
    }
  end
end

local function entry(state)
  local ratio = rt.mgr.ratio

  -- prepare the state
  state.parent = state.parent or ratio.parent
  state.current = state.current or ratio.current
  state.preview = state.preview or ratio.preview

  -- toggle preview
  if state.preview == 0 then
    state.preview = 1
  else
    state.preview = 0
  end

  if not state.layout then
    state.layout = Tab.layout

    Tab.layout = function(self)
      local all = state.parent + state.current + state.preview
      self._chunks = ui.Layout()
          :direction(ui.Layout.HORIZONTAL)
          :constraints({
            ui.Constraint.Ratio(state.parent, all),
            ui.Constraint.Ratio(state.current, all),
            ui.Constraint.Ratio(state.preview, all),
          })
          :split(self._area)
    end
  end

  -- Trigger the resize
  ya.emit("app:resize", {})
end

return { setup = setup, entry = entry }
