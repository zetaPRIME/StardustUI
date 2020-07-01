--

do
  --
end

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

local playerSurround = CreateFrame("FRAME", "StarFrame:PlayerSurround", UIParent)
--playerSurround:Hide()
local parent

playerSurround:RegisterEvent('WORLD_MAP_OPEN')
playerSurround:RegisterEvent('NAME_PLATE_UNIT_ADDED')
playerSurround:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

playerSurround:SetHeight(1)
playerSurround:SetWidth(1)
playerSurround:SetScript("onUpdate", function(self, elapsed)
  local parent = parent
  if WeakAuras and WeakAuras.IsOptionsOpen() then -- force display
    if not WeakAuras.personalRessourceDisplayFrame then -- hack to force PRD frame to exist
      local nf = function() end
      WeakAuras.AnchorFrame(
        { anchorFrameType = "PRD", id = "" },
        {
          id = "",
          SetAnchor = nf,
          SetFrameStrata = nf,
          SetFrameLevel = nf,
          SetParent = nf,
        }
      )
    end
    
    self:SetParent(UIParent)--WeakAuras.personalRessourceDisplayFrame)
    self:Show()
    self:ClearAllPoints()
    WeakAuras.personalRessourceDisplayFrame:Show()
    self:SetPoint("CENTER", WeakAuras.personalRessourceDisplayFrame, "TOP", 0, 150)
    self:SetScale(1)
    self:SetAlpha(1)
    
    return nil
  end
  
  if not parent then self:SetAlpha(0) return nil end
  self:SetParent(parent)
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
  self:SetPoint("CENTER", parent, "TOP", 0, cp/scale)
  self:Show()
end)

playerSurround:SetScript("onEvent", function(self, event, nameplate)
  if (event == "NAME_PLATE_UNIT_ADDED") then
    if (UnitIsUnit(nameplate, "player")) then
      local frame = C_NamePlate.GetNamePlateForUnit("player")
      if (frame) then
        if (frame.kui and frame.kui.bg and frame.kui:IsShown()) then
          parent = frame.kui
        elseif (ElvUIPlayerNamePlateAnchor) then
          parent = ElvUIPlayerNamePlateAnchor
        else
          parent = frame
        end
        playerSurround:SetParent(parent)
        playerSurround:Show()
      else
        parent, zoomAcc = nil
        playerSurround:ClearAllPoints()
        --playerSurround:Hide()
        playerSurround:SetParent(UIParent)
      end
    end
  elseif (event == "NAME_PLATE_UNIT_REMOVED") then
    if (UnitIsUnit(nameplate, "player")) then
      parent, zoomAcc = nil
      playerSurround:ClearAllPoints()
      --playerSurround:Hide()
      playerSurround:SetParent(UIParent)
    end
  end
end)
