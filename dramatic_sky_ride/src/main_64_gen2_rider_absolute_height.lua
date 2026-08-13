;(function()
-- -------------------------------------------------------------------------
-- Gen2 Stadium rider absolute-height lock.
--
-- Gen2-3D-Sprites captures the exact ground height used by the current voxel
-- frame as pose.gh.  Do not try to rediscover that ground through a DSR world
-- facade: streamed maps / raised building art can make the two contexts differ.
-- Instead cancel the provider's captured ground directly so the trainer's
-- final billboard height is always DSR's absolute Flight altitude + saddle.
--
-- IMPORTANT: this installs exactly one prepare wrapper, only from lifecycle
-- events. There is deliberately no OverworldState.update hook and no per-frame
-- re-installation, avoiding the recursive wrapper regression that caused the
-- progressive slowdown in the previous test build.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local state = {
  installs = 0,
  lockedFrames = 0,
  lastGround = nil,
  lastTarget = nil,
}

local RIDER_FOOT = {
  LUGIA = 8.0,
  HOOH = 7.5,
  GYARADOS = 7.0,
  LAPRAS = 7.0,
  MANTINE = 6.5,
  SUICUNE = 7.0,
  RAIKOU = 7.0,
  ENTEI = 7.2,
  TYRANITAR = 8.0,
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

local function riderSeat(species)
  return RIDER_FOOT[cleanSpecies(species)] or 7.0
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

local function lockPlayerPose(posed)
  if not (flight and flight.active == true and stadium3D()) then return end
  local altitude = tonumber(flight.altitude)
  if altitude == nil then return end

  local target = altitude + riderSeat(activeFlightSpecies())
  for _, p in ipairs(posed or {}) do
    -- `isPlayer` is the canonical identity exported by Randy's captured voxel
    -- pose. Do not compare entity objects with DSR's compatibility world: on
    -- modern Gold those can be different facade/live instances during a frame.
    if p and p.isPlayer == true then
      local ground = tonumber(p.gh) or 0
      p.lift = target - ground
      p.dramaticSkyRideAbsoluteRiderY = target
      state.lastGround = ground
      state.lastTarget = target
      state.lockedFrames = state.lockedFrames + 1
      return
    end
  end
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

  -- If this exact layer survived a hot reload, unwrap only our own stale
  -- wrapper before re-installing. Never peel another mod/provider's wrapper.
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.wrapper and type(marker.raw) == "function" then
    stadium.prepare = marker.raw
  end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    -- Correct BEFORE Randy prepares/draws anything so every downstream path
    -- (2D trainer card, optional 3D player renderer, shadow/ghost passes) sees
    -- the same absolute rider height from the start of the frame.
    lockPlayerPose(posed)
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
  api = 1,
  status = function()
    return {
      installs = state.installs,
      lockedFrames = state.lockedFrames,
      ground = state.lastGround,
      target = state.lastTarget,
    }
  end,
}

install()
log("Gen2 Stadium absolute rider-height lock loaded")
end)();
