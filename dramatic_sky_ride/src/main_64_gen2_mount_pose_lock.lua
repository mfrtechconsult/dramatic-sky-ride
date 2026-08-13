;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites final mounted-pose lock.
--
-- Randy's VoxelScene computes one ground height per captured entity.  Even if
-- that ground sampling changes around roofs/buildings, DSR must never derive
-- the rider and the mount from two independent vertical references.  This
-- layer runs after the provider's own Stadium preparation and locks the human
-- rider to the ACTUAL DSR mount proxy pose captured in the same frame.
--
-- In 2D HGSS/PokeMMO mode the same captured proxy is also the safest place to
-- apply the small flight-card seat correction: only the flying mount card is
-- raised, while Ground Ride and Surf keep their foot-on-ground anchors.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local state = {
  installs = 0,
  lockedFrames = 0,
  pokemmoFlightFrames = 0,
  lastMountBase = nil,
  lastRiderTarget = nil,
  lastFlightCardLift = nil,
}

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function provider()
  if type(mod.find) ~= "function" then return nil, nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then return nil, nil end
  return handle, handle.exports
end

local function stadium3D()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    if ok then return value == true end
  end
  return false
end

local function activeFlightSpecies()
  if flight and flight.active == true then
    return flight.species or (flight.mon and flight.mon.species)
  end
  return nil
end

local function riderSeat(species)
  local cfg = type(RIDER_OFFSETS) == "table" and RIDER_OFFSETS[species] or nil
  local lift = cfg and tonumber(cfg.lift) or nil
  if lift and lift > 0 then return lift end
  return 7.0
end

local function mountProxyPose(p)
  local e = p and p.entity or nil
  return type(e) == "table" and (
    e.dramaticSkyRideVoxelProxy == true
    or e.id == "DSR_GEN2_VOXEL_MOUNT"
    or e.name == "DSR_GEN2_VOXEL_MOUNT")
end

local function nativePokeMMOPose(p)
  local def = p and p.sprite and p.sprite.def or nil
  return type(def) == "table" and def.dramaticSkyRideNativePokeMMO == true
end

local function flightCardLift(species)
  -- The HGSS/PokeMMO card is foot-anchored.  A small upward correction puts
  -- the bird's upper body under the trainer instead of leaving the trainer
  -- visually floating above it.  Keep the correction intentionally bounded so
  -- large sprites (Ho-Oh/Lugia) do not jump by a size-proportional amount.
  local seat = riderSeat(species)
  return math.max(2.5, math.min(4.0, seat * 0.45))
end

local function lockCapturedPoses(posed)
  if not (isGold() and flight and flight.active == true) then return end

  local mountPose, playerPose
  for _, p in ipairs(posed or {}) do
    if mountProxyPose(p) then
      mountPose = p
    elseif p and p.isPlayer == true then
      playerPose = p
    end
  end
  if not mountPose then return end

  -- p.gh + p.lift is the exact world-space foot/base height VoxelScene will
  -- draw for this proxy on THIS frame.  Using it directly avoids every future
  -- disagreement between DSR terrain helpers and Randy's groundAt().
  local mountBase = (tonumber(mountPose.gh) or 0) + (tonumber(mountPose.lift) or 0)
  local species = activeFlightSpecies()
  state.lastMountBase = mountBase

  if stadium3D() then
    if playerPose then
      local target = mountBase + riderSeat(species)
      playerPose.lift = target - (tonumber(playerPose.gh) or 0)
      playerPose.dramaticSkyRideMountLockedY = target
      state.lastRiderTarget = target
      state.lockedFrames = state.lockedFrames + 1
    end
    return
  end

  -- Only the native high-resolution HGSS/PokeMMO flight card gets this visual
  -- correction. Ground Ride and Surf intentionally remain anchored to y=0.
  if nativePokeMMOPose(mountPose) then
    local lift = flightCardLift(species)
    mountPose.lift = (tonumber(mountPose.lift) or 0) + lift
    mountPose.dramaticSkyRideFlightCardLift = lift
    state.lastFlightCardLift = lift
    state.pokemmoFlightFrames = state.pokemmoFlightFrames + 1
  end
end

local function install()
  if not isGold() then return false end
  local _, ex = provider()
  local stadium = ex and ex.overworld or nil
  if not (type(stadium) == "table" and type(stadium.prepare) == "function") then
    return false
  end

  local marker = stadium._dramaticSkyRideMountPoseLock
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.wrapper then
    return true
  end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    local result = raw(posed, ...)
    lockCapturedPoses(posed)
    return result
  end
  stadium.prepare = wrapper
  stadium._dramaticSkyRideMountPoseLock = {
    owner = mod.id,
    raw = raw,
    wrapper = wrapper,
  }
  state.installs = state.installs + 1
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() and Game.overworld == self then install() end
  return result
end

mod.events:on("game.ready", install)
mod.events:on("mods.loaded", install)
mod.events:on("mod.options_changed", install)

mod.exports.gen2MountPoseLock = {
  api = 1,
  status = function()
    return {
      installs = state.installs,
      lockedFrames = state.lockedFrames,
      pokemmoFlightFrames = state.pokemmoFlightFrames,
      mountBase = state.lastMountBase,
      riderTarget = state.lastRiderTarget,
      flightCardLift = state.lastFlightCardLift,
    }
  end,
}

install()
log("Gen2 captured mount/rider pose lock loaded")
end)();
