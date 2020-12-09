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
