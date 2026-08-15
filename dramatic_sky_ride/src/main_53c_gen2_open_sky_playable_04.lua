  flight.originMap = spawn.map
  flight.originX, flight.originY = spawn.x, spawn.y
  flight.originSurf = false
  flight.originSurfMon = nil

  if type(openSkyApi.leave) == "function" then openSkyApi.leave("regional_descent") end
  if self.game and self.game.stack and self.game.stack:top() == self then self.game.stack:pop() end
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

  if not (isGen2() and flight.active and type(openSkyApi.active) == "function" and openSkyApi.active()) then
    self:returnToLocal("state_invalid")
    return
  end

  local vertical = type(altitudeInputDirection) == "function" and altitudeInputDirection() or 0
  if vertical ~= 0 then
    local rate = type(verticalRate) == "function" and verticalRate() or 48
    self.virtualAltitude = clampSky(self.virtualAltitude + vertical * rate * dt, OPEN_SKY_EXIT_ALTITUDE, MAX_MANUAL_HEIGHT)
    if vertical < 0 and self.virtualAltitude <= OPEN_SKY_EXIT_ALTITUDE + 0.01 then
      self:returnToLocal("descended")
      return
    end
  end

  local input = self.game and self.game.input
  if not input then return end

  if calibrationKeyPressed(self, "f8") then
    self.calibrationMode = not self.calibrationMode
    self.speed, self.targetSpeed = 0, 0
    self.screenVelocityX, self.screenVelocityY = 0, 0
    self.bank, self.pitch, self.steering = 0, 0, 0
    if self.calibrationMode then
      calibrationLoad()
      self.calibrationIndex = tonumber(self.calibrationIndex) or 1
      calibrationFocusSelection(self)
    end
    self:setNotice(self.calibrationMode and "CITY EDITOR ON" or "CITY EDITOR OFF", 1.5)
  end

  if self.calibrationMode then
    if calibrationKeyPressed(self, "f6") then calibrationSelectDelta(self, -1, true) end
    if calibrationKeyPressed(self, "f7") then calibrationSelectDelta(self, 1, true) end
    if calibrationKeyPressed(self, "f5") then calibrationCycleRegion(self) end
    if calibrationKeyPressed(self, "f9") then calibrationSetCurrent(self) end
    if calibrationKeyPressed(self, "f10") then calibrationDeleteCurrent(self) end
    if calibrationKeyPressed(self, "f11") then calibrationExport(self) end
    if calibrationKeyPressed(self, "f4") then
      calibrationLoad(true)
      calibrationFocusSelection(self)
      self:setNotice("SESSION VALIDATIONS CLEARED", 1.5)
    end

    local fine = calibrationKeyDown("lshift") or calibrationKeyDown("rshift")
    local ultraFine = calibrationKeyDown("lctrl") or calibrationKeyDown("rctrl")
    local rate = ultraFine and 1.5 or (fine and 4.0 or 20.0)
    local dx = (calibrationKeyDown("right") and 1 or 0) - (calibrationKeyDown("left") and 1 or 0)
    local dy = (calibrationKeyDown("down") and 1 or 0) - (calibrationKeyDown("up") and 1 or 0)
    if dx ~= 0 or dy ~= 0 then
      self.x = clampSky(self.x + dx * rate * dt, MAP_MIN_X, MAP_MAX_X)
      self.y = clampSky(self.y + dy * rate * dt, MAP_MIN_Y, MAP_MAX_Y)
      if type(projectOpenSkyPoint) == "function" then self.screenX, self.screenY = projectOpenSkyPoint(self.region, self.x, self.y) end
      self:refreshNearest()
    end
    self.speed, self.targetSpeed = 0, 0
    self.screenVelocityX, self.screenVelocityY = 0, 0
    self.boost, self.dash, self.brake = 0, 0, 0
    self.bank, self.pitch, self.steering = 0, 0, 0
    self.facing = facingFromHeading(self.heading)
    calibrationSelection(self)
    return
  end

  local inputX = (input:isDown("right") and 1 or 0) - (input:isDown("left") and 1 or 0)
  local inputY = (input:isDown("down") and 1 or 0) - (input:isDown("up") and 1 or 0)
  local inputMagnitude = math.sqrt(inputX * inputX + inputY * inputY)
  local inputMoving = inputMagnitude > 0
  if inputMoving then inputX, inputY = inputX / inputMagnitude, inputY / inputMagnitude end

  local boosting = inputMoving and input:isDown("b")
  local desiredSpeed = boosting and OPEN_SKY_BOOST_SPEED or OPEN_SKY_MOVE_SPEED
  if not inputMoving then desiredSpeed = 0 end
  self.targetSpeed = desiredSpeed

  local desiredVX = inputMoving and inputX * desiredSpeed or 0
  local desiredVY = inputMoving and inputY * desiredSpeed or 0
  local response = inputMoving and OPEN_SKY_MOVE_RESPONSE or OPEN_SKY_COAST_RESPONSE
  self.screenVelocityX = smoothSky(self.screenVelocityX, desiredVX, response, dt)
  self.screenVelocityY = smoothSky(self.screenVelocityY, desiredVY, response, dt)

  local screenSpeed = math.sqrt(self.screenVelocityX * self.screenVelocityX + self.screenVelocityY * self.screenVelocityY)
  if screenSpeed < 0.025 and not inputMoving then self.screenVelocityX, self.screenVelocityY, screenSpeed = 0, 0, 0 end
  self.speed = screenSpeed
  self.boost = smoothSky(self.boost, boosting and 1 or 0, 8.0, dt)
  self.dash = self.boost
  self.brake = inputMoving and 0 or clampSky(screenSpeed / OPEN_SKY_BOOST_SPEED, 0, 1)

  if screenSpeed > 0.001 then
    local dirX = self.screenVelocityX / screenSpeed
    local dirY = self.screenVelocityY / screenSpeed
    local targetHeading = wrapAngleSky(headingFromVector(dirX, dirY))
    local previousHeading = self.heading
    self.heading = smoothAngleSky(self.heading, targetHeading, OPEN_SKY_HEADING_RESPONSE, dt)
    self.facing = facingFromHeading(self.heading)
    local turn = wrapAngleSky(targetHeading - previousHeading)
    self.steering = clampSky(turn * 1.8, -1, 1)
    self.bank = smoothSky(self.bank, clampSky(turn * 26, -18, 18), 8.0, dt)
  else
    self.steering = smoothSky(self.steering, 0, 8.0, dt)
    self.bank = smoothSky(self.bank, 0, 8.0, dt)
  end
  self.pitch = smoothSky(self.pitch, vertical * 4.0, 10.0, dt)

  local nx = (tonumber(self.screenX) or NAV_W * 0.5) + self.screenVelocityX * dt
  local ny = (tonumber(self.screenY) or NAV_H * 0.5) + self.screenVelocityY * dt

  if self.region == "johto" and nx > NAV_MAX_X then
    if self:kantoUnlocked() then
      local overflow = nx - NAV_MAX_X
      self:setRegion("kanto", MAP_MIN_X, NAV_MIN_X + overflow)
      nx = self.screenX
    else
      nx = NAV_MAX_X
      if self.screenVelocityX > 0 then self.screenVelocityX = 0 end
      self:setNotice("KANTO IS NOT UNLOCKED YET")
    end
  elseif self.region == "kanto" and nx < NAV_MIN_X then
    local overflow = NAV_MIN_X - nx
    self:setRegion("johto", MAP_MAX_X, NAV_MAX_X - overflow)
    nx = self.screenX
  end

  if ny < NAV_MIN_Y then
    ny = NAV_MIN_Y
    if self.screenVelocityY < 0 then self.screenVelocityY = 0 end
  elseif ny > NAV_MAX_Y then
    ny = NAV_MAX_Y
    if self.screenVelocityY > 0 then self.screenVelocityY = 0 end
  end

  self.screenX = clampSky(nx, NAV_MIN_X, NAV_MAX_X)
  self.screenY = clampSky(ny, NAV_MIN_Y, NAV_MAX_Y)
  syncNativeCursorFromScreen(self)
  if screenSpeed > 0.001 then self.distanceTravelled = (tonumber(self.distanceTravelled) or 0) + screenSpeed * dt end
  self:updateRegionPreview()
  self:refreshNearest()

  if input:wasPressed("a") then self:descendAt(self.nearest) return end
end

function OpenSkyState:mapGear()
  if self.gear and self.gearRegion == self.region then return self.gear end
  local Pokegear = pokegearModule()
  if not (Pokegear and type(Pokegear.new) == "function") then return nil end
  local landmark = self.nearest and self.nearest.row and self.nearest.row.landmark
