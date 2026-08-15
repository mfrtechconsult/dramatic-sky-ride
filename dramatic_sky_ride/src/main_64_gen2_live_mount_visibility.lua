;(function()
-- -------------------------------------------------------------------------
-- Gold live-mount visibility safety net.
--
-- Gold's current runtime owns src.world.gen2.World directly and emits the
-- public world.stepped event. Some older DSR bridges only reconciled the mount
-- from the Gen 1 OverworldController:update path, so Flight/Ground could be
-- active while Gold kept drawing the native trainer. This late bridge makes
-- the live Gold player consume the already-resolved DSR mount SpriteRenderer
-- every step. It does not discover assets itself and stays sandbox-safe.
-- -------------------------------------------------------------------------
local generation = mod.exports and mod.exports.runtimeGeneration or {}
local state = {
  player = nil,
  nativeSprite = nil,
  nativeDef = nil,
  nativeYOffset = nil,
  installed = nil,
  kind = nil,
  species = nil,
  syncs = 0,
}

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function liveWorld()
  local fn = mod.exports and mod.exports._mountWorld or nil
  if type(fn) == "function" then
    local ok, value = pcall(fn, Game)
    if ok then return value end
  end
  return Game and (Game.overworld or Game.world) or nil
end

local function waterMount()
  local ex = mod.exports or {}
  if type(ex.isWaterRiding) ~= "function"
      or type(ex.waterMountSpecies) ~= "function"
      or type(ex._waterRideVisual) ~= "function" then return nil end
  local okActive, active = pcall(ex.isWaterRiding)
  if not (okActive and active == true) then return nil end
  local okSpecies, species = pcall(ex.waterMountSpecies)
  local okSprite, sprite = pcall(ex._waterRideVisual)
  if okSpecies and okSprite and species and sprite then
    return sprite, "water", species
  end
  return nil
end

local function desired()
  if flight and flight.active and flight.sprite then
    return flight.sprite, "flight", flight.species or (flight.mon and flight.mon.species)
  end
  if ground and ground.active and ground.sprite then
    return ground.sprite, "ground", ground.species or (ground.mon and ground.mon.species)
  end
  return waterMount()
end

local function clearPlayerTags(player)
  if not player then return end
  if rawget(player, "_dramaticSkyRideLiveMountOwner") == mod.id then
    player.dramaticSkyRideMountSpecies = nil
    player.skyRideMountSpecies = nil
    player._stadiumSkyRideSpecies = nil
    player._stadiumSkyRideKind = nil
    player._dramaticSkyRideLiveMountOwner = nil
  end
end

local function restore()
  local player = state.player
  if player then
    if player.sprite == state.installed then
      player.sprite = state.nativeSprite
      player.spriteDef = state.nativeDef
    end
    if state.nativeYOffset ~= nil then player.spriteYOffset = state.nativeYOffset end
    clearPlayerTags(player)
  end
  state.player = nil
  state.nativeSprite = nil
  state.nativeDef = nil
  state.nativeYOffset = nil
  state.installed = nil
  state.kind = nil
  state.species = nil
end

local function mountLift(world, kind)
  if kind ~= "flight" or not (flight and flight.active) then return 0 end
  local player = world and world.player or nil
  local floor = 0
  if world and world.map and player and type(terrainGroundHeight) == "function" then
    local ok, value = pcall(terrainGroundHeight,
      world.map, player.cellX, player.cellY)
    if ok then floor = math.max(0, tonumber(value) or 0) end
  end
  return math.max(0, (tonumber(flight.altitude) or 0) - floor)
end

local function sync()
  if not isGold() then
    restore()
    return false
  end
  local world = liveWorld()
  local player = world and world.player or nil
  local sprite, kind, species = desired()
  if not (player and sprite) then
    restore()
    return false
  end

  if state.player ~= player then
    restore()
    state.player = player
    state.nativeSprite = player.sprite
    state.nativeDef = player.spriteDef
    state.nativeYOffset = player.spriteYOffset
  elseif player.sprite ~= state.installed and player.sprite ~= sprite then
    -- Gold can change the underlying native state on shoreline/map transitions.
    state.nativeSprite = player.sprite
    state.nativeDef = player.spriteDef
    state.nativeYOffset = player.spriteYOffset
  end

  local def = sprite.def
  if type(def) == "table" and species then
    def.dramaticSkyRideMountSpecies = species
    def.skyRideMountSpecies = species
  end

  state.installed = sprite
  state.kind = kind
  state.species = species
  state.syncs = state.syncs + 1
  player.sprite = sprite
  if type(def) == "table" then player.spriteDef = def end
  player.spriteYOffset = -math.floor(mountLift(world, kind) + 0.5)

  -- Keep Randy's public Stadium detector aware of the live Gold actor as a
  -- secondary route. main_58's dedicated mount proxy remains the preferred 3D
  -- path; these tags simply prevent the player from being mistaken for an
  -- ordinary trainer if the provider inspects it first.
  if species then
    player.dramaticSkyRideMountSpecies = species
    player.skyRideMountSpecies = species
    player._stadiumSkyRideSpecies = species
    player._stadiumSkyRideKind = kind
    player._dramaticSkyRideLiveMountOwner = mod.id
  end
  return true
end

mod.events:on("world.stepped", sync)
mod.events:on("map.entered", sync)
mod.events:on("game.ready", sync)
mod.events:on("battle.ended", sync)

local previousStartFlight = startFlight
startFlight = function(game, mon)
  local ok = previousStartFlight(game, mon)
  if ok then sync() end
  return ok
end

local previousStartGround = startGroundRide
startGroundRide = function(game, mon)
  local ok = previousStartGround(game, mon)
  if ok then sync() end
  return ok
end

local previousStopFlight = stopFlight
stopFlight = function(...)
  local result = previousStopFlight(...)
  sync()
  return result
end

local previousStopGround = stopGroundRide
stopGroundRide = function(...)
  local result = previousStopGround(...)
  sync()
  return result
end

mod.exports.gen2LiveMountVisibility = {
  api = 1,
  sync = sync,
  status = function()
    return {
      active = state.player ~= nil,
      ownsPlayerSprite = state.player ~= nil and state.player.sprite == state.installed,
      kind = state.kind,
      species = state.species,
      syncs = state.syncs,
      spriteId = state.installed and state.installed.def and state.installed.def.id or nil,
    }
  end,
}

sync()
log("Gold live mount visibility safety net loaded")
end)();
