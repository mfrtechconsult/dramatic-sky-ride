  map.isWalkableCell = function() return true end
  Collision.occupied = function(entities, x, y, except)
    return storyOccupied(entities, x, y, except)
  end
  Map.defPassable = function() return true end
  if field then field.tilePairs = { land = {}, water = {} } end

  local ok, result = pcall(fn)

  if hadRawWalk then map.isWalkableCell = rawWalk
  else rawset(map, "isWalkableCell", nil) end
  Collision.occupied = oldOccupied
  Map.defPassable = oldDefPassable
  if field then field.tilePairs = oldPairs end

  if not ok then error(result, 0) end
  return result
end

local function updateBoost(dt)
  local input = Game.input
  local held = flight.active and flight.phase == "cruise"
    and flightBoostEnabled() and input and input:isDown("b")
  local target = held and 1 or 0
  local rate = held and BOOST_RAMP_UP or BOOST_RAMP_DOWN
  local step = rate * (tonumber(dt) or (1 / 60))
  if flight.boost < target then
    flight.boost = math.min(target, flight.boost + step)
  elseif flight.boost > target then
    flight.boost = math.max(target, flight.boost - step)
  end
  if held and not flight.boostWasHeld then feedback("boost") end
  flight.boostWasHeld = held
end

local handleInput = OverworldState.handleInput
function OverworldState:handleInput(...)
  local args = { ... }
  if not (flight.active and Game.overworld == self) then
    return handleInput(self, unpackArgs(args))
  end

  local input = Game.input
  if flight.phase == "takeoff" or flight.phase == "landing" then return end
  if input and input:wasPressed("a") then
    beginLanding(Game, false)
    return
  end

  return runAsOpenAir(self, function()
    return handleInput(self, unpackArgs(args))
  end)
end

local update = OverworldState.update
function OverworldState:update(dt, ...)
  if flight.active and Game.overworld == self then
    if not isSupportedVoxelMode() then
      -- Switching among every voxel camera, including 1ST and 3RD, is allowed.
      -- Only VOXEL OFF has no 3D height representation and forces a safe land.
      if not forceImmediateLand(Game) then clearFlight(self) end
    end

    local frameDt = tonumber(dt) or (1 / 60)
    updateBoost(frameDt)
    flight.hudTimer = math.max(0, (flight.hudTimer or 0) - frameDt)
    flight.noticeTimer = math.max(0, (flight.noticeTimer or 0) - frameDt)
    if flight.noticeTimer <= 0 then flight.notice = nil end

    if flight.phase == "takeoff" then
      flight.targetAltitude = effectiveAltitudeTarget(self)
      flight.altitude = approachDt(flight.altitude, flight.targetAltitude,
        TAKEOFF_RATE, OBSTACLE_DESCEND_RATE, frameDt)
      if flight.altitude >= flight.targetAltitude then flight.phase = "cruise" end
    elseif flight.phase == "cruise" then
      updateRequestedAltitude(frameDt)
      -- The requested altitude is the player's choice. The effective target
      -- may temporarily be higher when a low flight crosses a cliff/roof or
      -- one of the authored landmark-building safety zones.
      flight.targetAltitude = effectiveAltitudeTarget(self)
      local autoRaised = flight.safetyAltitude
        > (flight.requestedAltitude or CRUISE_HEIGHT) + 0.01
      if autoRaised and not flight.autoSafetyWasActive then feedback("safety") end
      flight.autoSafetyWasActive = autoRaised
      local upRate = autoRaised and OBSTACLE_CLIMB_RATE or MANUAL_FOLLOW_RATE
      local downRate = (flight.verticalInput or 0) < 0
        and MANUAL_FOLLOW_RATE or OBSTACLE_DESCEND_RATE
      flight.altitude = approachDt(flight.altitude, flight.targetAltitude,
        upRate, downRate, frameDt)
    elseif flight.phase == "landing" then
      local lx = flight.landingX or self.player.cellX
      local ly = flight.landingY or self.player.cellY
      local landingGround = terrainGroundHeight(self.map, lx, ly)
      flight.altitude = math.max(landingGround,
        flight.altitude - LANDING_RATE * frameDt)
      if flight.altitude <= landingGround then
        -- A moving NPC may have occupied the cell during the descent. Abort
        -- cleanly rather than placing the player inside it.
        if not landingCellValid(self, lx, ly) then
          flight.phase = "cruise"
          flight.landingX, flight.landingY = nil, nil
          notifyHud("CAN'T LAND HERE")
          revealAltitude()
        else
          local p = self.player
          p.cellX, p.cellY = lx, ly
          p.px, p.py = p.cellX * 16, p.cellY * 16
          log("landed at %s (%d,%d)", self.map.id, p.cellX, p.cellY)
          clearFlight(self, true)
        end
      end
    end
  end

  local result = update(self, dt, ...)
  -- Companion mods may respawn their entities during a seamless map change
  -- or their own update hook. Purging after the normal world update ensures
  -- none of those ground followers reaches the render pass while airborne.
  if flight.active and Game.overworld == self then
    purgeFollowersDuringFlight(self)
    if showRiderEnabled() then
      ensureRiderEntity(self)
    else
      removeRiderEntity(self)
    end
    ensureGroundFxEntity(self)
  elseif pendingFollowerRestore and Game.overworld == self then
    pendingFollowerRestore.frames = pendingFollowerRestore.frames - 1
