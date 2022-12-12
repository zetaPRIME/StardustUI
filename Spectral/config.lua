--
__spectral_db = { }
__spectral_db_local = { }

Spectral.config = { }

local events = { } do
  local handler = CreateFrame("Frame")
  handler:RegisterEvent("ADDON_LOADED")
  handler:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then for k in pairs(events) do handler:RegisterEvent(k) end end
    local ev = events[event];
    if ev then ev(...) end
  end)
end

function events.ADDON_LOADED(adn)
  if adn ~= "Spectral" then return end
  
  local tb = {
    "mount",
  }
  -- initialize tables and aliases
  for _,k in pairs(tb) do
    if not __spectral_db[k] then __spectral_db[k] = { } end
    if not __spectral_db_local[k] then __spectral_db_local[k] = { } end
    Spectral.config[k] = { global = __spectral_db[k], character = __spectral_db_local[k] }
  end
end

function Spectral.getConfig(category, key)
  local t = Spectral.config[category]
  if not t then return nil end
  local v = t.character[key]
  if not v then return t.global[key] end
  return v
end

function Spectral.getConfigRaw(category, key, perChar)
  local t = Spectral.config[category]
  if not t then return nil end
  if perChar then return t.character[key] end
  return t.global[key]
end

function Spectral.setConfig(category, key, value, perChar)
  local t = Spectral.config[category]
  if not t then return false end
  if value == "" then value = nil end
  if perChar then t.character[key] = value
  else t.global[key] = value end
  return true
end





do -- define panel
  local function pane(name)
    local p = CreateFrame("frame")
    p.name = name
    if name ~= "Spectral" then p.parent = "Spectral" end
    InterfaceOptions_AddCategory(p)
  end
  
  local main = pane "Spectral"
  
  
  local mount = pane "Mount"
end
