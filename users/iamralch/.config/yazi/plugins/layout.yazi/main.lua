local Plugin = {}

function Plugin:setup()
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

return Plugin
