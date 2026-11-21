-- Window placement on the hyper key (ctrl+alt+cmd+shift), the Rectangle shortcuts you used:
--   hyper+Left / Right   left / right half of the screen
--   hyper+Up / Down      move the window to the next / previous display
--   hyper+Space          maximize
local M = {}

local hyper = { "ctrl", "alt", "cmd", "shift" }

hs.window.animationDuration = 0

-- Wraps an action on the focused window, doing nothing when there is none.
local function onFocused(action)
  return function()
    local win = hs.window.focusedWindow()
    if win then
      action(win)
    end
  end
end

local function place(unit)
  return onFocused(function(win) win:moveToUnit(unit) end)
end

local function sendToScreen(pick)
  return onFocused(function(win)
    win:moveToScreen(pick(win:screen()), false, true)
  end)
end

function M.start()
  hs.hotkey.bind(hyper, "Left", place({ x = 0, y = 0, w = 0.5, h = 1 }))
  hs.hotkey.bind(hyper, "Right", place({ x = 0.5, y = 0, w = 0.5, h = 1 }))
  hs.hotkey.bind(hyper, "Space", onFocused(function(win) win:maximize() end))
  hs.hotkey.bind(hyper, "Up", sendToScreen(function(s) return s:next() end))
  hs.hotkey.bind(hyper, "Down", sendToScreen(function(s) return s:previous() end))
end

return M
