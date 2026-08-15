          row.name = anchor.name or sourceRow.name or sourceRow.landmark
          out[#out + 1] = { row = row, anchor = anchor }
        end
      end
    end
    return out
  end

  if type(fieldMoves.flyPoints) ~= "function" then return {} end
  local ok, rows = pcall(fieldMoves.flyPoints, game.save, landmarks, region)
  if not ok or type(rows) ~= "table" then return {} end
  local out = {}
  for _, row in ipairs(rows) do
    local anchor = atlasAnchor(row.landmark, region)
    if anchor and isLandingSettlement(anchor, region) then
      out[#out + 1] = { row = row, anchor = anchor }
    end
  end
  return out
end

local function landingIndicators(game, region)
  local atlas = nil
  if type(openSkyApi.atlas) == "function" then
    local ok, value = pcall(openSkyApi.atlas)
    if ok and type(value) == "table" then atlas = value end
  end
  if type(atlas) ~= "table" then return {} end

  local visitedById = {}
  for _, point in ipairs(visitedPoints(game, region)) do
    if point.anchor and point.anchor.id then visitedById[point.anchor.id] = point end
  end

  local out = {}
  for _, rawAnchor in ipairs(atlas[region] or {}) do
    if isLandingSettlement(rawAnchor, region) then
      local anchor = cloneAnchorWithCalibration(rawAnchor, region)
      local visited = anchor and visitedById[anchor.id] or nil
      if anchor then
        out[#out + 1] = { anchor = anchor, visited = visited ~= nil, row = visited and visited.row or nil, name = anchor.name or anchor.id }
      end
    end
  end
  return out
end

local function nearestLandingIndicator(game, region, x, y)
  local nearest, distance = nil, math.huge
  for _, point in ipairs(landingIndicators(game, region)) do
    local dx = (point.anchor.x or 0) - x
    local dy = (point.anchor.y or 0) - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < distance then nearest, distance = point, d end
  end
  return nearest, distance
end

local function nearestVisited(game, region, x, y)
  local nearest, distance = nil, math.huge
  for _, point in ipairs(visitedPoints(game, region)) do
    local dx = (point.anchor.x or 0) - x
    local dy = (point.anchor.y or 0) - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < distance then nearest, distance = point, d end
  end
  return nearest, distance
end

local function nearestLandingIndicatorScreen(game, region, sx, sy)
  local nearest, distance = nil, math.huge
  for _, point in ipairs(landingIndicators(game, region)) do
    local anchor = point and point.anchor
    if anchor then
      local px, py = projectOpenSkyPoint(region, anchor.x, anchor.y)
      local dx, dy = px - sx, py - sy
      local d = math.sqrt(dx * dx + dy * dy)
      if d < distance then nearest, distance = point, d end
    end
  end
  return nearest, distance
end

local function nearestVisitedScreen(game, region, sx, sy)
  local nearest, distance = nil, math.huge
  for _, point in ipairs(visitedPoints(game, region)) do
    local anchor = point and point.anchor
    if anchor then
      local px, py = projectOpenSkyPoint(region, anchor.x, anchor.y)
      local dx, dy = px - sx, py - sy
      local d = math.sqrt(dx * dx + dy * dy)
      if d < distance then nearest, distance = point, d end
    end
  end
  return nearest, distance
end

local OpenSkyState = {}
OpenSkyState.__index = OpenSkyState
OpenSkyState.isOpaque = true

function OpenSkyState.new(game, world)
  local status = type(openSkyApi.status) == "function" and openSkyApi.status() or {}
  local anchor = status.anchor or (type(openSkyApi.currentAnchor) == "function" and openSkyApi.currentAnchor(world) or nil)
  local self = setmetatable({
    game = game,
    world = world,
    region = status.region or (anchor and anchor.region) or "johto",
    x = clampSky(tonumber(anchor and anchor.x) or 80, MAP_MIN_X, MAP_MAX_X),
    y = clampSky(tonumber(anchor and anchor.y) or 78, MAP_MIN_Y, MAP_MAX_Y),
    screenX = nil, screenY = nil,
    facing = "right", heading = 0, speed = 0, targetSpeed = 0,
    screenVelocityX = 0, screenVelocityY = 0,
    regionPreview = nil, regionPreviewSide = nil, regionPreviewProgress = 0,
    bank = 0, pitch = 0, boost = 0, dash = 0, brake = 0, steering = 0,
    distanceTravelled = 0, anim = 0,
    virtualAltitude = tonumber(status.enteredAtAltitude) or tonumber(flight.altitude) or 88,
    notice = nil, noticeTimer = 0,
    nearest = nil, nearestDistance = math.huge,
    nearestLanding = nil, nearestLandingDistance = math.huge,
    gear = nil, gearRegion = nil,
    calibrationMode = false, calibrationIndex = 1, calibrationStep = 0.0,
  }, OpenSkyState)
  self.screenX, self.screenY = projectOpenSkyPoint(self.region, self.x, self.y)
  self:refreshNearest()
  self:updateRegionPreview()
  return self
end

function OpenSkyState:kantoUnlocked()
  if type(openSkyApi.kantoUnlocked) ~= "function" then return false end
  local ok, value = pcall(openSkyApi.kantoUnlocked, self.world)
  return ok and value == true
end

function OpenSkyState:setNotice(text, seconds)
  self.notice = text
  self.noticeTimer = seconds or 1.3
end

function OpenSkyState:refreshNearest()
  local sx = clampSky(tonumber(self.screenX) or NAV_W * 0.5, NAV_MIN_X, NAV_MAX_X)
  local sy = clampSky(tonumber(self.screenY) or NAV_H * 0.5, NAV_MIN_Y, NAV_MAX_Y)
  self.nearest, self.nearestDistance = nearestVisitedScreen(self.game, self.region, sx, sy)
  self.nearestLanding, self.nearestLandingDistance = nearestLandingIndicatorScreen(self.game, self.region, sx, sy)
end

function OpenSkyState:setRegion(region, nativeX, screenX)
  if region == self.region then return end
  self.region = region
  self.x = clampSky(nativeX or self.x, MAP_MIN_X, MAP_MAX_X)
  if screenX ~= nil then
    self.screenX = clampSky(screenX, NAV_MIN_X, NAV_MAX_X)
  else
    self.screenX, self.screenY = projectOpenSkyPoint(self.region, self.x, self.y)
  end
  syncNativeCursorFromScreen(self)
  self.gear = nil
  self.gearRegion = nil
  self:refreshNearest()
  self:setNotice(region == "kanto" and "KANTO AIRSPACE" or "JOHTO AIRSPACE", 1.5)
end

function OpenSkyState:updateRegionPreview()
  local preview, side, progress = nil, nil, 0
  local sx = clampSky(tonumber(self.screenX) or NAV_W * 0.5, NAV_MIN_X, NAV_MAX_X)
  if self.region == "kanto" then
    local d = clampSky(sx - NAV_MIN_X, 0, REGION_PREVIEW_MARGIN_SCREEN)
    progress = 1 - d / REGION_PREVIEW_MARGIN_SCREEN
    if progress > 0 then preview, side = "johto", "left" end
  elseif self.region == "johto" and self:kantoUnlocked() then
    local d = clampSky(NAV_MAX_X - sx, 0, REGION_PREVIEW_MARGIN_SCREEN)
    progress = 1 - d / REGION_PREVIEW_MARGIN_SCREEN
    if progress > 0 then preview, side = "kanto", "right" end
  end
  self.regionPreview = preview
  self.regionPreviewSide = side
  self.regionPreviewProgress = clampSky(progress, 0, 1)
end

function OpenSkyState:returnToLocal(reason)
  flight.altitude = clampSky(tonumber(self.virtualAltitude) or OPEN_SKY_REENTRY_ALTITUDE, MIN_MANUAL_HEIGHT, OPEN_SKY_REENTRY_ALTITUDE)
  flight.requestedAltitude = flight.altitude
  flight.targetAltitude = flight.altitude
  if type(openSkyApi.leave) == "function" then openSkyApi.leave(reason or "return") end
  if self.game and self.game.stack and self.game.stack:top() == self then self.game.stack:pop() end
end

function OpenSkyState:descendAt(point)
  point = point or self.nearest
  if not (point and point.row and point.row.spawn) then self:setNotice("NO VISITED LANDING POINT") return false end
  if (self.nearestDistance or math.huge) > OPEN_SKY_LAND_RADIUS then self:setNotice("FLY CLOSER TO A VISITED TOWN") return false end
  local world = self.world or liveWorld()
  local spawns = world and world.landmarks and world.landmarks.spawns
  local spawn = spawns and spawns[point.row.spawn] or nil
  if not (world and spawn and spawn.map and spawn.x and spawn.y and world.maps and world.maps[spawn.map]) then self:setNotice("LANDING DATA UNAVAILABLE") return false end
  local ok, loaded = pcall(world.setMap, world, spawn.map, spawn.x, spawn.y, self.facing or "down")
  if not ok or loaded == false then self:setNotice("COULD NOT REENTER THIS AREA") return false end
  flight.active = true
  flight.phase = "cruise"
  flight.altitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.requestedAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.targetAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.safetyAltitude = 0
  flight.verticalInput = 0
  flight.landingX, flight.landingY, flight.landingKind = nil, nil, nil
