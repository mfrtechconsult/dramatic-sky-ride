    - (input:isDown("left") and 1 or 0)
  local throttle = input:isDown("up")
  local braking = input:isDown("down")
  local boosting = input:isDown("b") and throttle
  local dash = boosting

  local targetSpeed = 0
  if throttle then targetSpeed = OPEN_SKY_FAST_SPEED end
  if boosting then targetSpeed = OPEN_SKY_BOOST_SPEED end

  self.targetSpeed = targetSpeed
  local speedRate = OPEN_SKY_IDLE_DRAG
  if braking then speedRate = OPEN_SKY_BRAKE
  elseif targetSpeed > (tonumber(self.speed) or 0) then speedRate = OPEN_SKY_ACCEL end
  self.speed = approachSky(self.speed, targetSpeed, speedRate, dt)
  self.boost = smoothSky(self.boost, boosting and 1 or 0, 7.5, dt)
  self.dash = smoothSky(self.dash, dash and 1 or 0, 9.0, dt)
  self.brake = smoothSky(self.brake, braking and 1 or 0, 10.0, dt)
  self.steering = smoothSky(self.steering, steer, 10.0, dt)

  -- More speed gives a stable wide arc instead of making the mount twitchy.
  local speedRatio = clampSky((tonumber(self.speed) or 0) / OPEN_SKY_DASH_SPEED, 0, 1)
  local turnAuthority = 0.78 + (1 - speedRatio) * 0.34
  self.heading = wrapAngleSky((tonumber(self.heading) or 0)
    + self.steering * OPEN_SKY_TURN_RATE * turnAuthority * dt)

  self.bank = smoothSky(self.bank,
    -self.steering * OPEN_SKY_BANK_ANGLE * (0.65 + speedRatio * 0.35), 7.5, dt)
  self.pitch = smoothSky(self.pitch,
    vertical * OPEN_SKY_PITCH_ANGLE - self.brake * 5 + self.dash * 3, 6.5, dt)
  self.facing = facingFromHeading(self.heading)

  local forwardX, forwardY = math.cos(self.heading), math.sin(self.heading)
  local step = math.max(0, tonumber(self.speed) or 0) * dt
  local nx, ny = self.x + forwardX * step, self.y + forwardY * step
  local bounced = false

  -- Crossing the east Johto / west Kanto seam is real regional travel. The
  -- progression gate remains authoritative. Outer borders behave like ORAS's
  -- map edge: the mount banks into an automatic U-turn instead of sticking.
  if self.region == "johto" and nx > MAP_MAX_X then
    if self:kantoUnlocked() then
      self:setRegion("kanto", MAP_MIN_X + 2)
      nx = self.x
    else
      nx = MAP_MAX_X - 1
      self.heading = wrapAngleSky(math.pi - self.heading)
      bounced = true
      self:setNotice("KANTO IS NOT UNLOCKED YET")
    end
  elseif self.region == "kanto" and nx < MAP_MIN_X then
    self:setRegion("johto", MAP_MAX_X - 2)
    nx = self.x
  elseif nx < MAP_MIN_X or nx > MAP_MAX_X then
    nx = clampSky(nx, MAP_MIN_X + 1, MAP_MAX_X - 1)
    self.heading = wrapAngleSky(math.pi - self.heading)
    bounced = true
  end

  if ny < MAP_MIN_Y or ny > MAP_MAX_Y then
    ny = clampSky(ny, MAP_MIN_Y + 1, MAP_MAX_Y - 1)
    self.heading = wrapAngleSky(-self.heading)
    bounced = true
  end
  if bounced and not self.notice then self:setNotice("TURNING BACK", 0.8) end

  self.x = clampSky(nx, MAP_MIN_X, MAP_MAX_X)
  self.y = clampSky(ny, MAP_MIN_Y, MAP_MAX_Y)
  self.facing = facingFromHeading(self.heading)
  self.distanceTravelled = (tonumber(self.distanceTravelled) or 0) + step
  self:refreshNearest()

  if input:wasPressed("a") then
    self:descendAt(self.nearest)
    return
  end
end

function OpenSkyState:mapGear()
  if self.gear and self.gearRegion == self.region then return self.gear end
  local Pokegear = pokegearModule()
  if not (Pokegear and type(Pokegear.new) == "function") then return nil end
  local landmark = self.nearest and self.nearest.row and self.nearest.row.landmark
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
  for _, anchor in ipairs((atlas and atlas[self.region]) or {}) do
    G.circle("fill", anchor.x or 0, anchor.y or 0, 2)
  end
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
    -- Regional map coordinates are already screen pixels. A half-scale mount
    -- reads as a soaring icon while still using DSR's selected Pokemon art.
    G.scale(0.5, 0.5)
    G.setColor(1, 1, 1, 1)
    local phase = self.anim >= 16 and 1 or 0
    pcall(sprite.draw, sprite, -8, -8, 0, 0, self.facing, phase, false)
    G.pop()
  else
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", self.x, self.y - 4, self.x + 4, self.y + 4,
      self.x, self.y + 2, self.x - 4, self.y + 4)
  end

  -- The ring stays readable even when a large Stadium/Pokedex-scaled mount
  -- covers its own centre point.
  G.setColor(1, 1, 1, 0.85)
  G.circle("line", math.floor(self.x), math.floor(self.y), 6)
end

function OpenSkyState:draw()
  if not (love and love.graphics) then return end
  local G = love.graphics
  G.push("all")
  G.clear(0.58, 0.80, 0.96, 1)
  self:drawRegionalMap()

