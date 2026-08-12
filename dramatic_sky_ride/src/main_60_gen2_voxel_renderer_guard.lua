;(function()
-- -------------------------------------------------------------------------
-- Final Gen 2 voxel renderer ownership guard.
--
-- main_58 intentionally keeps a separate DSR mount proxy in the Gold voxel
-- cast even when the user selects 2D SPRITES: the real Player pose is then the
-- cropped rider and the proxy is the 2D mount billboard. That composition is
-- required because GoldVoxelBridge bypasses Player:draw().
--
-- STADIUM2_OVERWORLD_MODELS also recognises DSR sprite/species tags. Its normal
-- stadiumModel=false opt-out is already set by main_58, but this late guard is
-- deliberately stronger: unless DSR's EFFECTIVE renderer is the external
-- Gen2 Stadium provider, the DSR proxy is forbidden from retaining prepared
-- Stadium geometry and safeDraw/safeCast refuse it explicitly.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local guard = {
  installed = false,
  stadium = nil,
  prepareRaw = nil,
  prepareWrapper = nil,
  drawRaw = nil,
  drawWrapper = nil,
  castRaw = nil,
  castWrapper = nil,
  blockedPrepareFrames = 0,
  blockedDraws = 0,
  blockedCasts = 0,
  lastError = nil,
}

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function providerExports()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  return ok and handle and handle.exports or nil
end

local function stadiumMountMode()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    return ok and value == true
  end
  if rendering and type(rendering.provider) == "function"
      and type(rendering.effective) == "function" then
    local okP, provider = pcall(rendering.provider)
    local okE, effective = pcall(rendering.effective)
    return okP and okE and provider == "gen2_stadium2_voxel"
      and effective == "stadium"
  end
  return false
end

local function isDsrMountProxy(p)
  local entity = p and p.entity or p
  return type(entity) == "table" and (
    entity.dramaticSkyRideVoxelProxy == true
    or entity.id == "DSR_GEN2_VOXEL_MOUNT"
    or entity.name == "DSR_GEN2_VOXEL_MOUNT")
end

local function clearPreparedModel(p)
  if type(p) ~= "table" then return end
  p.stadiumMon = nil
  p.stadiumMatrix = nil
  p.stadiumDex = nil
  p.stadiumShadowTick = nil
  p.stadiumTargetHeight = nil
  p.stadiumHeightMeters = nil
  p.stadiumWalking = nil
  p.dramaticSkyRideModelScale = nil
  local entity = p.entity
  if type(entity) == "table" then
    entity.stadiumModel = false
    entity.pokemonModel = false
  end
end

local function installGuard()
  local ex = providerExports()
  local stadium = ex and ex.overworld or nil
  if type(stadium) ~= "table" then
    guard.lastError = "provider overworld API unavailable"
    return false
  end

  local marker = stadium._dramaticSkyRideRendererOwnershipGuard
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.prepareWrapper then
    guard.installed = true
    guard.stadium = stadium
    guard.prepareRaw = marker.prepareRaw
    guard.prepareWrapper = marker.prepareWrapper
    guard.drawRaw = marker.drawRaw
    guard.drawWrapper = marker.drawWrapper
    guard.castRaw = marker.castRaw
    guard.castWrapper = marker.castWrapper
    guard.lastError = nil
    return true
  end

  local rawPrepare = stadium.prepare
  if type(rawPrepare) ~= "function" then
    guard.lastError = "provider prepare() unavailable"
    return false
  end

  local prepareWrapper = function(posed, ...)
    local result = rawPrepare(posed, ...)
    if isGold() and not stadiumMountMode() then
      local blocked = false
      for _, p in ipairs(posed or {}) do
        if isDsrMountProxy(p) then
          clearPreparedModel(p)
          blocked = true
        end
      end
      if blocked then guard.blockedPrepareFrames = guard.blockedPrepareFrames + 1 end
    end
    return result
  end

  local rawDraw = stadium.safeDraw
  local drawWrapper = rawDraw
  if type(rawDraw) == "function" then
    drawWrapper = function(p, ...)
      if isGold() and isDsrMountProxy(p) and not stadiumMountMode() then
        clearPreparedModel(p)
        guard.blockedDraws = guard.blockedDraws + 1
        return false
      end
      return rawDraw(p, ...)
    end
  end

  local rawCast = stadium.safeCast
  local castWrapper = rawCast
  if type(rawCast) == "function" then
    castWrapper = function(p, ...)
      if isGold() and isDsrMountProxy(p) and not stadiumMountMode() then
        clearPreparedModel(p)
        guard.blockedCasts = guard.blockedCasts + 1
        return false
      end
      return rawCast(p, ...)
    end
  end

  stadium.prepare = prepareWrapper
  if type(rawDraw) == "function" then stadium.safeDraw = drawWrapper end
  if type(rawCast) == "function" then stadium.safeCast = castWrapper end
  stadium._dramaticSkyRideRendererOwnershipGuard = {
    owner = mod.id,
    prepareRaw = rawPrepare,
    prepareWrapper = prepareWrapper,
    drawRaw = rawDraw,
    drawWrapper = drawWrapper,
    castRaw = rawCast,
    castWrapper = castWrapper,
  }

  guard.installed = true
  guard.stadium = stadium
  guard.prepareRaw = rawPrepare
  guard.prepareWrapper = prepareWrapper
  guard.drawRaw = rawDraw
  guard.drawWrapper = drawWrapper
  guard.castRaw = rawCast
  guard.castWrapper = castWrapper
  guard.lastError = nil
  return true
end

-- Run after main_58/main_59 every Gold tick. This also repairs the hook if the
-- provider is hot-loaded or rebuilds its public overworld table after startup.
local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() then installGuard() end
  return result
end

mod.events:on("game.ready", function()
  if isGold() then installGuard() end
end)

mod.events:on("mod.options_changed", function()
  if isGold() then installGuard() end
end)

mod.exports.gen2VoxelRendererGuard = {
  api = 1,
  installed = function() return guard.installed end,
  stadiumMountMode = stadiumMountMode,
  status = function()
    return {
      installed = guard.installed,
      stadiumMountMode = stadiumMountMode(),
      blockedPrepareFrames = guard.blockedPrepareFrames,
      blockedDraws = guard.blockedDraws,
      blockedCasts = guard.blockedCasts,
      lastError = guard.lastError,
    }
  end,
}

if installGuard() then
  log("Gen2 voxel renderer guard loaded (DSR 2D mounts cannot become Stadium models)")
else
  log("Gen2 voxel renderer guard idle; %s not available", PROVIDER_ID)
end
end)();