-- stock macros
local Spectral = Spectral
local branch = Spectral.branch

local m

local normalMount, mawMount, aquaticMount
local mountsList = {
  "Vulpine Familiar",
}
local mawMountsList = {
  "Corridor Creeper", "Mawsworn Soulhunter", -- known Maw-capable mounts
  "Running Wild", -- Worgen racial works in the Maw
}
local aquaticMountsList = {
  "Subdued Seahorse", "Saltwater Seahorse", -- Vashj'ir seahorse model
  "Crimson Tidestallion", "Inkscale Deepseeker", "Fabious", -- tidestallions
  "Darkwater Skate", "Great Sea Ray", -- rays
  "Fathom Dweller", "Surf Jelly", "Pond Nettle", -- jellyfeesh
  
  "Sea Turtle", "Riding Turtle", -- turtles
  "Brinedeep Bottom-Feeder", -- the ugly fish
  
}
local function findMounts()
  local function find(l)
    for _, m in pairs(l) do
      if Spectral.isSpell(m) then return m end
    end
  end
  
  normalMount = find(mountsList)
  mawMount = find(mawMountsList)
  aquaticMount = find(aquaticMountsList)
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
      if Spectral.zoneIsFlyable() then -- need to hack around the [flyable] condition being broken
        tfc = "/cast [combat,noswimming]!Mount Form;!Travel Form"
      else
        tfc = "/cast [noswimming]!Mount Form;!Travel Form"
      end
    end
    
    local cc = "][outdoors,harm,form:" .. druidCombatForm[pd.specId] .. "]" -- combat condition
    
    return {
      "@name Form",
      "/dismount", "/leavevehicle [canexitvehicle]",
      branch (function()
        if pd.specId == 4 then -- resto, moonkin when holding alt
          return { c = "[spec:4,noform:1,mod:alt]",
            "/cast !Moonkin Form",
          }
        end
      end) { c = "[outdoors,noform:3,noharm" .. mc .. cc,
        tfc,
      } (function() -- only build for our given spec since we're rebuilding on spec switch anyway
        if pd.specId == 1 and Spectral.spellKnown "Moonkin Form" then
          return { c = "[spec:1,noform:4]",
            "/cast !Moonkin Form",
          }
        elseif pd.specId == 4 then
          return { c = "[spec:4,noform:0]",
            "/cancelform",
            "#show [form:3]Travel Form;Mount Form",
          }
        elseif pd.specId == 3 then
          return { c = "[spec:3,noform:1]",
            "/cast !Bear Form",
          }
        end
      end) {
        "#show Cat Form",
        "/cancelform [noform:2]",
        "/cast [nocombat]!Prowl",
        "/cast [nostealth,noform:2]!Cat Form"
      }
    }
  else -- normal mount
    local z = Spectral.currentZone()
    if not normalMount then findMounts() end
    local mount = (z ~= "The Maw") and normalMount or mawMount
    if z == "Vashj'ir" and Spectral.isSpell "Vashj'ir Seahorse" then
      mount = "[swimming,nomod:alt]Vashj'ir Seahorse;" .. mount -- this is faster than other aquatic mounts apparently?
    elseif aquaticMount then
      mount = string.format("[swimming,nomod:alt]%s;%s", aquaticMount, mount)
    end
    
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
