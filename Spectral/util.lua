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
  pd.classDisplayName, pd.className, pd.classId = UnitClass("player")
  pd.specId = GetSpecialization()
  
  return pd
end
