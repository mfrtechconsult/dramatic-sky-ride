    ow:setMap(flight.originMap, flight.originX, flight.originY,
              ow.player.facing or "down")
    transitionGuard = guarded
    x, y = flight.originX, flight.originY
  end
  if not x then return false end
  local p = ow.player
  p.cellX, p.cellY = x, y
  p.px, p.py = x * 16, y * 16
  clearFlight(ow, true)
  return true
end

local function startFlight(game, mon)
  local ow = game and game.overworld
  if not (ow and ow.player and ow.map) then return false end
  if game.stack and game.stack:top() ~= ow then return false end
  if ow.transitioning or (ow.runner and ow.runner.isRunning and ow.runner:isRunning()) then
    say(game, "Finish the current\nevent first.")
    return false
  end
  if not isSupportedVoxelMode() then
    unsupportedVoxelMessage(game)
    return false
  end
  if not isOutdoor(ow) then
    say(game, "You can only take\noff outdoors.")
    return false
  end
  if game.save.onBike or ow.player.surfing then
    say(game, "Dismount first.")
    return false
  end
  if not healthy(mon) then
    say(game, "It is too tired\nto fly.")
    return false
  end
  local species = mountSpecies(game, mon)
  local cfg = species and ELIGIBLE[species]
  if not cfg then return false end

  local sprite, reason = buildMountSprite(species)
  if not sprite then
    mod.log:error("unable to build %s mount sprite: %s",
                  tostring(species or mon.species), tostring(reason))
    say(game, "PokePC follower\nsprites are missing.")
    return false
  end

  pendingFollowerRestore = nil
  flight.active = true
  flight.phase = "takeoff"
  flight.altitude = terrainGroundHeight(ow.map, ow.player.cellX, ow.player.cellY)
  flight.requestedAltitude = CRUISE_HEIGHT
  flight.safetyAltitude = safetyMinimum(ow)
  flight.targetAltitude = effectiveAltitudeTarget(ow)
  flight.verticalInput = 0
  flight.hudTimer = ALTITUDE_HUD_SECONDS
  flight.notice = nil
  flight.noticeTimer = 0
  flight.species = species
  flight.mon = mon
  flight.sprite = sprite
  local riderSprite, riderReason = buildRiderSprite(ow.player)
  if not riderSprite then
    mod.log:warn("unable to build rider sprite: %s", tostring(riderReason))
  end
  flight.riderSprite = riderSprite
  flight.riderEntity = nil
  flight.groundFxSprite = nil
  flight.groundFxEntity = nil
  flight.anim = 0
  flight.boost = 0
  flight.boostWasHeld = false
  flight.autoSafetyWasActive = false
  flight.cameraManualTimer = 0
  flight.originMap = ow.map.id
  flight.originX, flight.originY = ow.player.cellX, ow.player.cellY
  flight.suspended = suspendFollowers(ow)
  installDramaticHooks()
  ensureRiderEntity(ow)
  ensureGroundFxEntity(ow)
  ow.player.bumpFrames = 2
  feedback("takeoff")
  log("takeoff on %s at %s (%d,%d)", species, ow.map.id,
      ow.player.cellX, ow.player.cellY)
  return true
end

-- Reuse Dramatic Shape's existing lift contract: VoxelScene computes lift as
-- entity.py - poseY. Returning poseY above the logical ground lifts the card
-- in every voxel camera and also carries the 3RD camera, without editing the
-- Dramatic Shape mod.
local playerPose = Player.pose
function Player:pose()
  local sprite, px, py, facing, phase, flip, hopping = playerPose(self)
  local ow = Game.overworld
  if flight.active and ow and ow.player == self then
    flight.anim = (flight.anim + 1) % 32
    local wingPhase = flight.anim >= 16 and 1 or 0
    local ground = terrainGroundHeight(ow.map, self.cellX, self.cellY)
    -- VoxelScene adds local ground height after deriving lift from poseY.
    -- Subtract that same ground component here so the final world Y stays
    -- fixed. Only explicit tall-building targets alter flight.altitude.
    local lift = math.max(0, flight.altitude - ground)
    local visual = flight.sprite or sprite
    return visual, self.px,
           self.py - lift,
           facing, wingPhase, flip, false
  end
  return sprite, px, py, facing, phase, flip, hopping
end

-- Suppress the ground consequences of cells crossed in the air: encounters,
-- warps underfoot, spinner tiles, poison steps and scripted step triggers.
local onStepComplete = OverworldState.onStepComplete
function OverworldState:onStepComplete(...)
  if flight.active and Game.overworld == self then
    self.standingOnWarp = false
    return
  end
  return onStepComplete(self, ...)
end

local checkTrainerSight = OverworldState.checkTrainerSight
function OverworldState:checkTrainerSight(...)
  if flight.active and Game.overworld == self then return end
  return checkTrainerSight(self, ...)
end

-- Dramatic Shape's FreeMove remains responsible for camera-relative analog
-- movement in 1ST and 3RD. The orbit cameras use Gen1Recomp's ordinary movement. In
-- both cases, for the duration of one input tick only, collision questions
-- answer as open air. Every original function/table is restored before
-- returning, including when the tick raises an error.
local function runAsOpenAir(state, fn)
  local map = state.map
  local rawWalk = rawget(map, "isWalkableCell")
  local hadRawWalk = rawWalk ~= nil
  local oldOccupied = Collision.occupied
  local oldDefPassable = Map.defPassable
  local field = Game.data and Game.data.field
  local oldPairs = field and field.tilePairs

