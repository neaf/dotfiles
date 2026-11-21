require("hs.ipc")

hs.hotkey.bind({ "ctrl", "alt", "cmd", "shift" }, "R", hs.reload)

-- Each feature is a module file linked by its own dotfiles module. A missing file is skipped.
for _, name in ipairs({ "output", "display", "windows", "tempora" }) do
  local ok, feature = pcall(require, name)
  if ok then
    feature.start()
  elseif not tostring(feature):find("module '" .. name .. "' not found", 1, true) then
    hs.alert.show(name .. ": " .. tostring(feature))
  end
end

hs.alert.show("Hammerspoon config loaded")
