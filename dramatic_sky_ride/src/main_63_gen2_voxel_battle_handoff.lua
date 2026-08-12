;(function()
-- -------------------------------------------------------------------------
-- Gen2 mounted-battle handoff + final native follower ownership.
--
-- Dramatic Sky Ride owns traversal, never battle presentation. When Gold starts
-- a battle while a DSR mount is active, remove every DSR-only presentation
-- actor from Randy's voxel cast before the battle snapshot and make Randy's
-- optional LIVE OVERWORLD BATTLES shot yield to the next battle renderer.
-- Battle Art / another render.compose owner / vanilla Gold can then render the
-- fight without inheriting a mounted player, DSR proxy, or frozen rider card.
--
-- This layer also reclaims src.world.gen2.Follower AFTER all mods are loaded.
-- main_61 can install too early depending on mod priority; Randy may replace the
-- callback later. Re-chaining on game.ready and purging the real Game2 World
-- closes the remaining Ho-Oh duplicate path.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}

local state = {
  handoff = false,
  started = false,
  ended = false,
  reason = nil,
  kind = nil,
  species = nil,
  handoffs = 0,
  battleFramesYielded = 0,
  proxyEntitiesFiltered = 0,
  nativeFollowersPurged = 0,
  followerGateReclaims = 0,
  playerPose = nil,
  playerPoseRaw = nil,
  playerPoseWrapper = nil,
  providerExtraRaw = nil,
  providerExtraWrapper = nil,
  providerBridge = nil,
  lastError = nil,
}

local Follower2 = nil
local followerUnderlying = nil
local followerWrapper = nil

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function liveWorld()
  return mod.exports._mountWorld and mod.exports._mountWorld(Game) or nil
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

local function providerExports()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  return ok and handle and handle.exports or nil
end

local function providerBridge()
  local ex = providerExports()
  local bridge = ex and ex.voxelPipelineState or nil
  return type(bridge) == "table" and bridge or nil
end

local function removeFrom(list, entity)
  if type(list) ~= "table" or not entity then return end
  for i = #list, 1, -1 do
    if list[i] == entity then table.remove(list, i) end
  end
end

-- -------------------------------------------------------------------------
-- Final Gold party-follower gate.
-- -------------------------------------------------------------------------
local function ensureFollowerModule()
  if Follower2 then return Follower2 ~= false and Follower2 or nil end
  local ok, value = pcall(require, "src.world.gen2.Follower")
  if ok and type(value) == "table" and type(value.setShouldSpawn) == "function" then
    Follower2 = value
  else
    Follower2 = false
  end
  return Follower2 ~= false and Follower2 or nil
end

local function installFinalFollowerGate()
  local Follower = ensureFollowerModule()
  if not Follower then return false end

  if not followerWrapper then
    followerWrapper = function(game, world)
      if activeMount() then return false end
      if type(followerUnderlying) == "function" then
        local ok, value = pcall(followerUnderlying, game, world)
        return ok and value == true
      end
      return false
    end
  end

  -- setShouldSpawn() is also the only supported getter-like seam: it returns
  -- the previous callback. Reinstall our SAME wrapper after all mods load. If
  -- it was already current, do not point followerUnderlying back at ourselves.
  local previous = Follower.setShouldSpawn(followerWrapper)
  if previous ~= followerWrapper then
    followerUnderlying = previous
    state.followerGateReclaims = state.followerGateReclaims + 1
  end
  return true
end

local function purgeRealNativeFollower()
  local Follower = ensureFollowerModule()
  local world = liveWorld()
  if not (Follower and world and activeMount()) then return end
  local entity = type(Follower.current) == "function" and Follower.current(world) or nil
  if not entity then return end
  removeFrom(world.npcs, entity)
  removeFrom(world.entities, entity)
  if world.follower == entity then world.follower = nil end
  state.nativeFollowersPurged = state.nativeFollowersPurged + 1
end

-- -------------------------------------------------------------------------
-- Battle presentation handoff.
-- -------------------------------------------------------------------------
local function isDsrPresentationEntity(entity)
  if type(entity) ~= "table" then return false end
  return entity.dramaticSkyRideVoxelProxy == true
    or entity.id == "DSR_GEN2_VOXEL_MOUNT"
    or entity.name == "DSR_GEN2_VOXEL_MOUNT"
    or entity.skyRideRider == true
    or entity.groundRideRider == true
    or entity.waterRideRider == true
    or entity.id == "sky_ride_rider"
    or entity.id == "ground_ride_rider"
    or entity.id == "water_ride_rider"
end

local function nativePlayerPose(self)
  local bridge = mod.exports and mod.exports.gen2PlayerBridge or nil
  local sprite
  if bridge and type(bridge.nativePlayerSprite) == "function" then
    local ok, value = pcall(bridge.nativePlayerSprite, self)
    if ok then sprite = value end
  end
  if not sprite then
    local world = liveWorld()
    local def = world and world.sprites and world.sprites.SPRITE_CHRIS or nil
    if def then
      local ok, value = pcall(SpriteRenderer.new, def, "dsr_gen2_battle_handoff_player")
      if ok then sprite = value end
    end
  end
  if not sprite then return nil end
  local phase = 0
  if type(self.walkPhase) == "function" then
    local ok, value = pcall(self.walkPhase, self)
    if ok then phase = tonumber(value) or 0 end
  end
  return sprite, self.px or 0, self.py or 0, self.facing or "down",
    phase, self.stepFlip == true, false
end

local function installPlayerHandoffPose()
  local world = liveWorld()
  local player = world and world.player or nil
  if not player then return false end
  if state.playerPose == player and rawget(player, "pose") == state.playerPoseWrapper then
    return true
  end

  -- Restore an old world/player before capturing the current presentation chain.
  if state.playerPose and rawget(state.playerPose, "pose") == state.playerPoseWrapper then
    rawset(state.playerPose, "pose", state.playerPoseRaw)
  end

  local inherited = player.pose
  if type(inherited) ~= "function" then return false end
  local raw = rawget(player, "pose")
  local wrapper = function(self, ...)
    if state.handoff then
      local sprite, px, py, facing, phase, flip, hopping = nativePlayerPose(self)
      if sprite then return sprite, px, py, facing, phase, flip, hopping end
    end
    return inherited(self, ...)
  end

  state.playerPose = player
  state.playerPoseRaw = raw
  state.playerPoseWrapper = wrapper
  rawset(player, "pose", wrapper)
  return true
end

local function restorePlayerHandoffPose()
  local player = state.playerPose
  if player and rawget(player, "pose") == state.playerPoseWrapper then
    rawset(player, "pose", state.playerPoseRaw)
  end
  state.playerPose = nil
  state.playerPoseRaw = nil
  state.playerPoseWrapper = nil
end

local function installProviderHandoff()
  local bridge = providerBridge()
  if not bridge then return false end

  -- Filter the DSR mount/rider out of Randy's Gold state while a battle is
  -- taking ownership. main_58 remains the underlying provider and resumes
  -- untouched when state.handoff becomes false.
  local marker = bridge._dramaticSkyRideBattleHandoff
  if type(marker) ~= "table" or marker.owner ~= mod.id then
    local rawExtra = bridge.extraEntitiesProvider
    local extraWrapper = function(world)
      local extra = {}
      if type(rawExtra) == "function" then
        local ok, value = pcall(rawExtra, world)
        if ok and type(value) == "table" then extra = value end
      end
      if not state.handoff then return extra end
      local out = {}
      for _, entity in ipairs(extra) do
        if isDsrPresentationEntity(entity) then
          state.proxyEntitiesFiltered = state.proxyEntitiesFiltered + 1
        else
          out[#out + 1] = entity
        end
      end
      return out
    end
    if type(bridge.setExtraEntitiesProvider) == "function" then
      local ok = pcall(bridge.setExtraEntitiesProvider, extraWrapper)
      if ok then
        state.providerExtraRaw = rawExtra
        state.providerExtraWrapper = extraWrapper
      end
    end

    local rawUpdateBattle = bridge.updateBattle
    local rawBattleShot = bridge.battleShot
    local rawBattleStage = bridge.battleStage

    if type(rawUpdateBattle) == "function" then
      bridge.updateBattle = function(...)
        if state.handoff then
          state.battleFramesYielded = state.battleFramesYielded + 1
          return false
        end
        return rawUpdateBattle(...)
      end
    end
    if type(rawBattleShot) == "function" then
      bridge.battleShot = function(...)
        if state.handoff then return nil end
        return rawBattleShot(...)
      end
    end
    if type(rawBattleStage) == "function" then
      bridge.battleStage = function(...)
        if state.handoff then return nil end
        return rawBattleStage(...)
      end
    end

    bridge._dramaticSkyRideBattleHandoff = {
      owner = mod.id,
      extraRaw = rawExtra,
      extraWrapper = extraWrapper,
      updateBattleRaw = rawUpdateBattle,
      battleShotRaw = rawBattleShot,
      battleStageRaw = rawBattleStage,
    }
  else
    state.providerExtraRaw = marker.extraRaw
    state.providerExtraWrapper = marker.extraWrapper
  end

  state.providerBridge = bridge
  return true
end

local function beginHandoff(reason)
  if not isGold() then return false end
  local kind, species = activeMount()
  if not kind and not state.handoff then return false end
  if state.handoff then return true end

  state.handoff = true
  state.started = false
  state.ended = false
  state.reason = reason
  state.kind = kind
  state.species = species
  state.handoffs = state.handoffs + 1
  installPlayerHandoffPose()
  installProviderHandoff()
  return true
end

local function freeRoamReturned()
  local world = liveWorld()
  local fn = mod.exports and mod.exports._mountFreeRoam or nil
  if type(fn) == "function" then
    local ok, value = pcall(fn, Game, world)
    if ok then return value == true end
  end
  local stack = Game and Game.stack
  if stack and type(stack.top) == "function" then
    local ok, top = pcall(stack.top, stack)
    return ok and (top == nil or top == Game.overworld or top == world)
  end
  return false
end

local function finishHandoff()
  state.handoff = false
  state.started = false
  state.ended = false
  state.reason = nil
  state.kind = nil
  state.species = nil
  restorePlayerHandoffPose()
end

-- pushBattle is the earliest common seam. Ground Ride deliberately stops inside
-- its older wrapper before providers snapshot the cast; Flight remains logically
-- active for exact altitude restoration. This outer wrapper suppresses visuals
-- BEFORE either path enters a battle renderer.
local previousPushBattle = OverworldState.pushBattle
if type(previousPushBattle) == "function" then
  function OverworldState:pushBattle(battle, ...)
    if isGold() and Game.overworld == self and activeMount() then
      beginHandoff("pushBattle")
    end
    return previousPushBattle(self, battle, ...)
  end
end

mod.events:on("battle.started", function()
  if state.handoff or activeMount() then
    beginHandoff("battle.started")
    state.started = true
  end
end)

mod.events:on("battle.ended", function()
  if state.handoff then state.ended = true end
end)

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() and Game.overworld == self then
    installFinalFollowerGate()
    installProviderHandoff()
    if activeMount() then purgeRealNativeFollower() end

    -- battle.ended fires before Gold has closed battle/evolution screens. Keep
    -- yielding presentation until the first real free-roam update, after the
    -- existing remount code has had a chance to restore Ground/Surf/Flight.
    if state.handoff and state.ended and freeRoamReturned() then
      finishHandoff()
    elseif state.handoff then
      installPlayerHandoffPose()
    end
  end
  return result
end

-- Reclaim the follower callback after every mod has completed startup. This is
-- intentionally repeated on map entry because some experimental Gen2 providers
-- rebuild their follower integration around a new native World.
mod.events:on("game.ready", function()
  if isGold() then
    installFinalFollowerGate()
    installProviderHandoff()
  end
end)
mod.events:on("map.entered", function()
  if isGold() then
    installFinalFollowerGate()
    if activeMount() then purgeRealNativeFollower() end
  end
end)

mod.exports.gen2VoxelBattleHandoff = {
  api = 1,
  active = function() return state.handoff end,
  status = function()
    return {
      active = state.handoff,
      started = state.started,
      ended = state.ended,
      reason = state.reason,
      mountKind = state.kind,
      mountSpecies = state.species,
      handoffs = state.handoffs,
      battleFramesYielded = state.battleFramesYielded,
      proxyEntitiesFiltered = state.proxyEntitiesFiltered,
      nativeFollowersPurged = state.nativeFollowersPurged,
      followerGateReclaims = state.followerGateReclaims,
      lastError = state.lastError,
    }
  end,
}

installFinalFollowerGate()
installProviderHandoff()
log("Gen2 mounted battle handoff loaded (DSR yields battle visuals; final Gold follower gate active)")
end)();
