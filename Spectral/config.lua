--
__spectral_db = { }
__spectral_db_local = { }

Spectral.config = { }

local events = { } do
  local handler = CreateFrame("Frame")
  handler:RegisterEvent("ADDON_LOADED")
  handler:SetScript("OnEvent", function(self, event, p1, ...)
    if event == "ADDON_LOADED" and p1 == "Spectral" then for k in pairs(events) do handler:RegisterEvent(k) end end
    local ev = events[event];
    if ev then ev(p1, ...) end
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
  local cat
  local function pane(name)
    local p = CreateFrame("frame")
    p.name = name or "Spectral"
    if p.name ~= "Spectral" then p.parent = "Spectral" end
    if not p.parent then
      cat = Settings.RegisterCanvasLayoutCategory(p, p.name)
      Settings.RegisterAddOnCategory(cat)
    else
      Settings.RegisterCanvasLayoutSubcategory(cat, p, p.name)
    end
    
    p.category = string.lower(p.name)
    
    p._refresh = { }
    --function p:refresh() for _,f in pairs(p._refresh) do f() end end
    p:SetScript("OnShow", function(self) for _,f in pairs(p._refresh) do f() end end)
    
    function p:_updated()
      if self.updateEvent then
        local t = type(self.updateEvent)
        if t == "string" then
          Spectral.queueUpdate(self.updateEvent)
        elseif t == "function" then
          self.updateEvent()
        end
      end
    end
    
    -- bind a widget to a config value
    function p:bind(w, key, perChar)
      local t = w:GetObjectType();
      
      if t == "EditBox" then
        self._refresh[w] = function()
          w:SetText(Spectral.getConfigRaw(self.category, key, perChar) or "")
        end
        
        w:SetScript("OnEditFocusLost", function()
          w:SetText(Spectral.getConfigRaw(self.category, key, perChar) or "")
        end)
        w:SetScript("OnEnterPressed", function()
          Spectral.setConfig(self.category, key, w:GetText(), perChar)
          w:ClearFocus()
          self:_updated()
        end)
      end
      
      return w
    end
    
    function p:optText(key, label, y)
      local g = CreateFrame("Frame", nil, self)
      g:SetPoint("LEFT", 0, 0)
      g:SetPoint("RIGHT", -8, 0)
      g:SetPoint("TOP", 0, y)
      
      local lbl = g:CreateFontString("ARTWORK", nil, "GameFontNormalMed2")
      lbl:SetPoint("TOPLEFT")
      lbl:SetText(label);
      
      local lw = 80
      local lh = 20
      
      local lg = g:CreateFontString("ARTWORK", nil, "GameFontNormal")
      lg:SetPoint("TOP", 0, -lh-3) lg:SetPoint("LEFT")
      lg:SetText("Global")
      
      local eg = CreateFrame("EditBox", nil, g, "InputBoxTemplate")
      eg:SetHeight(20)
      eg:SetPoint("TOP", 0, -lh) eg:SetPoint("LEFT", lg, "RIGHT", 12, 0) eg:SetPoint("RIGHT", g, "CENTER", -4, 0)
      self:bind(eg, key, false) eg:SetAutoFocus(false)
      
      local ll = g:CreateFontString("ARTWORK", nil, "GameFontNormal")
      ll:SetPoint("TOP", 0, -lh-3) ll:SetPoint("LEFT", g, "CENTER", 4, 0)
      ll:SetText("Character")
      
      local el = CreateFrame("EditBox", nil, g, "InputBoxTemplate")
      el:SetHeight(20)
      el:SetPoint("TOP", 0, -lh) el:SetPoint("LEFT", ll, "RIGHT", 12, 0) el:SetPoint("RIGHT")
      self:bind(el, key, true) el:SetAutoFocus(false)
      
      return g
    end
    
    return p
  end
  
  local main = pane "Spectral"
  
  
  do local p = pane "Mount Macro"
    p.category = "mount"
    function p.updateEvent()
      Spectral.macros["spx:mount"]:reset()
    end
    
    --[[local title = p:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
    title:SetPoint("TOP")
    title:SetText("MyAddOn")--]]
    
    --[[local ea = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    --ea:SetHeight(20)
    ea:SetAutoFocus(false)
    ea:SetSize(200, 20)
    ea:SetPoint("TOPLEFT", 20, -20)
    p:bind(ea, "dragonMount", true)--]]
    
    local adc = -4
    local sh = 48
    local function adv(h)
      local t = adc
      adc = adc - h
      return t
    end
    p:optText("normalMount", "Normal Mount", adv(sh))
    p:optText("dragonMount", "Dragon Riding Mount", adv(sh))
  end
  
  
  
end
