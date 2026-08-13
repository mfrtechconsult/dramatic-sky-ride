;(function()
-- -------------------------------------------------------------------------
-- Gen2 voxel Flight height lock.
--
-- Gen2-3D-Sprites 0.2.22+ can report a raised pose.gh for roofs/buildings.
-- DSR's older bridge clamps Flight lift at zero, so once provider ground rises
-- above the requested Flight altitude the rendered mount is pushed upward by
-- the roof.  The rider can then use a different ground reference and separate
-- from the mount.
--
-- Fix the problem at Randy's canonical captured-pose seam.  Both the mount
-- proxy and the player are assigned one absolute Flight base for the frame:
--   final world Y = pose.gh + pose.lift
-- therefore pose.lift is allowed to become negative over raised geometry.
-- Stadium metadata is updated to the same base before Randy builds the model.
--
-- In DSR 2D-mount mode, hide only the automatic tall-building safety climb,
-- matching main_39's native-flat presentation rule.  Gameplay still keeps the
-- authoritative logical altitude; only the voxel billboard presentation uses
-- the requested height while that building-only safety override is active.
--
-- IMPORTANT: exactly one prepare wrapper, installed only from lifecycle events.
-- No OverworldState.update hook and no per-frame re-installation.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local EPSILON = 0.01

local state = {
  installs = 0,
  lockedFrames = 0,
  mountFrames = 0,
  riderFrames = 0,
  lastMode = nil,
  lastMountGround = nil,
  lastPlayerGround = nil,
  lastTarget = nil,
  lastSeat = nil,
  lastDelta = nil,
}

local buildingVisual = {
  active = false,
  lastFloor = 0,
}

local function cleanSpecies(value)
  if type(value) == "table" then value = value.species end
  if value == nil then return nil end
  local s = tostring(value):upper():gsub("[^A-Z0-9]", "")
  return s ~= "" and s or nil
end

local function activeFlightSpecies()
  if not (flight and flight.active == true) then return nil end
  return flight.species or (flight.mon and flight.mon.species)
end

local function stadium3D()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    return ok and value == true
  end
  return false
end

local function provider()
  if type(mod.find) ~= "function" then return nil, nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then return nil, nil end
  return handle, handle.exports
end

local function mountProxyPose(p)
  local e = p and p.entity or nil
  return type(e) == "table" and (
    e.dramaticSkyRideVoxelProxy == true
    or e.id == "DSR_GEN2_VOXEL_MOUNT"
    or e.name == "DSR_GEN2_VOXEL_MOUNT")
end

local function logicalAltitude()
  return math.max(0, tonumber(flight and flight.altitude) or 0)
end

local function requestedAltitude()
  local requested = tonumber(flight and flight.requestedAltitude)
  if requested == nil then return logicalAltitude() end
  return math.max(0, requested)
end

local function resetBuildingVisual()
  buildingVisual.active = false
  buildingVisual.lastFloor = 0
end

local function dsrWorld()
  local fn = mod.exports and mod.exports._mountWorld or nil
  if type(fn) == "function" then
    local ok, ow = pcall(fn, Game)
    if ok and type(ow) == "table" then return ow end
  end
  return Game and Game.overworld or nil
end

local function currentBuildingFloor(ow)
  if type(tallBuildingMinimum) ~= "function" or not ow then return 0 end
  local ok, value = pcall(tallBuildingMinimum, ow)
  value = ok and tonumber(value) or nil
  return math.max(0, value or 0)
end

local function twoDVisualAltitude()
  local logical = logicalAltitude()
  if stadium3D() or not (flight and flight.active == true)
      or flight.phase ~= "cruise" then
    resetBuildingVisual()
    return logical
  end

  local requested = requestedAltitude()
  local safety = math.max(0, tonumber(flight.safetyAltitude) or 0)
  local building = currentBuildingFloor(dsrWorld())
  local buildingDominates = building > requested + EPSILON
    and building >= safety - EPSILON

  if buildingDominates then
    buildingVisual.active = true
    buildingVisual.lastFloor = building
  end

  if buildingVisual.active then
    if buildingDominates then
      return math.min(logical, requested)
    end
    if safety > requested + EPSILON then
      resetBuildingVisual()
      return logical
    end
    if logical > requested + EPSILON then
      return requested
    end
    resetBuildingVisual()
  end

  return logical
end

local function dsrTerrainLift()
  local ow = dsrWorld()
  local player = ow and ow.player or nil
  if not (ow and ow.map and player and type(terrainGroundHeight) == "function") then
    return nil
  end
  local ok, ground = pcall(terrainGroundHeight, ow.map, player.cellX, player.cellY)
  ground = ok and tonumber(ground) or nil
  if ground == nil then return nil end
  return math.max(0, logicalAltitude() - math.max(0, ground))
end

local function fallbackSeat(species, scaled)
  local cfg = type(RIDER_OFFSETS) == "table"
    and (RIDER_OFFSETS[species] or RIDER_OFFSETS[cleanSpecies(species)]) or nil
  local seat = cfg and tonumber(cfg.lift) or 7.0
  if scaled then
    local scaleFn = mod.exports and mod.exports.mountVisualScale or nil
    if type(scaleFn) == "function" then
      local ok, scale = pcall(scaleFn, species)
      scale = ok and tonumber(scale) or nil
      if scale and scale > 0 then seat = seat * scale end
    end
  end
  return seat
end

local function capturedSeat(playerPose, mountPose, use3D, species)
  local playerLift = tonumber(playerPose and playerPose.lift)
  if playerLift == nil then return fallbackSeat(species, not use3D) end

  if use3D then
    -- main_58 deliberately composes the Stadium rider as mount lift + saddle.
    -- Reading the captured difference preserves its exact per-species saddle
    -- instead of maintaining a second table here.
    local mountLift = tonumber(mountPose and mountPose.lift)
    if mountLift ~= nil then
      local seat = playerLift - mountLift
      if seat > 0 and seat < 64 then return seat end
    end
    return fallbackSeat(species, false)
  end

  -- The 2D rider path still originates in DSR's native riderPose(), which uses
  -- DSR terrain rather than Randy groundAt(). Remove that native terrain lift
  -- from the captured player lift; what remains is the complete visual saddle
  -- offset, including Pokedex/user mount scaling and camera micro-offsets.
  local nativeLift = dsrTerrainLift()
  if nativeLift ~= nil then
    local seat = playerLift - nativeLift
    if seat > -4 and seat < 96 then return seat end
  end
  return fallbackSeat(species, true)
end

local function lockFlightPoses(posed)
  if not (flight and flight.active == true) then
    resetBuildingVisual()
    return
  end

  local mountPose, playerPose
  for _, p in ipairs(posed or {}) do
    if mountProxyPose(p) then
      mountPose = p
    elseif p and p.isPlayer == true then
      playerPose = p
    end
  end
  if not mountPose then return end

  local use3D = stadium3D()
  local target = use3D and logicalAltitude() or twoDVisualAltitude()
  local mountGround = tonumber(mountPose.gh) or 0
  local oldMountY = mountGround + (tonumber(mountPose.lift) or 0)
  local delta = target - oldMountY

  -- The mount billboard/model must use the same absolute base irrespective of
  -- the roof height Randy captured. Negative lift is intentional here.
  mountPose.lift = target - mountGround
  mountPose.dramaticSkyRideAbsoluteMountY = target
  local entity = mountPose.entity
  if type(entity) == "table" then
    entity._stadiumSkyRideGround = mountGround
    entity._stadiumSkyRideLift = target - mountGround
    entity._stadiumSkyRideAltitude = target
  end

  local species = activeFlightSpecies()
  local seat = playerPose and capturedSeat(playerPose, mountPose, use3D, species) or nil
  if playerPose and seat then
    local playerGround = tonumber(playerPose.gh) or 0
    local riderTarget = target + seat
    playerPose.lift = riderTarget - playerGround
    playerPose.dramaticSkyRideAbsoluteRiderY = riderTarget
    state.lastPlayerGround = playerGround
    state.lastSeat = seat
    state.riderFrames = state.riderFrames + 1
  end

  state.lastMode = use3D and "stadium3d" or "2d"
  state.lastMountGround = mountGround
  state.lastTarget = target
  state.lastDelta = delta
  state.mountFrames = state.mountFrames + 1
  state.lockedFrames = state.lockedFrames + 1
end

local function install()
  local _, ex = provider()
  local stadium = ex and ex.overworld or nil
  if not (type(stadium) == "table" and type(stadium.prepare) == "function") then
    return false
  end

  local marker = stadium._dramaticSkyRideAbsoluteRiderHeight
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.wrapper then
    return true
  end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    -- Run before Randy's Stadium preparation so both its 2D billboard path and
    -- special Sky Ride model transform consume the corrected common base.
    lockFlightPoses(posed)
    return raw(posed, ...)
  end

  stadium.prepare = wrapper
  stadium._dramaticSkyRideAbsoluteRiderHeight = {
    owner = mod.id,
    raw = raw,
    wrapper = wrapper,
  }
  state.installs = state.installs + 1
  return true
end

mod.events:on("game.ready", install)
mod.events:on("mods.loaded", install)

mod.exports.gen2AbsoluteRiderHeight = {
  api = 2,
  status = function()
    return {
      installs = state.installs,
      lockedFrames = state.lockedFrames,
      mountFrames = state.mountFrames,
      riderFrames = state.riderFrames,
      mode = state.lastMode,
      mountGround = state.lastMountGround,
      playerGround = state.lastPlayerGround,
      target = state.lastTarget,
      seat = state.lastSeat,
      delta = state.lastDelta,
      buildingVisualActive = buildingVisual.active == true,
      buildingFloor = buildingVisual.lastFloor,
    }
  end,
}

install()
log("Gen2 voxel Flight common-height lock loaded (mount + rider, Stadium 3D + 2D)")
end)();
