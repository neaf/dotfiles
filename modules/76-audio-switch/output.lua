-- Menubar item for the audio path. Each output device plays either directly
-- or through CamillaDSP (BlackHole 2ch -> CamillaDSP -> device, with that
-- device's config from camilladsp/configs). The choice is remembered per
-- device, and applied again when macOS switches to the device by itself.
local M = {}

local bar = hs.menubar.new()
local audioWatcher = nil
local statusTimer = nil
local refresh  -- forward declaration; used before its definition

local icon = hs.image.imageFromName("NSTouchBarAudioOutputVolumeHighTemplate")
if bar and icon then
  bar:setIcon(icon)
end

local GREEN = { red = 0.13, green = 0.5, blue = 0.2, alpha = 1 }
local RED = { red = 0.9, green = 0.25, blue = 0.2, alpha = 1 }
local TEXT_GREY = { red = 0.3, green = 0.3, blue = 0.3, alpha = 1 }

local BLACKHOLE = "BlackHole 2ch"
local SPEAKERS = "MacBook Air Speakers"
local CAMILLA_URL = "ws://127.0.0.1:1235"

-- ~/.hammerspoon/output.lua is a symlink into the dotfiles repo; the configs
-- sit next to the real file.
local CONFIG_DIR = hs.fs.pathToAbsolute(hs.configdir .. "/output.lua"):match("^(.*)/[^/]+$")
  .. "/configs/"

-- Menu choices, in display order. Absent devices are skipped. Devices with a
-- config can be routed through CamillaDSP; viaDefault applies until the
-- choice is first toggled.
local TARGETS = {
  { name = SPEAKERS, config = "speakers.yml" },
  { name = "External Headphones" },
  { name = "Tomasz\xe2\x80\x99s AirPods Pro", config = "airpods.yml" },
  { name = "Komplete Audio 6", config = "ka6.yml", viaDefault = true },
}

local function displayName(name)
  if #name > 24 then
    return name:sub(1, 23) .. "…"
  end
  return name
end

-- High-shelf cut for the menu, in dB. 0 is off. The shelf midpoint sits
-- above vocal presence (2-5 kHz) and over hats and cymbals (6-12 kHz).
local ROLLOFF_CHOICES = { 0, -1, -2, -3, -4, -6 }
local ROLLOFF_FREQ = 7000
local ROLLOFF_Q = 0.5
local ROLLOFF_KEY = "output.highShelfDb"

local function rolloffDb()
  return hs.settings.get(ROLLOFF_KEY) or 0
end

--- Per-device routing choice ---

local function viaKey(target)
  return "output.viaCamilla." .. target.name
end

local function usesCamilla(target)
  if not target.config then
    return false
  end
  local saved = hs.settings.get(viaKey(target))
  if saved == nil then
    return target.viaDefault == true
  end
  return saved
end

--- CamillaDSP websocket client ---

local camillaSocket = nil
local camillaPending = {}  -- commandKey -> callback
local camillaConfig = nil  -- active config filename
local camillaState = nil   -- engine state, e.g. "Running"
local camillaPoll

local function camillaConnected()
  return camillaSocket ~= nil and camillaSocket:status() == "open"
end

local function camillaHealthy()
  return camillaConnected() and camillaState == "Running"
end

-- Replies are always {[commandKey] = {...}}, so callbacks match by that key.
-- A command is a string ("GetState") or a one-key table ({SetConfigFilePath = path}).
local function camillaSend(command, onReply)
  if not camillaConnected() then
    return false
  end
  local key = type(command) == "table" and next(command) or command
  -- Text frame (isData=false): CamillaDSP ignores binary frames.
  local frame = type(command) == "table" and hs.json.encode(command) or ('"' .. command .. '"')
  camillaSocket:send(frame, false)
  camillaPending[key] = onReply or function() end
  return true
end

local function findDevice(name)
  for _, dev in ipairs(hs.audiodevice.allOutputDevices()) do
    if dev:name() == name then
      return dev
    end
  end
  return nil
end

local function targetByConfig(config)
  for _, t in ipairs(TARGETS) do
    if t.config and t.config == config then
      return t
    end
  end
  return nil
end

-- Adds the high-frequency roll-off to the loaded config: a high-shelf cut
-- on output channels 0 and 1, the stereo pair after any mixer. Safe to call
-- repeatedly; an existing roll-off step is updated, not duplicated.
local function camillaApplyRolloff(onDone)
  local db = rolloffDb()
  if db == 0 then
    onDone(true)
    return
  end
  local sent = camillaSend("GetConfigJson", function(reply)
    local ok, config = pcall(hs.json.decode, reply.value or "")
    if reply.result ~= "Ok" or not ok or type(config) ~= "table" then
      onDone(false)
      return
    end
    config.filters = config.filters or {}
    config.filters.hf_rolloff = {
      type = "Biquad",
      parameters = { type = "Highshelf", freq = ROLLOFF_FREQ, gain = db, q = ROLLOFF_Q },
    }
    local present = false
    for _, step in ipairs(config.pipeline or {}) do
      if step.type == "Filter" and step.names and hs.fnutils.contains(step.names, "hf_rolloff") then
        present = true
      end
    end
    if not present then
      config.pipeline = config.pipeline or {}
      table.insert(config.pipeline, { type = "Filter", channels = { 0, 1 }, names = { "hf_rolloff" } })
    end
    local set = camillaSend({ SetConfigJson = hs.json.encode(config) }, function(r)
      onDone(r.result == "Ok")
    end)
    if not set then
      onDone(false)
    end
  end)
  if not sent then
    onDone(false)
  end
end

-- Reloads the config file, then applies the roll-off on top.
local function camillaReload(onDone)
  local sent = camillaSend("Reload", function(reply)
    if reply.result ~= "Ok" then
      onDone(false)
      return
    end
    camillaApplyRolloff(onDone)
  end)
  if not sent then
    onDone(false)
  end
end

-- With -w, CamillaDSP goes Inactive when its device is missing, and stays
-- there. Reload once the device is back.
local function camillaRecover()
  local target = camillaConfig and targetByConfig(camillaConfig)
  if camillaConnected() and camillaState == "Inactive" and target and findDevice(target.name) then
    camillaReload(function() camillaPoll() end)
  end
end

camillaPoll = function()
  camillaSend("GetConfigFilePath", function(reply)
    camillaConfig = reply.result == "Ok" and type(reply.value) == "string" and reply.value:match("([^/]+)$") or nil
    refresh()
  end)
  camillaSend("GetState", function(reply)
    camillaState = reply.result == "Ok" and reply.value or nil
    camillaRecover()
    refresh()
  end)
end

-- Loads a config file and calls onDone(ok) once CamillaDSP has reloaded.
local function camillaLoad(config, onDone)
  local sent = camillaSend({ SetConfigFilePath = CONFIG_DIR .. config }, function(reply)
    if reply.result ~= "Ok" then
      onDone(false)
      return
    end
    camillaReload(function(ok)
      onDone(ok)
      camillaPoll()
    end)
  end)
  if not sent then
    onDone(false)
  end
end

local function camillaConnect()
  camillaSocket = hs.websocket.new(CAMILLA_URL, function(event, message)
    if event == "received" then
      local ok, decoded = pcall(hs.json.decode, message)
      local key = ok and type(decoded) == "table" and next(decoded)
      local cb = key and camillaPending[key]
      if cb then
        camillaPending[key] = nil
        cb(decoded[key])
      end
    elseif event == "open" then
      camillaPoll()
      camillaApplyRolloff(function() end)
    elseif event == "closed" or event == "fail" then
      camillaSocket = nil
      camillaConfig = nil
      camillaState = nil
      refresh()
      hs.timer.doAfter(3, camillaConnect)
    end
  end)
end

--- Output device control ---

-- The target currently playing: the default device itself, or the device
-- behind CamillaDSP when the default is BlackHole.
local function currentTarget()
  local dev = hs.audiodevice.defaultOutputDevice()
  if not dev then
    return nil
  end
  if dev:name() == BLACKHOLE then
    return camillaConfig and targetByConfig(camillaConfig)
  end
  for _, t in ipairs(TARGETS) do
    if t.name == dev:name() then
      return t
    end
  end
  return nil
end

local function route(target)
  local dev = findDevice(target.name)
  if not dev then
    hs.alert.show("No output device named \"" .. target.name .. "\"")
    return
  end
  if not usesCamilla(target) then
    dev:setDefaultOutputDevice()
    refresh()
    return
  end
  -- Switch macOS to BlackHole only after CamillaDSP plays to the new device.
  camillaLoad(target.config, function(ok)
    if ok then
      local bh = findDevice(BLACKHOLE)
      if bh then
        bh:setDefaultOutputDevice()
      end
    else
      hs.alert.show("CamillaDSP could not load " .. target.config)
    end
    refresh()
  end)
end

local function toggleCamilla()
  local target = currentTarget()
  if not (target and target.config) then
    return
  end
  hs.settings.set(viaKey(target), not usesCamilla(target))
  route(target)
end

local function cycle()
  local present = {}
  for _, t in ipairs(TARGETS) do
    if findDevice(t.name) then
      table.insert(present, t)
    end
  end
  if #present == 0 then
    return
  end
  local current = currentTarget()
  local currentIndex = 1
  for i, t in ipairs(present) do
    if t == current then
      currentIndex = i
      break
    end
  end
  route(present[(currentIndex % #present) + 1])
end

local function setRolloff(db)
  hs.settings.set(ROLLOFF_KEY, db)
  camillaReload(function(ok)
    if not ok then
      hs.alert.show("CamillaDSP could not apply the roll-off")
    end
    camillaPoll()
  end)
end

--- Menu ---

local function dot(ok)
  return hs.styledtext.new("\xe2\x97\x8f", { color = ok and GREEN or RED })
end

local function label(text)
  return hs.styledtext.new(text, { color = TEXT_GREY })
end

-- Passed to bar:setMenu() as a function so AppKit builds it when the menu
-- opens. Replacing items from a timer while the menu is open would make a
-- pending click do nothing.
local function buildMenuItems()
  local current = currentTarget()
  local items = {}

  for _, t in ipairs(TARGETS) do
    if findDevice(t.name) then
      table.insert(items, {
        title = t.name .. (usesCamilla(t) and " (via CamillaDSP)" or ""),
        checked = t == current,
        fn = function() route(t) end,
      })
    end
  end

  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Route through CamillaDSP",
    checked = current ~= nil and usesCamilla(current),
    disabled = not (current and current.config),
    fn = toggleCamilla,
  })

  local rolloff = { }
  for _, db in ipairs(ROLLOFF_CHOICES) do
    table.insert(rolloff, {
      title = db == 0 and "Off" or string.format("%d dB", db),
      checked = rolloffDb() == db,
      fn = function() setRolloff(db) end,
    })
  end
  table.insert(items, {
    title = "High frequency roll-off" .. (rolloffDb() ~= 0 and string.format(" (%d dB)", rolloffDb()) or ""),
    menu = rolloff,
    disabled = not camillaConnected(),
  })
  table.insert(items, { title = "-" })

  local currentDevice = hs.audiodevice.defaultOutputDevice()
  local volume = currentDevice and currentDevice:volume()
  if volume then
    local muted = currentDevice:muted()
    table.insert(items, { title = label(string.format("Volume: %d%%%s", math.floor(volume + 0.5), muted and " (muted)" or "")) })
  end
  table.insert(items, {
    title = label("CamillaDSP: ") .. dot(camillaHealthy()) .. label(" " .. (camillaState or "offline")
      .. (camillaConfig and (", " .. camillaConfig) or "")),
  })

  table.insert(items, { title = "-" })
  table.insert(items, { title = "Refresh", fn = camillaPoll })
  return items
end

-- Updates only the title bar; the dropdown is built on open.
refresh = function()
  if not bar then
    return
  end
  local currentDevice = hs.audiodevice.defaultOutputDevice()
  local viaBlackHole = currentDevice ~= nil and currentDevice:name() == BLACKHOLE
  local target = currentTarget()
  local title = target and displayName(target.name) or (currentDevice and displayName(currentDevice:name())) or "?"
  if viaBlackHole then
    title = title .. " (DSP)"
    if not camillaHealthy() then
      title = "\xe2\x9a\xa0 " .. title
    end
  end
  bar:setTitle(" " .. title)
end

-- macOS switches to AirPods or headphones by itself when they connect. Send
-- that device through CamillaDSP if it is set to be.
local function onAudioEvent(event)
  if event == "dOut" then
    local dev = hs.audiodevice.defaultOutputDevice()
    for _, t in ipairs(TARGETS) do
      if dev and t.name == dev:name() and usesCamilla(t) then
        route(t)
        break
      end
    end
  elseif event == "dev#" then
    camillaRecover()
  end
  refresh()
end

local hyper = { "ctrl", "alt", "cmd", "shift" }

-- Global shortcuts:
--   hyper+P          cycle to the next output device
--   hyper+I          internal speakers
--   hyper+O          toggle CamillaDSP routing for the current device
function M.start()
  camillaConnect()

  if bar then
    bar:setMenu(buildMenuItems)
  end
  refresh()

  hs.hotkey.bind(hyper, "P", cycle)
  hs.hotkey.bind(hyper, "I", function() route(TARGETS[1]) end)
  hs.hotkey.bind(hyper, "O", toggleCamilla)

  audioWatcher = hs.audiodevice.watcher
  audioWatcher.setCallback(onAudioEvent)
  audioWatcher.start()

  statusTimer = hs.timer.doEvery(10, camillaPoll)
end

return M
