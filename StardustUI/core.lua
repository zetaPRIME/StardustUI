--
StardustUI = { }
local ui = StardustUI

ui.texturePath = "Interface/Addons/StardustUI/textures/"
function ui.texture(p) return ui.texturePath .. (p or "") end

local zoomAcc
local minScale, maxScale = 0.5, 1.5
local minScaleZoom, maxScaleZoom = 17.5, 3

local raceHeight = {
  Tauren = 1.25, HighmountainTauren = 1.25,
  Dwarf = 0.75, DarkIronDwarf = 0.75,
  Gnome = 0.5, Mechagnome = 0.5,
  Goblin = 0.5,
  Vulpera = 0.5,
}

local prd
ui.playerSurround = CreateFrame("FRAME", nil, UIParent)

ui.playerSurround:RegisterEvent "ADDONS_UNLOADING"
ui.playerSurround:RegisterEvent "NAME_PLATE_UNIT_ADDED"
ui.playerSurround:RegisterEvent "NAME_PLATE_UNIT_REMOVED"

ui.playerSurround:SetHeight(1) ui.playerSurround:SetWidth(1)
ui.playerSurround:SetScript("onUpdate", function(self, elapsed)
  if not prd then self:SetAlpha(0) return nil end
  
  prd:SetAlpha(0)
  
  self:SetParent(prd)
  --if self:GetParent() ~= parent then self:SetParent(parent) end
  self:SetAlpha(1)
  self:Show()
  
  local _, race = UnitRace("player")
  
  local zoom = GetCameraZoom()
  if not zoomAcc then zoomAcc = zoom end
  
  zoomAcc = Lerp(zoomAcc, zoom, elapsed * 15)
  if math.abs(zoomAcc - zoom) < 0.1 then zoomAcc = zoom end
  
  local ezoom = zoomAcc
  if ezoom > minScaleZoom then ezoom = minScaleZoom + (ezoom - minScaleZoom) * 0.5 end
  local cp = 500 - (ezoom^1.1) * 11
  cp = cp * 0.3 * (raceHeight[race] or 1.0)
  
  local scaleProp = math.max(0, math.min(1, (zoomAcc-maxScaleZoom) / (minScaleZoom-maxScaleZoom)))
  scaleProp = scaleProp ^ 0.5
  local scale = Lerp(maxScale, minScale, scaleProp)
  self:SetScale(scale)
  
  self:ClearAllPoints()
  self:SetPoint("CENTER", prd, "TOP", 0, cp/scale)
  self:Show()
end)

ui.playerSurround:SetScript("onEvent", function(self, event, nameplate)
  if event == "ADDONS_UNLOADING" then
    -- revert cvar tinkering
    SetCVar("nameplatePersonalShowAlways", 0)
  elseif event == "NAME_PLATE_UNIT_ADDED" then
    if UnitIsUnit(nameplate, "player") then
      local frame = C_NamePlate.GetNamePlateForUnit("player")
      if (frame) then
        if (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
          prd = frame.kui
        elseif (ElvUIPlayerNamePlateAnchor) then
          prd = ElvUIPlayerNamePlateAnchor
        else
          prd = frame
        end
        self:SetParent(prd)
        self:Show()
        prd:Hide() -- hide default display
      else
        prd, zoomAcc = nil
        self:ClearAllPoints()
        --ui.playerSurround:Hide()
        self:SetParent(UIParent)
      end
    end
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    if UnitIsUnit(nameplate, "player") then
      prd, zoomAcc = nil
      self:ClearAllPoints()
      --ui.playerSurround:Hide()
      self:SetParent(UIParent)
    end
  end
end)

-- tinker with this
SetCVar("nameplatePersonalShowAlways", 1)
