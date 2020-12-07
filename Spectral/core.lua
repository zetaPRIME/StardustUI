Spectral = { }
local Spectral = Spectral

local macros = { }
Spectral.macros = macros

local processingMacro

local lastFragment = 0
local fragmentPool = { }

-- grab a fragment from the pool if it contains any, or initialize one if not
local function getFragment()
  local frag
  for k in pairs(fragmentPool) do frag = k break end
  if frag then fragmentPool[frag] = nil else
    local name = "SPXf" .. lastFragment
    lastFragment = lastFragment + 1
    
    frag = CreateFrame("Button", name, nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    frag.fragmentId = name
    frag:Hide()
    frag:SetAttribute("type", "macro")
    
  end
  -- TODO: autoassign
  
  return frag
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

do
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
  
end





C_Timer.After(1, function()
  local sf = getFragment()
  
  local f = processFragment {
    "/dismount", "/leavevehicle [canexitvehicle]",
    Spectral.branch { c = "[outdoors,noform:3,nocombat]",
      "/cast !Travel Form"
    }:branch { c = "[spec:3,noform:1]",
      "/cast !Bear Form"
    }:branch {
      "/cancelform [noform:2]",
      "/cast [nocombat]!Prowl",
      "/cast [nostealth,noform:2]!Cat Form"
    }
  }
  
  sf:SetAttribute("macrotext", "/click " .. f.fragmentId)
  print(f.fragmentId)
end)
