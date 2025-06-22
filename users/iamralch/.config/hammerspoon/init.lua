local layout = hs.loadSpoon("Layout")

-- Options: hints
hs.hints.style = "vimperator"
hs.hints.fontSize = 16

-- Options: hot keys
local hotkey = {
  modifiers = {
    meh = { "ctrl", "alt", "shift" },
  },
}

-- Show Window Hints
hs.hotkey.bind(hotkey.modifiers.meh, "return", function()
  hs.hints.windowHints(nil, layout.mouse_follow_focus, false)
end)

hs.hotkey.bind(hotkey.modifiers.meh, "f", function()
  hs.application.launchOrFocus("Finder")
  -- update the mouse position
  layout.mouse_follow_focus()
end)

hs.hotkey.bind(hotkey.modifiers.meh, "m", function()
  hs.application.launchOrFocus("zoom.us")
  -- update the mouse position
  layout.mouse_follow_focus()
end)

hs.hotkey.bind(hotkey.modifiers.meh, "k", function()
  hs.application.launchOrFocus("Slack")
  -- update the mouse position
  layout.mouse_follow_focus()
end)

hs.hotkey.bind(hotkey.modifiers.meh, "s", function()
  hs.application.launchOrFocus("Spotify")
  -- update the mouse position
  layout.mouse_follow_focus()
end)

hs.hotkey.bind(hotkey.modifiers.meh, "b", function()
  hs.application.launchOrFocus("Brave Browser")
  -- update the mouse position
  layout.mouse_follow_focus()
end)

hs.hotkey.bind(hotkey.modifiers.meh, "g", function()
  hs.application.launchOrFocus("Ghostty")
  -- update the mouse position
  layout.mouse_follow_focus()
end)
