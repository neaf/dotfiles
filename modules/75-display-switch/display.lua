-- Menubar item and hotkey to switch the external display off and on without
-- unplugging. bin/extdisplay (built from bin/extdisplay.c with
-- `clang extdisplay.c -o extdisplay -framework CoreGraphics -framework ApplicationServices`)
-- calls CGSConfigureDisplayEnabled, which can also re-enable a disabled display.
-- Disabling detaches the display from macOS (windows move to the laptop screen).
local M = {}

local TOOL = os.getenv("HOME") .. "/.hammerspoon/bin/extdisplay"

local bar = hs.menubar.new()
local busy = false

-- Returns id, online for the first non-built-in display with a serial number.
local function findExternal()
  local out = hs.execute(TOOL .. " list")
  for line in (out or ""):gmatch("[^\n]+") do
    local id, builtin, serial, online = line:match("^(%d+) builtin=(%d) .- serial=(%d+) online=(%d)")
    if id and builtin == "0" and serial ~= "0" then
      return id, online == "1"
    end
  end
  return nil, false
end

-- Monitor bezel outline; when the display is on, a filled screen sits inside it
-- with a 1px gap (stroke half-width 0.75 + 1 gap = 1.75 inset).
-- Template images follow the menu bar's light or dark appearance.
local function monitorIcon(online)
  local black = { white = 0, alpha = 1 }
  local c = hs.canvas.new({ x = 0, y = 0, w = 20, h = 18 })
  c[1] = { type = "rectangle", action = "stroke", strokeColor = black, strokeWidth = 1.5,
    frame = { x = 2, y = 3, w = 16, h = 12 }, roundedRectRadii = { xRadius = 2, yRadius = 2 } }
  if online then
    c[2] = { type = "rectangle", action = "fill", fillColor = black,
      frame = { x = 3.75, y = 4.75, w = 12.5, h = 8.5 }, roundedRectRadii = { xRadius = 0.5, yRadius = 0.5 } }
  end
  local img = c:imageFromCanvas()
  c:delete()
  return img:template(true)
end

local function refresh()
  if bar then
    local _, online = findExternal()
    bar:setIcon(monitorIcon(online), true)
  end
end

local function toggle()
  if busy then
    return
  end
  local id, online = findExternal()
  if not id then
    hs.alert.show("No external display known")
    return
  end
  busy = true
  hs.task.new(TOOL, function(code)
    busy = false
    if code == 0 then
      hs.alert.show(online and "External display off" or "External display on")
    else
      hs.alert.show("extdisplay failed: " .. code)
    end
    refresh()
  end, { online and "off" or "on", id }):start()
end

-- Global shortcut: hyper+D toggles the external display.
function M.start()
  if bar then
    bar:setMenu(function()
      local _, online = findExternal()
      return {
        { title = online and "Turn external display off" or "Turn external display on", fn = toggle },
      }
    end)
  end
  refresh()

  hs.hotkey.bind({ "ctrl", "alt", "cmd", "shift" }, "D", toggle)
  M.watcher = hs.screen.watcher.new(refresh)
  M.watcher:start()
end

return M
