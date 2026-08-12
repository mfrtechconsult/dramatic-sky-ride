;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites / STADIUM2_OVERWORLD_MODELS interoperability.
--
-- Gold's native DSR bridge temporarily makes the live Player wear the mount
-- sprite because the flat renderer has only one player draw. Randy's Gen-2
-- voxel renderer has a better contract: it can merge additional entities into
-- VoxelScene. In that renderer keep the real Player as the rider and publish a
-- separate passable Pokemon proxy for Flight, Ground Ride and Visible Surf.
--
-- Gameplay ownership never moves: DSR still controls movement, collisions,
-- altitude, progression, battles and mount lifecycle. This file is presentation
-- only and is completely dormant without STADIUM2_OVERWORLD_MODELS.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local providerState = {
  handle = nil,
  bridge = nil,
  previousExtraProvider = nil,
  wrapper = nil,
  installed = false,
  installs = 0,
  providerCalls = 0,
  preservedCalls = 0,
  proxyFrames = 0,
  lastError = nil,
}

local proxy = {
  id = "DSR_GEN2_VOXEL_MOUNT",
  name = "DSR_GEN2_VOXEL_MOUNT",
  passable = true,
  dramaticSkyRideVoxelProxy = true,
  _stadiumSkyRideMount = true,
}

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function liveWorld()
  return mod.exports._mountWorld and mod.exports._mountWorld(Game) or nil
end

local function safeHandle()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  return ok and handle or nil
end

local function providerExports()
  local handle = safeHandle()
  return handle, handle and handle.exports or nil
end

local function voxelBridge()
  local handle, ex = providerExports()
  local bridge = ex and ex.voxelPipelineState or nil
  if type(bridge) ~= "table" or type(bridge.setExtraEntitiesProvider) ~= "function" then
    return handle, ex, nil
  end
  return handle, ex, bridge
end

local function voxelActive()
  local _, ex, bridge = voxelBridge()
  if not (ex and bridge) then return false end
  if type(bridge.status) == "function" then
    local ok, status = pcall(bridge.status)
    if ok and type(status) == "table" and status.active ~= nil then
      return status.active == true
    end
  end
  if bridge.active ~= nil then return bridge.active == true end
  return ex.voxelComposeHook == true or ex.rendererInstalled == true
end

local function mountState()
  if flight and flight.active and flight.sprite then
    return "flight", flight.species or (flight.mon and flight.mon.species), flight.sprite
  end
  if ground and ground.active and ground.sprite then
    return "ground", ground.species or (ground.mon and ground.mon.species), ground.sprite
  end
  local ex = mod.exports or {}
  local waterVisual = ex._waterRideVisual
  if type(ex.isWaterRiding) == "function" and type(ex.waterMountSpecies) == "function"
     and type(waterVisual) == "function" then
    local okActive, active = pcall(ex.isWaterRiding)
    if okActive and active == true then
      local okSpecies, species = pcall(ex.waterMountSpecies)
      local okSprite, sprite = pcall(waterVisual)
      if okSpecies and okSprite and species and sprite then
        return "water", species, sprite
      end
    end
  end
  return nil
end

local function externalStadiumRequested()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if not rendering then return false end
  if type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    return ok and value == true
  end
  if type(rendering.provider) == "function" and type(rendering.usesStadium) == "function" then
    local okP, provider = pcall(rendering.provider)
    local okS, stadium = pcall(rendering.usesStadium)
    return okP and okS and stadium == true and provider == "gen2_stadium2_voxel"
  end
  return false
end

local function terrainFloor(world, player)
  if not (world and world.map and player) then return 0 end
  local ok, height = pcall(terrainGroundHeight, world.map, player.cellX, player.cellY)
  return ok and tonumber(height) or 0
end

local function flightLift(world, player)
  if not (flight and flight.active) then return 0 end
  return math.max(0, (tonumber(flight.altitude) or 0) - terrainFloor(world, player))
end

local function movementPhase(player, kind)
  if kind == "flight" then
    return (tonumber(flight.anim) or 0) >= 16 and 1 or 0
  end
  if player and type(player.walkPhase) == "function" then
    local ok, phase = pcall(player.walkPhase, player)
    if ok then return phase or 0 end
  end
  return 0
end

local function configureProxy(world, kind, species, sprite)
  local player = world and world.player or nil
  if not (player and species and sprite) then return false end

  local stadium = externalStadiumRequested()
  local lift = kind == "flight" and flightLift(world, player) or 0
  local ground = terrainFloor(world, player)

  proxy.sprite = sprite
  proxy.spriteDef = sprite.def
  proxy.cellX, proxy.cellY = player.cellX, player.cellY
  proxy.px, proxy.py = player.px, player.py
  proxy.facing = player.facing
  proxy.moving = player.moving
  proxy.targetX, proxy.targetY = player.targetX, player.targetY
  proxy.stepFlip = player.stepFlip
  proxy.dramaticSkyRideMountSpecies = species
  proxy.skyRideMountSpecies = species
  proxy.stadiumSpecies = species
  proxy.pokemonSpecies = species
  proxy.species = species
  proxy._stadiumSkyRideAnchorPx = player.px
  proxy._stadiumSkyRideAnchorPy = player.py
  proxy._stadiumSkyRideAnchorFacing = player.facing
  proxy._stadiumSkyRideGround = ground
  proxy._stadiumSkyRideLift = lift
  proxy._stadiumSkyRideAltitude = ground + lift
  proxy._stadiumSkyRideKind = kind
  proxy.stadiumModel = stadium and true or false
  proxy.pokemonModel = stadium and true or false
  return true
end

function proxy:pose()
  local world = liveWorld()
  local kind, species, sprite = mountState()
  local player = world and world.player or nil
  if not (kind and species and sprite and player
          and configureProxy(world, kind, species, sprite)) then
    return nil
  end
  local lift = kind == "flight" and flightLift(world, player) or 0
  local py = (tonumber(player.py) or 0) - lift
  return sprite, player.px, py, player.facing,
    movementPhase(player, kind), player.stepFlip == true, false
end

local function appendUnique(out, seen, entity)
  if type(entity) ~= "table" or seen[entity] then return end
  seen[entity] = true
  out[#out + 1] = entity
end

local function shouldPublishProxy(world)
  if not (isGold() and voxelActive() and world and world.player) then return false end
  local kind, species, sprite = mountState()
  if not (kind and species and sprite) then return false end
  return configureProxy(world, kind, species, sprite)
end

local function restorePreviousProviderMarker(bridge)
  local marker = bridge and bridge._dramaticSkyRideGen2VoxelProvider or nil
  if type(marker) ~= "table" or marker.owner ~= mod.id then return end
  if bridge.extraEntitiesProvider == marker.wrapper then
    pcall(bridge.setExtraEntitiesProvider, marker.previous)
  end
  bridge._dramaticSkyRideGen2VoxelProvider = nil
end

local function installExtraProvider()
  local handle, _, bridge = voxelBridge()
  if not bridge then return false end
  if providerState.bridge == bridge and providerState.installed then return true end

  restorePreviousProviderMarker(bridge)

  local previous = bridge.extraEntitiesProvider
  local wrapper
  wrapper = function(world)
    providerState.providerCalls = providerState.providerCalls + 1
    local out, seen = {}, {}
    if type(previous) == "function" then
      local ok, extra = pcall(previous, world)
      if ok and type(extra) == "table" then
        providerState.preservedCalls = providerState.preservedCalls + 1
        for _, entity in ipairs(extra) do appendUnique(out, seen, entity) end
      elseif not ok then
        providerState.lastError = "previous extra entity provider failed: " .. tostring(extra)
      end
    end
    if shouldPublishProxy(world) then
      appendUnique(out, seen, proxy)
      providerState.proxyFrames = providerState.proxyFrames + 1
    end
    return out
  end

  local ok, result, err = pcall(bridge.setExtraEntitiesProvider, wrapper)
  if not ok or result == false then
    providerState.lastError = tostring(ok and err or result)
    return false
  end

  providerState.handle = handle
  providerState.bridge = bridge
  providerState.previousExtraProvider = previous
  providerState.wrapper = wrapper
  providerState.installed = true
  providerState.installs = providerState.installs + 1
  providerState.lastError = nil
  bridge._dramaticSkyRideGen2VoxelProvider = {
    owner = mod.id,
    previous = previous,
    wrapper = wrapper,
  }
  return true
end

-- main_56 intentionally replaces Gold's player sprite with the mount for the
-- flat renderer. After that update, expose its remembered native player sprite
-- again only while Randy's voxel compose path is active. The separate proxy is
-- then the Pokemon actor. Flat fallback still uses main_56 on the next tick.
local function exposeNativeRider(world)
  if not (world and world.player and shouldPublishProxy(world)) then return false end
  local api = mod.exports and mod.exports.gen2PlayerBridge or nil
  local nativeFn = api and api.nativePlayerSprite or nil
  if type(nativeFn) ~= "function" then return false end

  local ok, native, nativeDef = pcall(nativeFn, world.player)
  if not (ok and native) then return false end
  world.player.sprite = native
  world.player.spriteDef = nativeDef or native.def or world.player.spriteDef

  local kind = select(1, mountState())
  local lift = kind == "flight" and flightLift(world, world.player) or 0
  -- Full Gold/red_3d_player rider stays above the Pokemon body. Species-specific
  -- model seating remains owned by Randy's Stadium transform; this offset only
  -- carries the rider through DSR's vertical Flight state.
  world.player.spriteYOffset = -math.floor(lift + 0.5)
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() then
    installExtraProvider()
    if voxelActive() and Game.overworld == self then exposeNativeRider(self) end
  end
  return result
end

mod.events:on("game.ready", function()
  if isGold() then installExtraProvider() end
end)

mod.events:on("mod.options_changed", function()
  -- The proxy reads renderer/voxel settings lazily each compose frame. This
  -- event only ensures a provider installed after startup is picked up quickly.
  if isGold() then installExtraProvider() end
end)

mod.exports.gen2VoxelInterop = {
  api = 1,
  providerId = PROVIDER_ID,
  installed = function() return providerState.installed end,
  active = function()
    local world = liveWorld()
    return providerState.installed and shouldPublishProxy(world)
  end,
  provider = function()
    local rendering = mod.exports and mod.exports.flightRendering or nil
    if rendering and type(rendering.provider) == "function" then
      local ok, value = pcall(rendering.provider)
      if ok then return value end
    end
    return nil
  end,
  mountProxyActive = function()
    return shouldPublishProxy(liveWorld())
  end,
  mountSpecies = function()
    return select(2, mountState())
  end,
  mountKind = function()
    return select(1, mountState())
  end,
  rendererRequested = function()
    local rendering = mod.exports and mod.exports.flightRendering or nil
    if rendering and type(rendering.requested) == "function" then
      local ok, value = pcall(rendering.requested)
      if ok then return value end
    end
    return "2d"
  end,
  rendererEffective = function()
    local rendering = mod.exports and mod.exports.flightRendering or nil
    if rendering and type(rendering.effective) == "function" then
      local ok, value = pcall(rendering.effective)
      if ok then return value end
    end
    return "2d"
  end,
  existingExtraProviderPreserved = function()
    return providerState.previousExtraProvider ~= nil
  end,
  status = function()
    return {
      installed = providerState.installed,
      voxelActive = voxelActive(),
      proxyActive = shouldPublishProxy(liveWorld()),
      mountKind = select(1, mountState()),
      mountSpecies = select(2, mountState()),
      stadiumRequested = externalStadiumRequested(),
      providerCalls = providerState.providerCalls,
      preservedCalls = providerState.preservedCalls,
      proxyFrames = providerState.proxyFrames,
      installs = providerState.installs,
      previousProvider = providerState.previousExtraProvider ~= nil,
      lastError = providerState.lastError,
    }
  end,
}

if installExtraProvider() then
  log("Gen2 voxel interop loaded (%s extra-entity composition + DSR mount proxy)", PROVIDER_ID)
else
  log("Gen2 voxel interop idle; %s not available", PROVIDER_ID)
end
end)();
