-- Spectral utilities



function Spectral.spellKnown(...)
  local name, rank, icon, castTime, minR, maxR, spellId = GetSpellInfo(...)
  if not spellId then return nil end
  return IsSpellKnown(spellId)
end

function Spectral.isSpell(...)
  local name, rank, icon, castTime, minR, maxR, spellId = GetSpellInfo(...)
  return not not spellId
end

function Spectral.canUse(...)
  local name, rank, icon, castTime, minR, maxR, spellId = GetSpellInfo(...)
  return IsUsableSpell(spellId)
end

function Spectral.getPlayerData()
  local pd = { }
  local _
  pd.classDisplayName, pd.className, pd.classId = UnitClass("player")
  pd.specId = GetSpecialization()
  _, pd.race = UnitRace("player")
  
  return pd
end

function Spectral.inactiveBinding(name)
  if not name then
    m = Spectral.getProcessingMacro()
    name = m and m.name or ""
  end
  return {
    "@name ~ " .. string.lower(name),
    "@icon 3565717", -- red X
  }
end

do
  local pf = { -- pathfinder spell list
    bfa = 278833,
  }
  local zoneFlyMap = { -- referenced from LibFlyable
    -- zones that are always flyable as of Shadowlands prepatch
    [1116] = true, [1464] = true, -- Draenor and Tanaan Jungle
    [1152] = true, [1330] = true, [1153] = true, [1154] = true, -- horde garrison
    [1158] = true, [1331] = true, [1159] = true, [1160] = true, -- alliance garrison
    [1220] = true, -- Broken Isles
    
    -- zones requiring BFA pathfinder
    [1642] = pf.bfa, -- Zandalar
    [1643] = pf.bfa, -- Kul Tiras
    [1718] = pf.bfa, -- Nazjatar
    
    -- zones that will require a spell in the future
    [2222] = false, -- Shadowlands
    
    -- zones that aren't flyable despite IsFlyableArea saying otherwise
    [1669] = false, -- Argus
    [1463] = false, -- Helheim
    -- some class halls
    [1519] = false, -- The Fel Hammer (Demon Hunter)
    [1514] = false, -- The Wandering Isle (Monk)
    [1469] = false, -- The Heart of Azeroth (Shaman)
    [1107] = false, -- Dreadscar Rift (Warlock)
    [1479] = false, -- Skyhold (Warrior)
  }
  
  function Spectral.zoneIsFlyable()
    -- no zone is flyable to someone who can't fly yet
    if not (IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)) then return false end
    
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local ff = zoneFlyMap[instanceID]
    if ff == nil then return IsFlyableArea() end
    if type(ff) == "boolean" then return ff end
    return IsSpellKnown(ff)
  end
  
  --[[
  local dragonRidingMap = {
    -- names
    ["10.0 Dragon Isles"] = true,
    
    -- IDs
    [2444] = true, -- main Dragon Isles
    [2512] = true, -- "Grand Time Adventure" / Primalist Future (quest version?)
  } -- ]]
  
  function Spectral.zoneIsDragonRiding()
    return IsUsableSpell(368896) -- we can just check if the player is able to use the Renewed Proto-Drake
    --local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    --return dragonRidingMap[instanceID] or dragonRidingMap[name]
  end
  
  function Spectral.debugZoneInfo()
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    print("Current zone: \"" .. name .. "\" (" .. instanceID .. ")")
    if Spectral.zoneIsFlyable() then print "Zone is flyable" end
    if Spectral.zoneIsDragonRiding() then print "Zone allows dragon riding" end
  end
end

do
  local zoneMap = {
    ["Kelp'thar Forest"] = "Vashj'ir",
    ["Shimmering Expanse"] = "Vashj'ir",
    ["Abyssal Depths"] = "Vashj'ir",
  }
  
  function Spectral.currentZone()
    local z = GetAreaText()
    return zoneMap[z] or z
  end
end

function Spectral.castKnown(lst)
  local condition = lst.condition or lst.c or ""
  local fallback = lst.fallback or lst.fb
  
  for i = 1,99999 do
    local cd = lst[i]
    if not cd then break end
    if Spectral.spellKnown(cd) then -- found!
      return table.concat { "/cast ", condition, cd }
    end
  end
  
  if fallback then
    if string.sub(fallback, 1, 1) ~= "/" then return "/cast " .. fallback end
    return fallback
  end
end
