  local ok, gear = pcall(Pokegear.new, self.game, {
    save = self.game and self.game.save,
    currentLandmark = landmark,
  })
  if not ok then return nil end
  self.gear, self.gearRegion = gear, self.region
  return gear
end

function OpenSkyState:drawFallbackMap()
  local G = love.graphics
  G.setColor(0.60, 0.82, 0.95, 1)
  G.rectangle("fill", 0, 0, 160, 144)
  local atlas = type(openSkyApi.atlas) == "function" and openSkyApi.atlas() or nil
  G.setColor(0.20, 0.45, 0.28, 1)
  for _, anchor in ipairs((atlas and atlas[self.region]) or {}) do G.circle("fill", anchor.x or 0, anchor.y or 0, 2) end
end

function OpenSkyState:drawRegionalMap()
  local gear = self:mapGear()
  local cells = gear and gear.gfx and gear.gfx.maps and gear.gfx.maps[self.region]
  if gear and cells and type(gear.drawTilemap) == "function" then
    local ok = pcall(gear.drawTilemap, gear, cells)
    if ok then return true end
  end
  self:drawFallbackMap()
  return false
end

function OpenSkyState:drawMount()
  local G = love.graphics
  local sprite = flight.sprite
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(self.x), math.floor(self.y))
    G.scale(0.5, 0.5)
    G.setColor(1, 1, 1, 1)
    local phase = self.anim >= 16 and 1 or 0
    pcall(sprite.draw, sprite, -8, -8, 0, 0, self.facing, phase, false)
    G.pop()
  else
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", self.x, self.y - 4, self.x + 4, self.y + 4, self.x, self.y + 2, self.x - 4, self.y + 4)
  end
  G.setColor(1, 1, 1, 0.85)
  G.circle("line", math.floor(self.x), math.floor(self.y), 6)
end

function OpenSkyState:drawCalibrationHud(G, width, height, uiScale)
  if not self.calibrationMode or not (G and type(G.print) == "function") then return end
  local anchor, list = calibrationSelection(self)
  local saved = anchor and calibrationPoint(self.region, anchor.id) or nil
  local validated = calibrationValidatedCount(self.region)
  local scale = math.max(1, tonumber(uiScale) or 1)
  G.push()
  G.scale(scale, scale)
  local w = (tonumber(width) or 160) / scale
  local panelW = math.min(w - 8, 330)
  G.setColor(0, 0, 0, 0.82)
  G.rectangle("fill", 4, 20, panelW, 96)
  G.setColor(1, 1, 1, 0.98)
  local region = string.upper(tostring(self.region or "?"))
  pcall(G.print, string.format("CITY EDITOR [%s]  %d/%d   VALIDATED %d/%d", region, tonumber(self.calibrationIndex) or 0, #list, validated, #list), 8, 24)
  local label = anchor and tostring(anchor.name or anchor.id) or "NO CITY"
  if #label > 38 then label = label:sub(1, 38) end
  pcall(G.print, label, 8, 36)
  local id = anchor and tostring(anchor.id or "") or ""
  if #id > 42 then id = id:sub(1, 42) end
  pcall(G.print, id, 8, 48)
  local baseX, baseY = tonumber(anchor and anchor.x) or 0, tonumber(anchor and anchor.y) or 0
  local curX, curY = tonumber(self.x) or 0, tonumber(self.y) or 0
  local status = "[NOT VALIDATED]"
  if saved then
    local sx, sy = tonumber(saved.x) or 0, tonumber(saved.y) or 0
    if math.abs(curX - sx) < 0.005 and math.abs(curY - sy) < 0.005 then status = "[VALIDATED]" else status = "[CHANGED - F9 TO VALIDATE]" end
  end
  pcall(G.print, string.format("XY %.2f , %.2f   BASE %.2f , %.2f", curX, curY, baseX, baseY), 8, 60)
  pcall(G.print, string.format("DELTA %+.2f , %+.2f   %s", curX - baseX, curY - baseY, status), 8, 72)
  pcall(G.print, "ARROWS move   SHIFT=fine   CTRL=ultra fine", 8, 84)
  pcall(G.print, "F6/F7 city   F9 VALIDATE+NEXT   F10 reset", 8, 96)
  pcall(G.print, "F5 region   F11 COPY REPORT   F4 clear   F8 exit", 8, 108)
  G.pop()
end

function OpenSkyState:draw()
  if not (love and love.graphics) then return end
  local G = love.graphics
  G.push("all")
  G.clear(0.58, 0.80, 0.96, 1)
  self:drawRegionalMap()
  for _, point in ipairs(landingIndicators(self.game, self.region)) do
    local a = point.anchor
    local close = self.nearestLanding == point or (self.nearestLanding and self.nearestLanding.anchor and self.nearestLanding.anchor.id == a.id)
    if point.visited then
      G.setColor(0.20, 0.95, 0.38, 0.95)
      G.circle("fill", a.x, a.y, 2.0)
      G.setColor(1, 1, 1, 0.95)
      G.circle("line", a.x, a.y, 2.4)
    else
      G.setColor(0.95, 0.32, 0.28, 0.92)
      G.circle("line", a.x, a.y, 2.2)
      G.line(a.x - 1.4, a.y - 1.4, a.x + 1.4, a.y + 1.4)
      G.line(a.x - 1.4, a.y + 1.4, a.x + 1.4, a.y - 1.4)
    end
    if close and (self.nearestLandingDistance or math.huge) <= OPEN_SKY_LAND_RADIUS then
      G.setColor(1, 1, 1, 0.95)
      G.circle("line", a.x, a.y, OPEN_SKY_LAND_RADIUS)
    end
  end

  self:drawMount()
  G.setColor(0, 0, 0, 0.72)
  G.rectangle("fill", 0, 0, 160, 18)
  G.rectangle("fill", 0, 124, 160, 20)
  G.setColor(1, 1, 1, 1)
  local Chrome = chromeModule()
  local regionLabel = self.region == "kanto" and "OPEN SKY - KANTO" or "OPEN SKY - JOHTO"
  local nearestName = self.nearest and cleanName(self.nearest.row.name) or "NO VISITED CITY"
  local ready = (self.nearestDistance or math.huge) <= OPEN_SKY_LAND_RADIUS
  local nearestCity = self.nearestLanding
  local nearCity = nearestCity and (self.nearestLandingDistance or math.huge) <= OPEN_SKY_LAND_RADIUS
  local bottom = self.notice
  if not bottom then
    if nearCity and not nearestCity.visited then bottom = "LOCKED - " .. cleanName(nearestCity.name) .. " (NOT VISITED)" else bottom = (ready and "A DESCEND - " or "NEAREST - ") .. nearestName end
  end
  if Chrome and type(Chrome.print) == "function" then
    Chrome.print(regionLabel, 1, 0)
    Chrome.print(string.format("ALT %d SPD %d", math.floor(self.virtualAltitude + 0.5), math.floor((self.speed or 0) + 0.5)), 10, 0)
    Chrome.print(bottom, 1, 16)
  else
    G.print(regionLabel, 4, 4)
    G.print(string.format("ALT %d SPD %d", math.floor(self.virtualAltitude + 0.5), math.floor((self.speed or 0) + 0.5)), 88, 4)
    G.print(bottom, 4, 128)
  end
  self:drawCalibrationHud(G, 160, 144, 1)
  G.pop()
end

local pushedState = nil
local function ensureOpenSkyState()
  if not isGen2() then return end
  local active = type(openSkyApi.active) == "function" and openSkyApi.active()
  local world = liveWorld()
  local game = world and world.game or nil
  if not active then pushedState = nil return end
  if not (game and game.stack and world and flight.active) then return end
  local top = game.stack:top()
  if pushedState and top == pushedState then return end
  if top ~= nil then return end
  pushedState = OpenSkyState.new(game, world)
  game.stack:push(pushedState)
  notifyHud("OPEN SKY", 1.2)
end

local previousOpenSkyPlayableUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousOpenSkyPlayableUpdate(self, dt, ...)
  ensureOpenSkyState()
  return result
end

mod.exports.openSkyPlayable = {
  api = 1,
  active = function() return pushedState ~= nil and pushedState.game and pushedState.game.stack and pushedState.game.stack:top() == pushedState end,
  state = function() return pushedState end,
  landingRadius = function() return OPEN_SKY_LAND_RADIUS end,
  reentryAltitude = function() return OPEN_SKY_REENTRY_ALTITUDE end,
  visitedPoints = function(region) local world = liveWorld(); local game = world and world.game; return game and visitedPoints(game, region or "johto") or {} end,
  landingIndicators = function(region) local world = liveWorld(); local game = world and world.game; return game and landingIndicators(game, region or "johto") or {} end,
  isLandingSettlement = isLandingSettlement,
  calibratedAnchor = function(region, id) return atlasAnchor(id, region) end,
  calibrationFile = CALIBRATION_FILE,
  calibrationSaveDirectory = function() return nil end,
  calibrationReload = function() return calibrationLoad(true) end,
  calibrationSave = calibrationSave,
  calibrationExportText = calibrationExportText,
  calibrationPoints = function() calibrationLoad(); return calibration.points end,
}

log("Gen2 Open Sky playable layer loaded (collision-free screen-space glide speed=%d boost=%d landingRadius=%d reentry=%d)", OPEN_SKY_MOVE_SPEED, OPEN_SKY_BOOST_SPEED, OPEN_SKY_LAND_RADIUS, OPEN_SKY_REENTRY_ALTITUDE)
end)();
