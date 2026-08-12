;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites / STADIUM2_OVERWORLD_MODELS interoperability.
--
-- Gold's flat DSR bridge temporarily makes the live Player wear the mount
-- sprite because the normal renderer has only one player draw. Randy's Gen-2
-- voxel renderer can merge extra entities, so in voxel views we instead expose
-- a separate passable Pokemon proxy and turn the player pose into DSR's normal
-- cropped rider. This keeps the established DSR composition in both 2D and
-- Stadium modes while leaving gameplay ownership entirely inside DSR.
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
  filteredMountFollowers = 0,
  suppressedMountFollowers = 0,
  riderPoseFrames = 0,
  modelScaleFrames = 0,
  lastModelScale = 1,
  lastModelTargetHeight = nil,
  lastProviderTargetHeight = nil,
  lastError = nil,
}

local proxy = {
  id = "DSR_GEN2_VOXEL_MOUNT",
  name = "DSR_GEN2_VOXEL_MOUNT",
  passable = true,
  dramaticSkyRideVoxelProxy = true,
  _stadiumSkyRideMount = true,
}

local riderProxy = {
  id = "DSR_GEN2_VOXEL_RIDER",
  name = "DSR_GEN2_VOXEL_RIDER",
  passable = true,
}

local riderState = {
  player = nil,
  world = nil,
  rawPose = nil,
  nativePose = nil,
  wrapper = nil,
  oldMarker = nil,
}

local suppressedFollowers = setmetatable({}, { __mode = "k" })
local providerHooks = {
  stadium = nil,
  skinRaw = nil,
  skinWrapper = nil,
  prepareRaw = nil,
  prepareWrapper = nil,
  mat4 = nil,
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
  local groundHeight = terrainFloor(world, player)

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
  proxy._stadiumSkyRideGround = groundHeight
  proxy._stadiumSkyRideLift = lift
  proxy._stadiumSkyRideAltitude = groundHeight + lift
  proxy._stadiumSkyRideKind = kind
  -- Explicitly opt out when DSR says 2D. OverworldStadium checks these flags
  -- before species tags/cache, so a previous 3D frame cannot leak into 2D.
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

local function cleanSpecies(value)
  if type(value) == "table" then
    value = value.species or value.pokemonSpecies or value.stadiumSpecies
      or value.dex or value.pokemonDex
  end
  if value == nil then return nil end
  local s = tostring(value):upper():gsub("[^A-Z0-9]", "")
  return s ~= "" and s or nil
end

local function followerSpecies(entity)
  if type(entity) ~= "table" then return nil end
  local values = {
    entity._wildsFollowerSpecies,
    entity._pokepcFollowerSpecies,
    entity.pokepcFollowerSpecies,
    entity.followerSpecies,
    entity.pokemonSpecies,
    entity.stadiumSpecies,
    type(entity.pokepcMon) == "table" and entity.pokepcMon.species or nil,
    entity.species,
  }
  for _, value in ipairs(values) do
    local s = cleanSpecies(value)
    if s then return s end
  end
  return nil
end

local function followerLike(entity)
  return type(entity) == "table" and entity ~= proxy and (
    entity.wildsFollower == true
    or entity.pikachuFollower == true
    or entity._wildsFollowerSpecies ~= nil
    or entity._pokepcFollowerSpecies ~= nil
    or entity.pokepcFollowerSpecies ~= nil
    or entity.pokepcMon ~= nil
    or entity.followerSpecies ~= nil)
end

local function isCurrentMountFollower(entity)
  if not followerLike(entity) then return false end
  local _, species = mountState()
  local current = cleanSpecies(species)
  return current ~= nil and followerSpecies(entity) == current
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
        for _, entity in ipairs(extra) do
          -- Randy's embedded Wilds/provider can publish the party follower as
          -- an extra voxel entity. While that Pokemon is the active DSR mount,
          -- the DSR proxy is the single visual owner; keeping the follower is
          -- exactly what produced a second Ho-Oh/Suicune at ground level.
          if isCurrentMountFollower(entity) then
            providerState.filteredMountFollowers = providerState.filteredMountFollowers + 1
          else
            appendUnique(out, seen, entity)
          end
        end
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

-- Native Gold party followers are already part of GoldVoxelBridge's base
-- entity set, so filtering the extra provider is not sufficient. Temporarily
-- make ONLY the active mount's follower pose invisible and opt it out of
-- Stadium rescue. Its movement/trail state keeps running and is restored on
-- dismount, so normal following resumes without a teleport or reset.
local function suppressFollower(entity)
  if type(entity) ~= "table" or suppressedFollowers[entity] then return end
  local nativePose = entity.pose
  if type(nativePose) ~= "function" then return end
  local rawPose = rawget(entity, "pose")
  local oldStadium = entity.stadiumModel
  local oldPokemon = entity.pokemonModel
  local wrapper = function(self)
    if voxelActive() and isCurrentMountFollower(self) then
      return nil, self.px or 0, self.py or 0, self.facing or "down", 0,
        self.stepFlip == true, false
    end
    return nativePose(self)
  end
  suppressedFollowers[entity] = {
    rawPose = rawPose,
    wrapper = wrapper,
    stadiumModel = oldStadium,
    pokemonModel = oldPokemon,
  }
  rawset(entity, "pose", wrapper)
  entity.stadiumModel = false
  entity.pokemonModel = false
  providerState.suppressedMountFollowers = providerState.suppressedMountFollowers + 1
end

local function restoreFollower(entity, state)
  if type(entity) ~= "table" or type(state) ~= "table" then return end
  if rawget(entity, "pose") == state.wrapper then rawset(entity, "pose", state.rawPose) end
  entity.stadiumModel = state.stadiumModel
  entity.pokemonModel = state.pokemonModel
  suppressedFollowers[entity] = nil
end

local function restoreSuppressedFollowers()
  for entity, state in pairs(suppressedFollowers) do restoreFollower(entity, state) end
end

local function scanCollection(collection, found)
  if type(collection) ~= "table" then return end
  for _, entity in pairs(collection) do
    if type(entity) == "table" and isCurrentMountFollower(entity) then
      found[entity] = true
      suppressFollower(entity)
    end
  end
end

local function syncNativeMountFollowers(world)
  if not (world and shouldPublishProxy(world)) then
    restoreSuppressedFollowers()
    return
  end
  local found = {}
  scanCollection(world.npcs, found)
  scanCollection(world.entities, found)
  for entity, state in pairs(suppressedFollowers) do
    if not found[entity] or not isCurrentMountFollower(entity) then
      restoreFollower(entity, state)
    end
  end
end

-- Reuse exactly the same rider crops/seat calculations as Gold's flat DSR
-- bridge. The voxel player pose is only a presentation view; the real Player
-- coordinates and gameplay sprite remain owned by main_56.
local function mountedRiderPose(kind)
  if kind == "flight" then
    if not (showRiderEnabled() and flight.riderSprite) or isFirstPerson() then return nil end
    riderProxy.sprite = flight.riderSprite
    return riderPose(riderProxy)
  end
  if kind == "ground" then
    if not (ground and ground.riderSprite) or isFirstPerson() then return nil end
    riderProxy.sprite = ground.riderSprite
    return groundRiderPose(riderProxy)
  end
  if kind == "water" then
    if isFirstPerson() then return nil end
    local waterPose = mod.exports and mod.exports._waterRideRiderPose or nil
    if type(waterPose) ~= "function" then return nil end
    local ok, sprite, px, py, facing, phase, flip, hopping = pcall(waterPose, riderProxy)
    if ok then return sprite, px, py, facing, phase, flip, hopping end
  end
  return nil
end

local function restoreRiderPose()
  local player = riderState.player
  if player then
    if rawget(player, "pose") == riderState.wrapper then
      rawset(player, "pose", riderState.rawPose)
    end
    if rawget(player, "_dramaticSkyRideVoxelRider") == true then
      rawset(player, "_dramaticSkyRideVoxelRider", riderState.oldMarker)
    end
  end
  riderState.player = nil
  riderState.world = nil
  riderState.rawPose = nil
  riderState.nativePose = nil
  riderState.wrapper = nil
  riderState.oldMarker = nil
end

local function installRiderPose(world)
  if not (world and world.player and shouldPublishProxy(world)) then
    restoreRiderPose()
    return false
  end
  local player = world.player
  if riderState.player == player and riderState.world == world
     and rawget(player, "pose") == riderState.wrapper then
    return true
  end

  restoreRiderPose()
  local nativePose = player.pose
  if type(nativePose) ~= "function" then return false end
  local rawPose = rawget(player, "pose")
  local wrapper = function(self)
    if voxelActive() and self == world.player then
      local kind = select(1, mountState())
      if kind then
        local sprite, px, py, facing, phase, flip, hopping = mountedRiderPose(kind)
        providerState.riderPoseFrames = providerState.riderPoseFrames + 1
        if sprite then
          return sprite, px or self.px, py or self.py, facing or self.facing,
            phase or 0, flip == true, hopping == true
        end
        -- SHOW RIDER off / first-person: a successful nil-sprite pose is the
        -- provider's supported way to keep the player actor out of the cast.
        return nil, self.px or 0, self.py or 0, self.facing or "down", 0,
          self.stepFlip == true, false
      end
    end
    return nativePose(self)
  end

  riderState.player = player
  riderState.world = world
  riderState.rawPose = rawPose
  riderState.nativePose = nativePose
  riderState.wrapper = wrapper
  riderState.oldMarker = rawget(player, "_dramaticSkyRideVoxelRider")
  rawset(player, "pose", wrapper)
  rawset(player, "_dramaticSkyRideVoxelRider", true)
  return true
end

local function providerMat4(ex)
  if providerHooks.mat4 then return providerHooks.mat4 end
  local lib = ex and ex.lib or nil
  if not (lib and type(lib.require) == "function") then return nil end
  local ok, Mat4 = pcall(lib.require, "Mat4")
  if ok and type(Mat4) == "table" and type(Mat4.mul) == "function"
     and type(Mat4.scale) == "function" then
    providerHooks.mat4 = Mat4
    return Mat4
  end
  return nil
end

local function desiredModelWorldHeight(species)
  local scale = 1
  local sizeFn = mod.exports and mod.exports.mountVisualScale or nil
  if type(sizeFn) == "function" then
    local ok, value = pcall(sizeFn, species)
    value = ok and tonumber(value) or nil
    if value and value > 0 then scale = value end
  end
  -- DSR's 2D sizing contract defines a 1.70 m reference mount as one 16 px
  -- overworld card. Matching that exact visual height keeps Stadium and 2D
  -- renderer choices consistent and honours every SIZE <SPECIES> option.
  return 16 * scale, scale
end

local function applyProxyModelScale(posed, ex)
  if not externalStadiumRequested() then
    providerState.lastModelScale = 1
    return
  end
  local Mat4 = providerMat4(ex)
  if not Mat4 then return end

  for _, p in ipairs(posed or {}) do
    if p and p.entity == proxy and p.stadiumMatrix and p.stadiumMon then
      local species = select(2, mountState())
      local wanted = species and desiredModelWorldHeight(species) or nil
      local current = tonumber(p.stadiumTargetHeight)
      if not current and type(p.stadiumMon.worldHeight) == "function" then
        local ok, value = pcall(p.stadiumMon.worldHeight, p.stadiumMon)
        if ok then current = tonumber(value) end
      end
      if wanted and current and current > 0 then
        local factor = wanted / current
        -- The DSR user scale is already clamped. This second guard is only for
        -- malformed third-party model bounds and prevents a bad pack from
        -- exploding to an unusable scene size.
        factor = math.max(0.35, math.min(4.50, factor))
        local okScale, scaled = pcall(function()
          return Mat4.mul(p.stadiumMatrix, Mat4.scale(factor, factor, factor))
        end)
        if okScale and scaled then
          p.stadiumMatrix = scaled
          p.stadiumMon.model_matrix = scaled
          p.stadiumTargetHeight = wanted
          p.dramaticSkyRideModelScale = factor
          providerState.lastModelScale = factor
          providerState.lastModelTargetHeight = wanted
          providerState.lastProviderTargetHeight = current
          providerState.modelScaleFrames = providerState.modelScaleFrames + 1
        end
      end
    end
  end
end

-- VoxelScene gives red_3d_player first refusal for p.isPlayer. While mounted,
-- DSR deliberately owns the rider presentation so a full standing trainer mesh
-- cannot replace the cropped seated rider. The selector resumes immediately on
-- dismount because this wrapper only checks the per-player DSR marker.
local function installPlayerSkinGuard(stadium)
  if not (stadium and type(stadium.safeDrawPlayerSkin) == "function") then return false end
  local marker = stadium._dramaticSkyRidePlayerSkinGuard
  if type(marker) == "table" and marker.owner == mod.id
     and stadium.safeDrawPlayerSkin == marker.wrapper then
    providerHooks.skinRaw = marker.raw
    providerHooks.skinWrapper = marker.wrapper
    return true
  end

  local raw = stadium.safeDrawPlayerSkin
  local wrapper = function(p, ...)
    local entity = p and p.entity or nil
    if type(entity) == "table" and entity._dramaticSkyRideVoxelRider == true then
      return false
    end
    return raw(p, ...)
  end
  stadium.safeDrawPlayerSkin = wrapper
  stadium._dramaticSkyRidePlayerSkinGuard = {
    owner = mod.id, raw = raw, wrapper = wrapper,
  }
  providerHooks.skinRaw = raw
  providerHooks.skinWrapper = wrapper
  return true
end

local function installModelSizeHook(stadium, ex)
  if not (stadium and type(stadium.prepare) == "function") then return false end
  local marker = stadium._dramaticSkyRideMountSizeHook
  if type(marker) == "table" and marker.owner == mod.id
     and stadium.prepare == marker.wrapper then
    providerHooks.prepareRaw = marker.raw
    providerHooks.prepareWrapper = marker.wrapper
    providerMat4(ex)
    return true
  end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    local result = raw(posed, ...)
    if result ~= false then applyProxyModelScale(posed, ex) end
    return result
  end
  stadium.prepare = wrapper
  stadium._dramaticSkyRideMountSizeHook = {
    owner = mod.id, raw = raw, wrapper = wrapper,
  }
  providerHooks.prepareRaw = raw
  providerHooks.prepareWrapper = wrapper
  providerMat4(ex)
  return true
end

local function installProviderHooks()
  local _, ex = providerExports()
  local stadium = ex and ex.overworld or nil
  if type(stadium) ~= "table" then return false end
  providerHooks.stadium = stadium
  installPlayerSkinGuard(stadium)
  installModelSizeHook(stadium, ex)
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() then
    installExtraProvider()
    installProviderHooks()
    if voxelActive() and Game.overworld == self then
      syncNativeMountFollowers(self)
      installRiderPose(self)
    else
      restoreRiderPose()
      restoreSuppressedFollowers()
    end
  else
    restoreRiderPose()
    restoreSuppressedFollowers()
  end
  return result
end

mod.events:on("game.ready", function()
  if isGold() then
    installExtraProvider()
    installProviderHooks()
  end
end)

mod.events:on("mod.options_changed", function()
  -- Renderer/size values are read lazily every compose frame; this event only
  -- refreshes hooks when either mod was hot-loaded after startup.
  if isGold() then
    installExtraProvider()
    installProviderHooks()
  end
end)

mod.exports.gen2VoxelInterop = {
  api = 2,
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
  mountProxyActive = function() return shouldPublishProxy(liveWorld()) end,
  mountSpecies = function() return select(2, mountState()) end,
  mountKind = function() return select(1, mountState()) end,
  riderCropActive = function()
    return riderState.player ~= nil and rawget(riderState.player, "pose") == riderState.wrapper
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
  modelScale = function()
    return providerState.lastModelScale,
      providerState.lastModelTargetHeight,
      providerState.lastProviderTargetHeight
  end,
  status = function()
    return {
      installed = providerState.installed,
      voxelActive = voxelActive(),
      proxyActive = shouldPublishProxy(liveWorld()),
      riderCropActive = riderState.player ~= nil,
      mountKind = select(1, mountState()),
      mountSpecies = select(2, mountState()),
      stadiumRequested = externalStadiumRequested(),
      providerCalls = providerState.providerCalls,
      preservedCalls = providerState.preservedCalls,
      proxyFrames = providerState.proxyFrames,
      filteredMountFollowers = providerState.filteredMountFollowers,
      suppressedMountFollowers = providerState.suppressedMountFollowers,
      riderPoseFrames = providerState.riderPoseFrames,
      modelScaleFrames = providerState.modelScaleFrames,
      modelScale = providerState.lastModelScale,
      modelTargetHeight = providerState.lastModelTargetHeight,
      providerTargetHeight = providerState.lastProviderTargetHeight,
      installs = providerState.installs,
      previousProvider = providerState.previousExtraProvider ~= nil,
      lastError = providerState.lastError,
    }
  end,
}

if installExtraProvider() then
  installProviderHooks()
  log("Gen2 voxel interop loaded (%s + cropped rider + single mount owner + DSR-sized Stadium models)", PROVIDER_ID)
else
  log("Gen2 voxel interop idle; %s not available", PROVIDER_ID)
end
end)();
