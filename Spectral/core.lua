Spectral = { }
local Spectral = Spectral

local macros = { }
Spectral.macros = macros
local fragments = { }
Spectral.fragments = fragments

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
    
    f = CreateFrame("Button", name, nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
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
    m:reinit()
    macros[name] = m
    
    return m
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
    self.initialFragment = processFragment(self:buildFunc())
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





C_Timer.After(1, function()
  local branch = Spectral.branch
  
  local m = Spectral.createMacro("Mount", function()
    return {
      "/run print(\"macro test\")",
      "/dismount", "/leavevehicle [canexitvehicle]",
      branch { c = "[outdoors,noform:3,nocombat]",
        "/cast !Travel Form"
      } { c = "[spec:3,noform:1]",
        "/cast !Bear Form"
      } {
        "/cancelform [noform:2]",
        "/cast [nocombat]!Prowl",
        "/cast [nostealth,noform:2]!Cat Form"
      }
    }
  end)
  m:rebuild()
  --print(f.fragmentId)
end)
