Spectral = { }
local Spectral = Spectral

-- public tables
local macros = { }
Spectral.macros = macros
local fragments = { }
Spectral.fragments = fragments

-- set up base frame
local baseFrame = CreateFrame("Frame")
baseFrame:Hide()
baseFrame.events = setmetatable({ }, {
  __newindex = function(table, key, value)
    rawset(table, key, value)
    baseFrame:RegisterEvent(string.upper(key))
  end
})
baseFrame:SetScript("onEvent", function(self, event, ...)
  if self.events[event] then self.events[event](self, ...) end
end)

-- fragment works
local processingMacro
local lastFragment = 0
local fragmentPool = { }

-- grab a fragment from the pool if it contains any, or initialize one if not
local function getFragment()
  local f
  for k in pairs(fragmentPool) do f = k break end
  if f then fragmentPool[f] = nil else
    local name = "SPXf" .. lastFragment
    lastFragment = lastFragment + 1
    
    f = CreateFrame("Button", name, baseFrame, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    f.fragmentId = name
    f:Hide()
    f:SetAttribute("type", "macro")
    
    fragments[name] = f
  end
  -- autoassign if operating on a macro
  if processingMacro then processingMacro.fragments[f] = true end
  
  return f
end

-- return a fragment to the pool
local function collectFragment(f)
  fragmentPool[f] = true
  f:SetAttribute("macrotext", "") -- maybe free some memory
end

local charLimit = 1022 - string.len("/click SPXf12345678")
local function processFragment(inp)
  
  local f = getFragment() -- initial fragment
  local cf = f -- current operating fragment
  local acc = { }
  local cc = 0
  
  for ln, line in pairs(inp) do
    if type(line) == "table" then
      if line[1] then
        line = table.concat(line)
      end
    end
    
    local lcc = string.len(line) + 1
    if cc + lcc > charLimit then
      local xf = getFragment() -- extend fragment
      table.insert(acc, "/click ")
      table.insert(acc, xf.fragmentId)
      
      cf:SetAttribute("macrotext", table.concat(acc))
      acc = { } cc = 0 cf = xf
    else
      cc = cc + lcc
      table.insert(acc, line) table.insert(acc, "\n")
    end
  end
  
  cf:SetAttribute("macrotext", table.concat(acc))
  
  return f
end

do -- branch ops
  local bp = { }
  local bmt = {__index = bp}
  
  function Spectral.branch(t)
    local condition = t.condition or t.c or ""
    t.c = nil t.condition = nil
    
    local bt = setmetatable({ }, bmt)
    
    table.insert(bt, "/click ")
    table.insert(bt, condition)
    local f = processFragment(t)
    table.insert(bt, f.fragmentId)
    
    return bt
  end
  
  function bp:branch(t)
    local condition = t.condition or t.c or ""
    t.c = nil t.condition = nil
    
    table.insert(self, ";")
    table.insert(self, condition)
    local f = processFragment(t)
    table.insert(self, f.fragmentId)
    
    return self
  end
  bmt.__call = bp.branch
  
end

do -- macro ops
  local mp = { }
  local mmt = {__index = mp}
  
  function Spectral.createMacro(name, func)
    if type(name) ~= "string" then return end
    local m = setmetatable({ }, mmt)
    m.name = name
    m.buildFunc = func
    m.updateReasons = { default = true }
    m:reinit()
    macros[name] = m
    
    return m
  end
  
  function mp:updatesOn(...)
    local a = {...}
    for _, r in pairs(a) do self.updateReasons[r] = true end
    return self
  end
  
  function mp:reinit()
    if self.fragments then
      for f in pairs(self.fragments) do collectFragment(f) end
    end
    self.fragments = { }
    self.initialFragment = nil
  end
  
  function mp:rebuild()
    self:reinit() -- reset fragments
    processingMacro = self
    self.initialFragment = processFragment(self:buildFunc() or { })
    processingMacro = nil
    self:updateBackingMacro()
    return self
  end
  
  function mp:findBackingMacro()
    if self.backingMacro then return end
    local search = table.concat {"#SPX ", self.name}
    local sl = string.len(search)
    local global, char = GetNumMacros()
    for i=1,120+char do
      if i <= 120 and i > global then i = 121 end
      if string.sub(GetMacroBody(i), 1, sl) == search then
        self.backingMacro = i
        return i
      end
    end
  end
  
  function mp:updateBackingMacro()
    self:findBackingMacro()
    if self.backingMacro then
      -- icon 134400 is the magic ?
      EditMacro(self.backingMacro, self.displayName or self.name, self.icon or 134400, table.concat {
        "#SPX ", self.name, "\n#showtooltip\n/click ", self.initialFragment.fragmentId
      })
    end
  end
  
  --
end

local updateReasons
local function doUpdate()
  if InCombatLockdown() -- wait for leaving combat event
    or not updateReasons -- update already done
    then return end
  
  -- scan through macros, rebuild for given reasons
  for _, m in pairs(macros) do
    local shouldUpdate = not m.initialFragment -- always update if not built
    if not shouldUpdate then -- find reasons
      for r in pairs(updateReasons) do
        if m.updateReasons[r] then shouldUpdate = true break end
      end
    end
    if shouldUpdate then m:rebuild() end
  end
  
  updateReasons = nil
end

function Spectral.queueUpdate(...)
  local a = {...}
  updateReasons = updateReasons or { }
  
  for _, r in pairs(a) do updateReasons[r] = true end
  
  if not InCombatLockdown() then C_Timer.After(0.05, doUpdate) end
end

-- queue initial update
C_Timer.After(0.1, function() Spectral.queueUpdate "default" end)

-- process queued updates on leaving combat
function baseFrame.events.PLAYER_REGEN_ENABLED() doUpdate() end

do -- default update events
  local function qdu() Spectral.queueUpdate "default" end
  baseFrame.events.PLAYER_SPECIALIZATION_CHANGED = qdu
  baseFrame.events.PLAYER_LEVEL_UP = qdu
end

-- other reasons
function baseFrame.events.ZONE_CHANGED_NEW_AREA() C_Timer.After(0.5, function() Spectral.queueUpdate "zone" end) end
--baseFrame.events.PLAYER_ENTERING_WORLD = 
