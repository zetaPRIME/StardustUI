-- stock macros
local Spectral = Spectral
local branch = Spectral.branch

local m

m = Spectral.createMacro("Mount", function()
  local pd = Spectral.getPlayerData()
  
  -- TODO use ghost wolf for shaman
  
  if pd.className == "DRUID" then
    return {
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
  else
    return {
      branch { c = "[nomounted,nocanexitvehicle]",
        "/cast Vulpine Familiar",
        (function() if Spectral.spellKnown "Ghost Wolf" then return "/cast Ghost Wolf" end end)(),
      } {
        "/dismount",
        "/leavevehicle [canexitvehicle]",
        "#show item:142513",
      }
    }
  end
end)
