-- stock macros
local Spectral = Spectral
local branch = Spectral.branch

local m

local normalMount, mawMount
local mountsList = {
  "Vulpine Familiar",
}
local mawMountsList = {
  "Corridor Creeper", "Mawsworn Soulhunter", -- known Maw-capable mounts
  "Running Wild", -- Worgen racial works in the Maw
}
local function findMounts()
  for _, m in pairs(mountsList) do
    if Spectral.isSpell(m) then
      normalMount = m
      break
    end
  end
  
  for _, m in pairs(mawMountsList) do
    if Spectral.isSpell(m) then
      mawMount = m
      break
    end
  end
end

local druidCombatForm = {
  4, 2, 1, 0
}

m = Spectral.createMacro("Mount", function()
  local pd = Spectral.getPlayerData()
  
  if pd.className == "DRUID" then -- shapeshift macro
    -- travel stuff
    local mc = "" -- mount condition
    local tfc = "/cast !Travel Form" -- travel form command
    if Spectral.spellKnown "Mount Form" then
      local f = 4
      if Spectral.spellKnown "Moonkin Form" then f = f + 1 end
      if Spectral.spellKnown "Treant Form" then f = f + 1 end
      mc = ",noform:" .. f
      tfc = "/cast [noflyable,noswimming]!Mount Form;!Travel Form"
    end
    
    local cc = "][outdoors,harm,form:" .. druidCombatForm[pd.specId] .. "]" -- combat condition
    
    
    return {
      "@name Form",
      "/dismount", "/leavevehicle [canexitvehicle]",
      branch { c = "[outdoors,noform:3,noharm" .. mc .. cc,
        tfc,
      } { c = "[spec:4,noform:0]",
        "/cancelform",
      } { c = "[spec:3,noform:1]",
        "/cast !Bear Form",
      } {
        "#show Cat Form",
        "/cancelform [noform:2]",
        "/cast [nocombat]!Prowl",
        "/cast [nostealth,noform:2]!Cat Form"
      }
    }
  else -- normal mount
    if not normalMount then findMounts() end
    local mount = (GetAreaText() ~= "The Maw") and normalMount or mawMount
    
    return {
      "#show " .. mount,
      branch { c = "[nomounted,nocanexitvehicle]",
        "/cast " .. mount,
        (function() if Spectral.spellKnown "Ghost Wolf" then return "/cast Ghost Wolf" end end)(),
      } {
        "/dismount",
        "/leavevehicle [canexitvehicle]",
        --"#show item:142513",
      }
    }
  end
end)
m:updatesOn "zone" -- can change on entering the maw

m = Spectral.createMacro("Stealth", function()
  local pd = Spectral.getPlayerData()
  
  if pd.className == "DRUID" then
    return {
      "/cancelaura Travel Form",
      "/cast Prowl",
    }
  elseif pd.className == "ROGUE" then
    return {
      "/cast [combat]Vanish;Stealth",
    }
  else
    return Spectral.inactiveBinding()
  end
end)
