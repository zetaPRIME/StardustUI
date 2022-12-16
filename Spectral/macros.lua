-- stock macros
local Spectral = Spectral
local branch = Spectral.branch

local m

local normalMount, mawMount, aquaticMount, dragonMount
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
local dragonMountsList = { -- default to latest story dragon you have
  "Cliffside Wylderdrake",
  "Highland Drake",
  "Windborne Velocidrake",
  "Renewed Proto-Drake",
}
local function findMounts()
  local function find(l, cfg)
    if cfg then
      local c = Spectral.getConfig("mount", cfg)
      if Spectral.isSpell(c) then return c end
    end
    for _, m in pairs(l) do
      if Spectral.isSpell(m) then return m end
    end
  end
  
  normalMount = find(mountsList, "normalMount")
  mawMount = find(mawMountsList)
  aquaticMount = find(aquaticMountsList, "aquaticMount")
  dragonMount = find(dragonMountsList, "dragonMount")
  if not (IsSpellKnown(33388) or IsSpellKnown(33391) or IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)) then
    normalMount = find{"Summon Chauffeur"}
    mawMount = nil
    aquaticMount = nil
  end
end

local druidCombatForm = {
  4, 2, 1, 0
}

local mawMountable

m = Spectral.createMacro("spx:mount", "Mount", function()
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
    
    local form = druidCombatForm[pd.specId] or 0
    if form == 4 and not Spectral.spellKnown "Moonkin Form" then form = 0 end
    local cc = "][outdoors,harm,form:" .. form .. "]" -- combat condition
    
    return {
      "@name Form",
      "/cancelaura Path of Greed",
      "/dismount", "/leavevehicle [canexitvehicle]",
      branch (function()
        if pd.specId == 4 and Spectral.spellKnown "Moonkin Form" then -- resto, moonkin when holding alt+shift
          return { c = "[spec:4,noform:1,mod:alt,mod:shift]",
            "/cast !Moonkin Form",
          }
        end
      end) { c = "[outdoors,noform:3,noharm" .. mc .. cc,
        tfc,
      } (function() -- only build for our given spec since we're rebuilding on spec switch anyway
        if pd.specId == 1 then
          local mk = Spectral.spellKnown "Moonkin Form"
          return { c = "[spec:1,noform:" .. (mk and "4" or "0") .. "]",
            (not mk) and "#show Travel Form",
            "/cancelform",
            "/cast !Moonkin Form",
          }
        elseif pd.specId == 4 or pd.specId == 0 then
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
    if not normalMount and not mawMount and not aquaticMount then
      return {
        "#icon ",
      }
    end
    -- match zone, but no restriction if True Maw Walker is unlocked
    local inMaw = z == "The Maw" or z == "Korthia"
    if inMaw then
      mawMountable = mawMountable or (normalMount and IsUsableSpell(normalMount))
    end
    local mawRestriction = inMaw and not mawMountable
    local mount = (not mawRestriction) and normalMount or mawMount or ""
    if Spectral.zoneIsDragonRiding() then mount = dragonMount or mount end
    if z == "Vashj'ir" and Spectral.isSpell "Vashj'ir Seahorse" then
      mount = "[swimming,nomod:alt]Vashj'ir Seahorse;" .. mount -- this is faster than other aquatic mounts apparently?
    elseif aquaticMount then
      mount = string.format("[swimming,nomod:alt]%s;%s", aquaticMount, mount)
    end
    
    return {
      "#show " .. mount,
      branch { c = "[nomounted,nocanexitvehicle]",
        "/cancelaura Path of Greed",
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
m:updatesOn "mountable"
m:updatesOn "spx:mount:reset"
function m:reset()
  normalMount = nil -- next update will rerun findMounts()
  Spectral.queueUpdate "spx:mount:reset"
end

m = Spectral.createMacro("spx:stealth", "Stealth", function()
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

m = Spectral.createMacro("spx:interrupt", "Interrupt", function()
  return {
    "/stopcasting",
    Spectral.castKnown {
      c = "[@mouseover,harm][@focus,harm][]",
      -- direct interrupts
      "Solar Beam", "Skull Bash",
      "Counterspell",
      "Rebuke",
      "Kick",
      "Wind Shear",
      "Pummel",
      "Spell Lock", "Optical Blast",
      "Mind Freeze",
      "Spear Hand Strike",
      "Counter Shot",
      "Disrupt",
    },
  }
end)

m = Spectral.createMacro("dbg:zoneinfo", "Debug Zone Info", function()
  return { "#show item:187899", "/script Spectral.debugZoneInfo()" }
end)
