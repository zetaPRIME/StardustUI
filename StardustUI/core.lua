--
StardustUI = { }
local ui = StardustUI

local function clamp(value, min, max)
  return math.max(min or 0, math.min(max or 1, value))
end
local function sign(value) return value < 0 and -1 or 1 end

ui.texturePath = "Interface/Addons/StardustUI/textures/"
function ui.texture(p) return ui.texturePath .. (p or "") end

-- utility function for cleaner event registry
function ui.createFrame(...)
  local f = CreateFrame(...)
  f.events = setmetatable({ }, {
    __newindex = function(table, key, value)
      rawset(table, key, value)
      f:RegisterEvent(string.upper(key))
    end
  })
  f:SetScript("onEvent", function(self, event, ...)
    if self.events[event] then self.events[event](self, ...) end
  end)
  return f
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

local prd
ui.playerSurround = ui.createFrame("Frame", nil, UIParent)

ui.playerSurround:RegisterEvent "ADDONS_UNLOADING"
ui.playerSurround:RegisterEvent "NAME_PLATE_UNIT_ADDED"
ui.playerSurround:RegisterEvent "NAME_PLATE_UNIT_REMOVED"

ui.playerSurround:SetHeight(1) ui.playerSurround:SetWidth(1)
ui.playerSurround:SetFrameStrata("LOW")
ui.playerSurround:SetScript("onUpdate", function(self, dt)
  if not prd then self:SetAlpha(0) return nil end
  
  self:SetParent(UIParent)
  --if self:GetParent() ~= parent then self:SetParent(parent) end
  self:SetAlpha(1)
  self:Show()
  
  local _, race = UnitRace("player")
  
  local zoom = GetCameraZoom()
  if not zoomAcc then zoomAcc = zoom end
  
  zoomAcc = Lerp(zoomAcc, zoom, dt * 15)
  if math.abs(zoomAcc - zoom) < 0.1 then zoomAcc = zoom end
  
  local ezoom = zoomAcc
  if ezoom > minScaleZoom then ezoom = minScaleZoom + (ezoom - minScaleZoom) * 0.5 end
  local cp = 500 - (ezoom^1.1) * 11
  if ezoom < 10 then cp = cp + (10 - ezoom) * 60 end
  cp = cp * 0.3 * (raceHeight[race] or 1.0)
  
  local scaleProp = clamp((zoomAcc-maxScaleZoom) / (minScaleZoom-maxScaleZoom))
  scaleProp = scaleProp ^ 0.5
  local scale = Lerp(maxScale, minScale, scaleProp)
  self:SetScale(scale)
  
  self:ClearAllPoints()
  if zoom == 0 then
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  else
    self:SetPoint("CENTER", prd, "TOP", 0, cp/scale + 25)
  end
  self:Show()
  
  prd:Hide() -- hide default display
end)

--[[
ui.playerSurround.crosshair = ui.playerSurround:CreateTexture()
ui.playerSurround.crosshair:SetWidth(64)
ui.playerSurround.crosshair:SetHeight(64)
ui.playerSurround.crosshair:SetPoint("CENTER", ui.playerSurround, "CENTER", 0, 0)
ui.playerSurround.crosshair:SetTexture(165635)
ui.playerSurround.crosshair:SetAlpha(0.25)
ui.playerSurround.crosshair:Show()
--]]

function ui.playerSurround.events:ADDONS_UNLOADING()
  -- revert cvar tinkering (to defaults)
  SetCVar("nameplatePersonalShowAlways", 0)
  SetCVar("nameplateSelfBottomInset", 0.2)
end
SetCVar("nameplatePersonalShowAlways", 1)
SetCVar("nameplateSelfBottomInset", 0)

function ui.playerSurround.events:NAME_PLATE_UNIT_ADDED(nameplate)
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
      --self:SetParent(prd)
      self:Show()
    else
      prd, zoomAcc = nil
      self:ClearAllPoints()
      --ui.playerSurround:Hide()
      self:SetParent(UIParent)
    end
  end
end

function ui.playerSurround.events:NAME_PLATE_UNIT_REMOVED(nameplate)
  if UnitIsUnit(nameplate, "player") then
    prd, zoomAcc = nil
    self:ClearAllPoints()
    --ui.playerSurround:Hide()
    self:SetParent(UIParent)
  end
end

ui.playerHud = ui.createFrame("Frame", "StardustUI:PlayerHUD", ui.playerSurround)
ui.playerHud:SetHeight(1) ui.playerHud:SetWidth(2*150)
ui.playerHud:SetPoint("CENTER", ui.playerSurround, "CENTER", 0, 0)
ui.playerHud:Show()
ui.playerHud:SetAlpha(0.75)

-- parent proc frame to HUD
SpellActivationOverlayFrame:ClearAllPoints()
SpellActivationOverlayFrame:SetParent(ui.playerHud)
SpellActivationOverlayFrame:SetPoint("CENTER", ui.playerHud, "CENTER", 0, 0)
SpellActivationOverlayFrame:SetScale(1.5)
SpellActivationOverlayFrame:SetFrameStrata("LOW")
SpellActivationOverlayFrame:Lower()

do
  local healthBar = ui.createFrame("StatusBar", nil, ui.playerHud)
  ui.playerHud.healthBar = healthBar
  healthBar:SetHeight(256) healthBar:SetWidth(64)
  healthBar:SetPoint("CENTER", ui.playerHud, "LEFT", 0, 0)
  healthBar:SetStatusBarTexture(ui.texture "healthBarFill")
  healthBar:SetStatusBarColor(1, 0, 0)
  healthBar:SetOrientation("VERTICAL")
  
  healthBar:SetMinMaxValues(-0.14, 1.14)
  healthBar:SetValue(1)
  
  healthBar.bg = healthBar:CreateTexture(nil, "BACKGROUND")
  healthBar.bg:SetTexture(ui.texture "healthBarBackground")
  healthBar.bg:SetAllPoints(true)
  
  healthBar:Show()
  
  local powerBar = ui.createFrame("StatusBar", nil, ui.playerHud)
  ui.playerHud.powerBar = powerBar
  powerBar:SetHeight(256) powerBar:SetWidth(64)
  powerBar:SetPoint("CENTER", ui.playerHud, "RIGHT", 0, 0)
  powerBar:SetStatusBarTexture(ui.texture "powerBarFill")
  powerBar:SetOrientation("VERTICAL")
  
  powerBar:SetMinMaxValues(-0.14, 1.14)
  powerBar:SetValue(1)
  
  powerBar.bg = powerBar:CreateTexture(nil, "BACKGROUND")
  powerBar.bg:SetTexture(ui.texture "powerBarBackground")
  powerBar.bg:SetAllPoints(true)
  
  powerBar:Show()
end

ui.playerHud:SetScript("onUpdate", function(self, dt)
  local targetAlpha = 0
  if UnitExists("target")
    and UnitCanAttack("player", "target")
    and not UnitIsDead("target")
    then targetAlpha = 0.5 end
  if UnitAffectingCombat("player") then targetAlpha = 1 end
  
  self.alpha = self.alpha or targetAlpha
  local diff = targetAlpha - self.alpha
  self.alpha = self.alpha + math.min(math.abs(diff), dt * 3) * sign(diff)
  self:SetAlpha(self.alpha * 0.75)
  
  if self.alpha > 0 then -- update stats and display properties
    local scale = Lerp(1.5, 1.0, clamp(self.alpha*2)^0.5)
    self:SetScale(scale)
    self:SetWidth(2 * (150 + 250 * (1 - self.alpha^0.1)) / scale)
    
    self.healthBar:SetValue(UnitHealth("player") / UnitHealthMax("player"))
    self.powerBar:SetValue(UnitPower("player") / UnitPowerMax("player"))
  end
  
end)

function ui.playerHud:setupForSpec()
  local _, pt = UnitPowerType("player")
  local pc = PowerBarColor[pt]
  self.powerBar:SetStatusBarColor(pc.r, pc.g, pc.b)
end

function ui.playerHud.events:PLAYER_SPECIALIZATION_CHANGED() self:setupForSpec() end
function ui.playerHud.events:ADDON_LOADED() self:setupForSpec() end
