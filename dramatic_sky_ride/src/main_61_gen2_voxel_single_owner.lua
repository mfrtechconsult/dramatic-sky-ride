;(function()
-- -------------------------------------------------------------------------
-- Gen2 voxel single-owner hardening.
--
-- This late layer fixes four Gold/STADIUM2_OVERWORLD_MODELS issues that need
-- one authoritative owner rather than more per-frame masking:
--   * Randy's native party follower must not exist while DSR owns a mount;
--   * DSR's legacy rider entities must not coexist with the live Player rider;
--   * Randy must remain the stable Stadium provider while the user selected it;
--   * the final Stadium model/rider transforms must share one vertical anchor.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local state = {
  rendererExportsInstalled = false,
  followerGateInstalled = false,
  followerGatePrevious = nil,
  followerGateWrapper = nil,
  followersPurged = 0,
  riderEntitiesSuppressed = 0,
  geometryAdjustments = 0,
  riderLiftAdjustments = 0,
  externalFrames = 0,
  lastMountKind = nil,
  lastMountSpecies = nil,
  lastSeatWorldY = nil,
  lastGroundCorrection = nil,
  lastScaleCorrection = nil,
  lastError = nil,
}

local suppressedRiders = setmetatable({}, { __mode = "k" })

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function liveWorld()
  return mod.exports._mountWorld and mod.exports._mountWorld(Game) or nil
end

local function providerExports()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  return ok and handle and handle.exports or nil
end

local function providerVoxelActive()
  local ex = providerExports()
  local bridge = ex and ex.voxelPipelineState or nil
  if type(bridge) ~= "table" then return false end
  if type(bridge.status) == "function" then
    local ok, status = pcall(bridge.status)
    if ok and type(status) == "table" and status.active ~= nil then
      return status.active == true
    end
  end
  if bridge.active ~= nil then return bridge.active == true end
  return ex.voxelComposeHook == true or ex.rendererInstalled == true
end

local function activeMount()
  if flight and flight.active and flight.species then
    return "flight", flight.species
  end
  if ground and ground.active and ground.species then
    return "ground", ground.species
  end
  local ex = mod.exports or {}
  if type(ex.isWaterRiding) == "function" and type(ex.waterMountSpecies) == "function" then
    local okActive, active = pcall(ex.isWaterRiding)
    if okActive and active == true then
      local okSpecies, species = pcall(ex.waterMountSpecies)
      if okSpecies and species then return "water", species end
    end
  end
  return nil
end

local function stadiumRequested()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.requested) == "function" then
    local ok, value = pcall(rendering.requested)
    return ok and tostring(value):lower() == "stadium"
  end
  return false
end

-- Model availability is deliberately NOT part of this decision. Once the user
-- selected STADIUM 3D and the Gen2 provider is alive, Randy remains the owner.
-- A missing/corrupt species can still fall back to its own 2D card naturally,
-- but transient pack/cache probes can no longer switch the whole DSR renderer.
local function stableExternalOwner()
  if not (isGold() and stadiumRequested() and providerVoxelActive()) then return false end
  local ex = providerExports()
  return type(ex) == "table" and type(ex.overworld) == "table"
end

-- -------------------------------------------------------------------------
-- Stable exported renderer decision + native DSR arbitration.
--
-- main_41's old native Stadium2 renderer asks only usesStadium(). While Randy
-- owns Gen2, answer false THERE so the native renderer cannot create a second
-- model. Every Gen2 external consumer uses usesGen2VoxelStadium() explicitly.
-- -------------------------------------------------------------------------
local function installStableRendererExports()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if type(rendering) ~= "table" then return false end
  if rendering._gen2StableExternalOwner == state then return true end

  local rawProvider = rendering.provider
  local rawEffective = rendering.effective
  local rawUses2D = rendering.uses2D
  local rawUsesStadium = rendering.usesStadium
  local rawUsesNative = rendering.usesNativeStadium
  local rawUsesGen2 = rendering.usesGen2VoxelStadium

  local function fallback(fn, default)
    if type(fn) ~= "function" then return default end
    local ok, value = pcall(fn)
    return ok and value or default
  end

  rendering.provider = function()
    if stableExternalOwner() then return "gen2_stadium2_voxel" end
    return fallback(rawProvider, nil)
  end
  rendering.effective = function()
    if stableExternalOwner() then return "stadium" end
    return fallback(rawEffective, "2d")
  end
  rendering.uses2D = function()
    if stableExternalOwner() then return false end
    return fallback(rawUses2D, true) == true
  end
  rendering.usesGen2VoxelStadium = function()
    if stableExternalOwner() then return true end
    return fallback(rawUsesGen2, false) == true
  end
  rendering.usesNativeStadium = function()
    if stableExternalOwner() then return false end
    return fallback(rawUsesNative, false) == true
  end
  rendering.usesStadium = function()
    if stableExternalOwner() then
      -- Intentionally false only for the legacy/native DSR generic seam.
      -- main_58/main_59/main_60 use usesGen2VoxelStadium() first.
      return false
    end
    return fallback(rawUsesStadium, false) == true
  end
  rendering._gen2StableExternalOwner = state

  local compat = mod.exports and mod.exports.stadiumCompatibility or nil
  if type(compat) == "table" and compat._gen2StableExternalOwner ~= state then
    local rawCompatProvider = compat.provider
    local rawCompatEffective = compat.effectiveRenderer
    local rawCompatEnabled = compat.enabled
    compat.provider = function()
      if stableExternalOwner() then return "gen2_stadium2_voxel" end
      return fallback(rawCompatProvider, nil)
    end
    compat.effectiveRenderer = function()
      if stableExternalOwner() then return "stadium" end
      return fallback(rawCompatEffective, "2d")
    end
    compat.enabled = function()
      if stableExternalOwner() then return true end
      return fallback(rawCompatEnabled, false) == true
    end
    compat._gen2StableExternalOwner = state
  end

  state.rendererExportsInstalled = true
  return true
end

-- -------------------------------------------------------------------------
-- Native Gold party follower ownership.
--
-- Randy installs a src.world.gen2.Follower shouldSpawn callback for party slot
-- #1. GoldVoxelBridge merges world.npcs before DSR's extra provider, so hiding
-- the follower later is inherently racy. Chain the engine gate instead: while
-- ANY DSR mount is active the follower does not exist, and Randy's exact gate
-- resumes automatically on dismount.
-- -------------------------------------------------------------------------
local Follower2 = nil
local function installFollowerGate()
  if state.followerGateInstalled then return true end
  local ok, Follower = pcall(require, "src.world.gen2.Follower")
  if not ok or type(Follower) ~= "table" or type(Follower.setShouldSpawn) ~= "function" then
    state.lastError = "Gen2 Follower.setShouldSpawn unavailable"
    return false
  end
  Follower2 = Follower

  local marker = Follower._dramaticSkyRideMountGate
  if type(marker) == "table" and marker.owner == mod.id then
    state.followerGatePrevious = marker.previous
    state.followerGateWrapper = marker.wrapper
    state.followerGateInstalled = true
    return true
  end

  local previous
  local wrapper = function(game, world)
    local kind = activeMount()
    if kind then return false end
    if type(previous) == "function" then
      local okPrev, value = pcall(previous, game, world)
      return okPrev and value == true
    end
    return false
  end
  previous = Follower.setShouldSpawn(wrapper)
  Follower._dramaticSkyRideMountGate = {
    owner = mod.id,
    previous = previous,
    wrapper = wrapper,
  }
  state.followerGatePrevious = previous
  state.followerGateWrapper = wrapper
  state.followerGateInstalled = true
  return true
end

local function removeFrom(list, entity)
  if type(list) ~= "table" then return end
  for i = #list, 1, -1 do
    if list[i] == entity then table.remove(list, i) end
  end
end

local function purgeNativeFollower(world)
  if not (Follower2 and world) then return end
  local entity = type(Follower2.current) == "function" and Follower2.current(world) or nil
  if not entity then return end
  removeFrom(world.npcs, entity)
  removeFrom(world.entities, entity)
  if world.follower == entity then world.follower = nil end
  state.followersPurged = state.followersPurged + 1
end

-- -------------------------------------------------------------------------
-- Single rider actor.
--
-- Gold voxel mode already turns the REAL Player pose into DSR's cropped rider.
-- Old Flight/Ground/Surf compatibility entities are therefore duplicates. Keep
-- their update state alive but return a successful nil-sprite pose so VoxelScene
-- skips their card. Flat Gold fallback still uses main_56's direct composition.
-- -------------------------------------------------------------------------
local function legacyRiderEntity(entity)
  if type(entity) ~= "table" then return false end
  return entity.skyRideRider == true
    or entity.groundRideRider == true
    or entity.waterRideRider == true
    or entity.id == "sky_ride_rider"
    or entity.id == "ground_ride_rider"
    or entity.id == "water_ride_rider"
end

local function suppressRider(entity)
  if type(entity) ~= "table" or suppressedRiders[entity] then return end
  local inherited = entity.pose
  if type(inherited) ~= "function" then return end
  local rawPose = rawget(entity, "pose")
  local wrapper = function(self, ...)
    if providerVoxelActive() and activeMount() then
      return nil, self.px or 0, self.py or 0, self.facing or "down", 0,
        self.stepFlip == true, false
    end
    return inherited(self, ...)
  end
  suppressedRiders[entity] = { rawPose = rawPose, wrapper = wrapper }
  rawset(entity, "pose", wrapper)
  state.riderEntitiesSuppressed = state.riderEntitiesSuppressed + 1
end

local function restoreRider(entity, saved)
  if type(entity) ~= "table" or type(saved) ~= "table" then return end
  if rawget(entity, "pose") == saved.wrapper then rawset(entity, "pose", saved.rawPose) end
  suppressedRiders[entity] = nil
end

local function syncLegacyRiders(world)
  if not (providerVoxelActive() and activeMount()) then
    for entity, saved in pairs(suppressedRiders) do restoreRider(entity, saved) end
    return
  end
  local found = {}
  for _, list in ipairs({ world and world.npcs, world and world.entities }) do
    for _, entity in pairs(type(list) == "table" and list or {}) do
      if legacyRiderEntity(entity) then
        found[entity] = true
        suppressRider(entity)
      end
    end
  end
  for entity, saved in pairs(suppressedRiders) do
    if not found[entity] then restoreRider(entity, saved) end
  end
end

-- -------------------------------------------------------------------------
-- Final Stadium transform correction.
--
-- Randy's generic _stadiumSkyRideMount path assumes every DSR mount is flying:
-- it lowers the model by riderFootLift - height*seatFraction. That is correct
-- for an airborne saddle but sinks Ground Ride Pokemon such as Suicune. Also,
-- main_58's later size multiplier changes body height without moving that saddle.
-- Correct the FINAL pose just before safeDraw/safeCast and set the Player card's
-- lift from the same absolute seat world-Y.
-- -------------------------------------------------------------------------
local SEAT_FRACTION = {
  CHARIZARD = 0.50, PIDGEOT = 0.58, FEAROW = 0.58, GOLBAT = 0.50,
  AERODACTYL = 0.50, ARTICUNO = 0.56, ZAPDOS = 0.56, MOLTRES = 0.56,
  DRAGONAIR = 0.48, DRAGONITE = 0.50,
}
local RIDER_FOOT = {
  LUGIA = 8.0, HO_OH = 7.5, GYARADOS = 7.0, LAPRAS = 7.0,
  MANTINE = 6.5, SUICUNE = 7.0, RAIKOU = 7.0, ENTEI = 7.2,
  TYRANITAR = 8.0,
}

local function cleanSpecies(value)
  if value == nil then return nil end
  return tostring(value):upper():gsub("[^A-Z0-9]", "")
end

local function isMountProxyPose(p)
  local e = p and p.entity or nil
  return type(e) == "table" and (
    e.dramaticSkyRideVoxelProxy == true
    or e.id == "DSR_GEN2_VOXEL_MOUNT"
    or e.name == "DSR_GEN2_VOXEL_MOUNT")
end

local function currentHeightBeforeDsrScale(p)
  local wanted = tonumber(p and p.stadiumTargetHeight)
  local factor = tonumber(p and p.dramaticSkyRideModelScale) or 1
  if wanted and wanted > 0 and factor > 0 then return wanted / factor, wanted, factor end
  return wanted, wanted, factor
end

local function flightSeatWorldY(species)
  local foot = RIDER_FOOT[cleanSpecies(species)] or 7.0
  -- DSR flight.altitude is absolute world-space height. Using it directly
  -- avoids disagreement between DSR's terrain sampler and VoxelScene p.gh.
  return (tonumber(flight and flight.altitude) or 0) + foot
end

local function adjustMountGeometry(p)
  if not (stableExternalOwner() and isMountProxyPose(p)
      and type(p.stadiumMatrix) == "table" and p.stadiumMon) then return end
  if p._dramaticSkyRideFinalGeometryAdjusted then return end

  local kind, species = activeMount()
  if not kind then return end
  local key = cleanSpecies(species)
  local oldH, wantedH = currentHeightBeforeDsrScale(p)
  oldH = tonumber(oldH) or tonumber(wantedH)
  local fraction = SEAT_FRACTION[key] or 0.52
  local matrix = p.stadiumMatrix
  local dy = 0

  if kind == "ground" and oldH then
    local e = p.entity or {}
    local metadataGround = tonumber(e._stadiumSkyRideGround)
    if metadataGround == nil then metadataGround = tonumber(p.gh) or 0 end
    local currentGroundY = metadataGround
      + (tonumber(e._stadiumSkyRideLift) or 0)
      + 7.0 - oldH * fraction
    local desiredGroundY = tonumber(p.gh) or metadataGround
    local correction = desiredGroundY - currentGroundY
    dy = dy + correction
    state.lastGroundCorrection = correction
  elseif kind == "flight" and oldH and wantedH then
    -- Keep Randy's authored saddle point fixed after DSR scales the model.
    local correction = -(wantedH - oldH) * fraction
    dy = dy + correction
    state.lastScaleCorrection = correction
  end

  if dy ~= 0 then
    matrix[8] = (tonumber(matrix[8]) or 0) + dy
    p.stadiumMatrix = matrix
    p.stadiumMon.model_matrix = matrix
  end
  p._dramaticSkyRideFinalGeometryAdjusted = true
  state.geometryAdjustments = state.geometryAdjustments + 1
end

local function adjustPlayerRiderPose(p)
  if not (stableExternalOwner() and p and p.isPlayer) then return end
  local entity = p.entity
  if type(entity) ~= "table" or entity._dramaticSkyRideVoxelRider ~= true then return end
  local kind, species = activeMount()
  if kind ~= "flight" then return end
  local seatY = flightSeatWorldY(species)
  p.lift = seatY - (tonumber(p.gh) or 0)
  state.lastSeatWorldY = seatY
  state.riderLiftAdjustments = state.riderLiftAdjustments + 1
end

local function installDrawTransformHooks()
  local ex = providerExports()
  local stadium = ex and ex.overworld or nil
  if type(stadium) ~= "table" then return false end
  local marker = stadium._dramaticSkyRideFinalTransformGuard
  if type(marker) == "table" and marker.owner == mod.id then return true end

  local rawDraw = stadium.safeDraw
  if type(rawDraw) == "function" then
    stadium.safeDraw = function(p, ...)
      adjustPlayerRiderPose(p)
      adjustMountGeometry(p)
      return rawDraw(p, ...)
    end
  end

  local rawCast = stadium.safeCast
  if type(rawCast) == "function" then
    stadium.safeCast = function(p, ...)
      adjustMountGeometry(p)
      return rawCast(p, ...)
    end
  end

  stadium._dramaticSkyRideFinalTransformGuard = {
    owner = mod.id,
    drawRaw = rawDraw,
    castRaw = rawCast,
  }
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() and Game.overworld == self then
    installStableRendererExports()
    installFollowerGate()
    installDrawTransformHooks()
    local kind, species = activeMount()
    state.lastMountKind, state.lastMountSpecies = kind, species
    if kind then purgeNativeFollower(self) end
    syncLegacyRiders(self)
    if stableExternalOwner() then state.externalFrames = state.externalFrames + 1 end
  else
    syncLegacyRiders(nil)
  end
  return result
end

mod.events:on("game.ready", function()
  if isGold() then
    installStableRendererExports()
    installFollowerGate()
    installDrawTransformHooks()
  end
end)

mod.events:on("mod.options_changed", function()
  if isGold() then
    installStableRendererExports()
    installDrawTransformHooks()
  end
end)

mod.exports.gen2VoxelSingleOwner = {
  api = 1,
  externalOwner = stableExternalOwner,
  status = function()
    return {
      rendererExportsInstalled = state.rendererExportsInstalled,
      followerGateInstalled = state.followerGateInstalled,
      providerVoxelActive = providerVoxelActive(),
      stadiumRequested = stadiumRequested(),
      externalOwner = stableExternalOwner(),
      mountKind = select(1, activeMount()),
      mountSpecies = select(2, activeMount()),
      followersPurged = state.followersPurged,
      riderEntitiesSuppressed = state.riderEntitiesSuppressed,
      geometryAdjustments = state.geometryAdjustments,
      riderLiftAdjustments = state.riderLiftAdjustments,
      externalFrames = state.externalFrames,
      lastSeatWorldY = state.lastSeatWorldY,
      lastGroundCorrection = state.lastGroundCorrection,
      lastScaleCorrection = state.lastScaleCorrection,
      lastError = state.lastError,
    }
  end,
}

installStableRendererExports()
installFollowerGate()
installDrawTransformHooks()
log("Gen2 voxel single-owner hardening loaded (stable Randy provider, no native follower/rider duplicates, shared vertical anchor)")
end)();