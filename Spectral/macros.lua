-- stock macros
local Spectral = Spectral
local branch = Spectral.branch

local m

m = Spectral.createMacro("Mount", function()
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
end)
