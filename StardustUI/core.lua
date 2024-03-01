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

function ui.spellKnown(...)
  local name, rank, icon, castTime, minR, maxR, spellId = GetSpellInfo(...)
  if not spellId then return nil end
  return IsSpellKnown(spellId)
end

function ui.isSpell(...)
  local name, rank, icon, castTime, minR, maxR, spellId = GetSpellInfo(...)
  return not not spellId
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
  
  Dracthyr = 1.25, -- base on main form
}

local barMargin = 56 / 512
-- sets a texture widget to a specific slice of its parent within bar range
local function setBarRange(tx, mn, mx)
  local p = tx:GetParent()
  local ph = p:GetHeight()
  local r = 1.0 - barMargin*2 -- amount of "real" area there is between the margins
  
  local top = barMargin + (1.0-mx)*r
  local bot = barMargin + mn*r
  
  tx:SetPoint("TOP", p, "TOP", 0, -ph * top)
  tx:SetPoint("BOTTOM", p, "BOTTOM", 0, ph * bot)
  tx:SetTexCoord(0, 1, top, 1-bot)
end

local prd
ui.playerSurround = ui.createFrame("Frame", nil, UIParent)

ui.playerSurround:SetHeight(1) ui.playerSurround:SetWidth(1)
ui.playerSurround:SetFrameStrata("MEDIUM")
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
  self.scaleProp = scaleProp -- save this for later
  local scale = Lerp(maxScale, minScale, scaleProp)
  self:SetScale(scale)
  
  self:ClearAllPoints()
  if zoom == 0 then
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  else
    self:SetPoint("CENTER", prd, "TOP", 0, cp/scale + 25)
  end
  self:Show()
  
  prd:SetAlpha(0) -- don't need to show this
  
  -- parent cast bar by brute force since UIPARENT_MANAGED_FRAME_POSITIONS doesn't exist anymore
  pcall(function()
    PlayerCastingBarFrame:SetParent(ui.playerSurround)
    PlayerCastingBarFrame:ClearAllPoints()
    PlayerCastingBarFrame:SetPoint("CENTER", ui.playerSurround, "CENTER", 0, -110)
    PlayerCastingBarFrame:SetScale(1.5)
    --PlayerCastingBarFrame:SetFrameStrata("LOW")
    --PlayerCastingBarFrame:Lower()
    --UIPARENT_MANAGED_FRAME_POSITIONS.CastingBarFrame = nil -- disable UIParent trying to set points
  end)
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

-- handle setting up and reverting cvars
local function setupCVars()
  if InCombatLockdown() then return end -- nnnnnope
  SetCVar("nameplatePersonalShowAlways", 1)
  SetCVar("nameplateSelfBottomInset", 0.10)
end
C_Timer.After(0.1, setupCVars)
C_Timer.After(5, setupCVars)

function ui.playerSurround.events:ADDONS_UNLOADING()
  -- revert cvar tinkering (to defaults)
  SetCVar("nameplatePersonalShowAlways", 0)
  SetCVar("nameplateSelfBottomInset", 0.2)
end

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
ui.playerHud:SetHeight(2*120) ui.playerHud:SetWidth(2*150)
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
  local buffArea = ui.createFrame("Frame", "StardustUI:PlayerBuffs", ui.playerHud)
  ui.playerHud.buffArea = buffArea
  buffArea:SetSize(1, 1)
  buffArea:SetPoint("CENTER", ui.playerHud, "TOP", 0, 0)
  
  local healthBar = ui.createFrame("Frame", nil, ui.playerHud)
  ui.playerHud.healthBar = healthBar
  healthBar:SetSize(64, 256)
  healthBar:SetPoint("CENTER", ui.playerHud, "LEFT", 0, 0)
  
  healthBar.fill = healthBar:CreateTexture(nil, "ARTWORK")
  healthBar.fill:SetTexture(ui.texture "healthBarFill")
  healthBar.fill:SetVertexColor(1.0, 0.10, 0.25)
  healthBar.fill:SetPoint("LEFT", healthBar, "LEFT")
  healthBar.fill:SetPoint("RIGHT", healthBar, "RIGHT")
  
  healthBar.heal = healthBar:CreateTexture(nil, "ARTWORK")
  healthBar.heal:SetTexture(ui.texture "healthBarFill")
  healthBar.heal:SetVertexColor(0.25, 0.75, 0.70)
  healthBar.heal:SetPoint("LEFT", healthBar, "LEFT")
  healthBar.heal:SetPoint("RIGHT", healthBar, "RIGHT")
  
  healthBar.shield = healthBar:CreateTexture(nil, "ARTWORK", nil, 5)
  healthBar.shield:SetTexture(ui.texture "healthBarFill")
  healthBar.shield:SetVertexColor(1.0, 1.0, 1.0, 0.666)
  healthBar.shield:SetPoint("LEFT", healthBar, "LEFT")
  healthBar.shield:SetPoint("RIGHT", healthBar, "RIGHT")
  healthBar.shield:SetBlendMode("ADD")
  
  healthBar.bg = healthBar:CreateTexture(nil, "BACKGROUND")
  healthBar.bg:SetTexture(ui.texture "healthBarBackground")
  healthBar.bg:SetAllPoints(true)
  
  healthBar:Show()
  
  local powerBar = ui.createFrame("Frame", nil, ui.playerHud)
  ui.playerHud.powerBar = powerBar
  powerBar:SetSize(64, 256)
  powerBar:SetPoint("CENTER", ui.playerHud, "RIGHT", 0, 0)
  
  powerBar.fill = powerBar:CreateTexture(nil, "ARTWORK")
  powerBar.fill:SetTexture(ui.texture "powerBarFill")
  powerBar.fill:SetPoint("LEFT", powerBar, "LEFT")
  powerBar.fill:SetPoint("RIGHT", powerBar, "RIGHT")
  
  powerBar.bg = powerBar:CreateTexture(nil, "BACKGROUND")
  powerBar.bg:SetTexture(ui.texture "powerBarBackground")
  powerBar.bg:SetAllPoints(true)
  
  powerBar:Show()
  
  local powerBar2 = ui.createFrame("Frame", nil, ui.playerHud)
  ui.playerHud.powerBar2 = powerBar2
  powerBar2:SetSize(64, 256)
  powerBar2:SetPoint("CENTER", ui.playerHud, "RIGHT", 24, 0)
  
  powerBar2.fill = powerBar2:CreateTexture(nil, "ARTWORK")
  powerBar2.fill:SetTexture(ui.texture "powerBarFill")
  powerBar2.fill:SetPoint("LEFT", powerBar2, "LEFT")
  powerBar2.fill:SetPoint("RIGHT", powerBar2, "RIGHT")
  
  powerBar2.bg = powerBar2:CreateTexture(nil, "BACKGROUND")
  powerBar2.bg:SetTexture(ui.texture "powerBarBackground")
  powerBar2.bg:SetAllPoints(true)
  
  powerBar2:Show()
end

ui.playerHud:SetScript("onUpdate", function(self, dt)
  setupCVars() -- fuck it, sledgehammer
  
  local health = UnitHealth("player")
  local healthMax = UnitHealthMax("player")
  local healthProportion = health / healthMax
  
  local targetAlpha = 0
  if healthProportion < 0.75 then targetAlpha = 0.3 end
  if UnitExists("target")
    and UnitCanAttack("player", "target")
    and not UnitIsDead("target")
    and (UnitIsEnemy("target", "player") or not IsTargetLoose()) -- don't pop up on soft targeting a passive
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
    
    local bscale = Lerp(1.0, 2.0, clamp(ui.playerSurround.scaleProp or 0))
    self.buffArea:SetScale(bscale)
    
    pcall(function() -- wrap this because otherwise it spams errors on zone load no matter how I try to validate
      local heal = min((health + UnitGetIncomingHeals("player")) / healthMax, 1.0)
      local shield = min(UnitGetTotalAbsorbs("player") / healthMax, 1.0)
      
      setBarRange(self.healthBar.fill, 0, healthProportion)
      setBarRange(self.healthBar.heal, healthProportion, heal)
      setBarRange(self.healthBar.shield, 0, shield)
      
      if self.powerType then
        local v, max, p = ui.getPowerValues(self.powerType)
        setBarRange(self.powerBar.fill, 0, p)
      end
      if self.powerType2 then
        local v, max, p = ui.getPowerValues(self.powerType2)
        setBarRange(self.powerBar2.fill, 0, p)
      end
    end)
  end
  
end)

local powerTypeStats -- forward declare

local PowerTypes = { -- name, is combo point
  [0] = {"MANA", primary = true},
  [1] = {"RAGE", primary = true},
  [2] = {"FOCUS", primary = true},
  [3] = {"ENERGY", primary = true},
  [4] = {"COMBO_POINTS", true},
  [5] = {"RUNES", true, func = function(pt)
    local m = UnitPowerMax("player", pt.id)
    v = 0
    for i = 1, math.floor(m) do
      if GetRuneCount(i) ~= 0 then v = v + 1 end
    end
    return v, m
  end},
  [6] = {"RUNIC_POWER", primary = true},
  [7] = {"SOUL_SHARDS", true, func = function(pt)
    local v = UnitPower("player", pt.id, true) / 10
    local m = UnitPowerMax("player", pt.id)
    return v, m
  end},
  [8] = {"LUNAR_POWER"}, -- astral power
  [9] = {"HOLY_POWER", true},
  [11] = {"MAELSTROM"},
  [12] = {"CHI", true},
  [13] = {"INSANITY"},
  [16] = {"ARCANE_CHARGES", true},
  [17] = {"FURY", primary = true},
  [18] = {"PAIN", primary = true}, -- no longer exists but whatever
  [19] = {"ESSENCE", primary = true},
  --
}

local PowerTypeOverride = {
  DRUID1 = {0, 8}, -- balance
  DRUID2 = {3, 4}, -- feral druid
  DRUID3 = {1, false}, -- guardian druid
  DRUID4 = {0, false}, -- resto druid
  SHAMAN2 = {0, function(u)  -- enh shaman; maelstrom weapon stacks
    --if not IsSpellKnown(187880) then return end -- don't have Maelstrom Weapon unlocked yet
    local m = powerTypeStats(u, 11) -- maelstrom
    function m.valueFunc(pt)
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(344179)
      if not aura then return 0, 1 end
      local max = IsPlayerSpell(384143) and 10 or 5
      return aura.applications, max
    end
    return m
  end},
  EVOKER1 = {19, 0},
  EVOKER2 = {19, 0},
}

powerTypeStats = function(u, id)
  if id == false then return nil end
  if type(id) == "function" then return id(u) end
  if UnitPowerMax(u or "player", id) <= 0 then return nil end
  local pt = PowerTypes[id]
  if not pt then return nil end
  local pc = PowerBarColor[pt[1]] or {r = 0, g = 255, b = 255}
  return { id = id, type = pt[1], isCombo = pt[2], color = {pc.r, pc.g, pc.b}, isPrimary = pt.primary, valueFunc = pt.func }
end

local function powerStats(u, i)
  local n = UnitPowerType(u or "player", i)
  return powerTypeStats(u, n)
end

function ui.getPowerValues(pt, f)
  local v, m, p
  if pt.valueFunc then
    v, m, p = pt.valueFunc(pt)
  else
    v = UnitPower("player", pt.id)
    m = UnitPowerMax("player", pt.id)
  end
  p = p or (v/m)
  if f then return p end
  return v, m, p
end

function ui.playerHud:setupForSpec()
  if not InCombatLockdown() then
    C_NamePlate.SetNamePlateSelfClickThrough(true) -- ...
  end
  
  local classDisplayName, className, classId = UnitClass("player")
  local specId = GetSpecialization()
  
  local bpi = 24
  local bpos = bpi
  self.powerBar:Hide()
  self.powerBar2:Hide()
  
  self.powerType = powerStats("player", 0)
  self.powerType2 = nil
  
  local foundPrimary, foundSecondary = true, false
  for k, v in pairs(PowerTypes) do
    local ps = powerTypeStats("player", k)
    if ps then
      if ps.isPrimary then
        --self.powerType = ps
        foundPrimary = true
      elseif not foundSecondary then
        self.powerType2 = ps
        foundSecondary = true
      end
      if foundPrimary and foundSecondary then break end
    end
  end
  
  local pto = PowerTypeOverride[className .. specId]
  if pto then
    if pto[1] ~= nil then self.powerType = powerTypeStats("player", pto[1]) end
    if pto[2] ~= nil then self.powerType2 = powerTypeStats("player", pto[2]) end
  end
  
  if self.powerType and self.powerType2 and self.powerType2.type == self.powerType.type then self.powerType2 = nil end -- no double bar
  
  --print("primary:" .. (self.powerType and self.powerType.type or "none"))
  --print("secondary:" .. (self.powerType2 and self.powerType2.type or "none"))
  
  if self.powerType then
    self.powerBar:Show()
    self.powerBar.fill:SetVertexColor(unpack(self.powerType.color))
  end
  
  if self.powerType2 then
    self.powerBar2:Show()
    self.powerBar2.fill:SetVertexColor(unpack(self.powerType2.color))
    self.powerBar2:SetPoint("CENTER", self, "RIGHT", bpos, 0)
    bpos = bpos + bpi
  end
end

function ui.playerHud.events:PLAYER_SPECIALIZATION_CHANGED() C_Timer.After(0.1, function() self:setupForSpec() end) end
ui.playerHud.events.PLAYER_TALENT_UPDATE = ui.playerHud.events.PLAYER_SPECIALIZATION_CHANGED
ui.playerHud.events.PLAYER_LEVEL_CHANGED = ui.playerHud.events.PLAYER_SPECIALIZATION_CHANGED
local loaded
function ui.playerHud.events:ADDON_LOADED()
  if not loaded then loaded = true C_Timer.After(0.1, function() self:setupForSpec() end) end
  
  --
end
