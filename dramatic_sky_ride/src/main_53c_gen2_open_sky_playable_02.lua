    facing = "right",
    heading = 0,
    speed = 0,
    targetSpeed = 0,
    bank = 0,
    pitch = 0,
    boost = 0,
    dash = 0,
    brake = 0,
    steering = 0,
    distanceTravelled = 0,
    anim = 0,
    virtualAltitude = tonumber(status.enteredAtAltitude)
      or tonumber(flight.altitude) or 88,
    notice = nil,
    noticeTimer = 0,
    nearest = nil,
    nearestDistance = math.huge,
    gear = nil,
    gearRegion = nil,
  }, OpenSkyState)
  self:refreshNearest()
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
  self.nearest, self.nearestDistance = nearestVisited(
    self.game, self.region, self.x, self.y)
end

function OpenSkyState:setRegion(region, x)
  if region == self.region then return end
  self.region = region
  self.x = clampSky(x or self.x, MAP_MIN_X, MAP_MAX_X)
  self.gear = nil
  self.gearRegion = nil
  self:refreshNearest()
  self:setNotice(region == "kanto" and "KANTO AIRSPACE" or "JOHTO AIRSPACE", 1.5)
end

function OpenSkyState:returnToLocal(reason)
  flight.altitude = clampSky(tonumber(self.virtualAltitude) or OPEN_SKY_REENTRY_ALTITUDE,
    MIN_MANUAL_HEIGHT, OPEN_SKY_REENTRY_ALTITUDE)
  flight.requestedAltitude = flight.altitude
  flight.targetAltitude = flight.altitude
  if type(openSkyApi.leave) == "function" then openSkyApi.leave(reason or "return") end
  if self.game and self.game.stack and self.game.stack:top() == self then
    self.game.stack:pop()
  end
end

function OpenSkyState:descendAt(point)
  point = point or self.nearest
  if not (point and point.row and point.row.spawn) then
    self:setNotice("NO VISITED LANDING POINT")
    return false
  end
  if (self.nearestDistance or math.huge) > OPEN_SKY_LAND_RADIUS then
    self:setNotice("FLY CLOSER TO A VISITED TOWN")
    return false
  end

  local world = self.world or liveWorld()
  local spawns = world and world.landmarks and world.landmarks.spawns
  local spawn = spawns and spawns[point.row.spawn] or nil
  if not (world and spawn and spawn.map and spawn.x and spawn.y
      and world.maps and world.maps[spawn.map]) then
    self:setNotice("LANDING DATA UNAVAILABLE")
    return false
  end

  -- Do not call World:flyTo(): it deliberately ends in PLAYER_NORMAL and owns
  -- the vanilla Fly animation. Open Sky wants the opposite contract: change
  -- the authoritative local map, then hand control back to DSR still airborne.
  local ok, loaded = pcall(world.setMap, world,
    spawn.map, spawn.x, spawn.y, self.facing or "down")
  if not ok or loaded == false then
    self:setNotice("COULD NOT REENTER THIS AREA")
    return false
  end

  flight.active = true
  flight.phase = "cruise"
  flight.altitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.requestedAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.targetAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.safetyAltitude = 0
  flight.verticalInput = 0
  flight.landingX, flight.landingY, flight.landingKind = nil, nil, nil
  -- Emergency landing must now regard the new local map as the safe origin;
  -- otherwise a battle/save transition after regional travel could snap the
  -- player all the way back to the map where Open Sky was first entered.
  flight.originMap = spawn.map
  flight.originX, flight.originY = spawn.x, spawn.y
  flight.originSurf = false
  flight.originSurfMon = nil

  if type(openSkyApi.leave) == "function" then
    openSkyApi.leave("regional_descent")
  end
  if self.game and self.game.stack and self.game.stack:top() == self then
    self.game.stack:pop()
  end
  notifyHud("DESCENDING: " .. cleanName(point.row.name), 2.0)
  return true
end

function OpenSkyState:update(dt)
  dt = clampSky(tonumber(dt) or (1 / 60), 0, 0.10)
  self.anim = (self.anim + dt * (24 + (tonumber(self.speed) or 0) * 0.18)) % 32
  if self.noticeTimer > 0 then
    self.noticeTimer = math.max(0, self.noticeTimer - dt)
    if self.noticeTimer == 0 then self.notice = nil end
  end

  if not (isGen2() and flight.active and type(openSkyApi.active) == "function"
      and openSkyApi.active()) then
    self:returnToLocal("state_invalid")
    return
  end

  -- Keep the existing DSR triggers/PageUp/PageDown as the pitch/altitude seam.
  -- main_53e consumes the trigger that carried us through altitude 88, so the
  -- first regional frame cannot accidentally climb again.
  local vertical = type(altitudeInputDirection) == "function"
    and altitudeInputDirection() or 0
  if vertical ~= 0 then
    local rate = type(verticalRate) == "function" and verticalRate() or 48
    self.virtualAltitude = clampSky(self.virtualAltitude + vertical * rate * dt,
      OPEN_SKY_EXIT_ALTITUDE, MAX_MANUAL_HEIGHT)
    if vertical < 0 and self.virtualAltitude <= OPEN_SKY_EXIT_ALTITUDE + 0.01 then
      self:returnToLocal("descended")
      return
    end
  end

  local input = self.game and self.game.input
  if not input then return end

  -- Omega Ruby / Alpha Sapphire-inspired controls:
  --   Left/Right : steer + bank
  --   Up         : faster cruise
  --   Down       : brake
  --   Hold B     : speed boost; Up+B is the fast dash
  --   R2/L2 or PageUp/PageDown : climb/descend
  --   A over a visited Fly Point: descend there
  local steer = (input:isDown("right") and 1 or 0)
