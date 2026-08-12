;(function()
-- -------------------------------------------------------------------------
-- Gen2 voxel visual regression fixes.
--
-- This late layer deliberately stays presentation-only. It fixes three Gold
-- interoperability cases observed with STADIUM2_OVERWORLD_MODELS:
--   * the engine party follower can still render a second 3D copy of the mount;
--   * taking off from the bicycle can bake SPRITE_BIKE into the rider crop;
--   * Gold data packs do not always expose dexEntry heights, leaving large
--     mounts at the 1.70 m fallback size even though Randy ships canonical
--     Gen1+Gen2 heights.
--
-- The existing main_58 proxy remains the single DSR mount actor. 2D mount mode
-- still publishes that proxy as an explicitly opted-out billboard, while
-- Stadium mode lets Randy replace exactly that proxy with a model.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}

local visualFix = {
  follower = nil,
  followerPoseRaw = nil,
  followerPoseWrapper = nil,
  followerOldStadium = nil,
  followerOldPokemon = nil,
  followerSuppressions = 0,
  riderRepairs = 0,
  heightFallbacks = 0,
  lastFollowerSpecies = nil,
  lastHeightSpecies = nil,
  lastHeightMeters = nil,
}

-- Canonical heights used by Randy's PokemonHeights.lua, limited to the DSR
-- mount roster. Keeping the small table here avoids reaching into another
-- mod's private loader while making 2D and Stadium sizing deterministic.
local MOUNT_HEIGHT_METERS = {
  -- Flight Gen 1
  CHARIZARD = 1.7, PIDGEOT = 1.5, FEAROW = 1.2, GOLBAT = 1.6,
  AERODACTYL = 1.8, ARTICUNO = 1.7, ZAPDOS = 1.6, MOLTRES = 2.0,
  DRAGONAIR = 4.0, DRAGONITE = 2.2,
  -- Ground Gen 1
  ARCANINE = 1.9, RAPIDASH = 1.7, DODRIO = 1.8, RHYHORN = 1.0,
  RHYDON = 1.9, KANGASKHAN = 2.2, TAUROS = 1.4, SNORLAX = 2.1,
  -- Visible Surf Gen 1
  BLASTOISE = 1.6, TENTACRUEL = 1.6, GYARADOS = 6.5, LAPRAS = 2.5,
  -- Flight Gen 2
  NOCTOWL = 1.6, CROBAT = 1.8, XATU = 1.5, SKARMORY = 1.7,
  LUGIA = 5.2, HO_OH = 3.8,
  -- Ground Gen 2
  MEGANIUM = 1.8, GIRAFARIG = 1.5, URSARING = 1.8, DONPHAN = 1.1,
  STANTLER = 1.4, RAIKOU = 1.9, ENTEI = 2.1, SUICUNE = 2.0,
  TYRANITAR = 2.0,
  -- Visible Surf Gen 2
  FERALIGATR = 2.3, MANTINE = 2.1, KINGDRA = 1.8,
}

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

local function voxelActive()
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

local function gen2StadiumMountMode()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    return ok and value == true
  end
  return false
end

local function providerFirstPerson()
  local ex = providerExports()
  if ex and type(ex.voxelCameraMode) == "function" then
    local ok, mode = pcall(ex.voxelCameraMode)
    return ok and tostring(mode):lower() == "first"
  end
  return false
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

local function cleanSpecies(value)
  if type(value) == "table" then value = value.species end
  if value == nil then return nil end
  local s = tostring(value):upper():gsub("[^A-Z0-9]", "")
  return s ~= "" and s or nil
end

-- -------------------------------------------------------------------------
-- Size fallback: Gold data can omit dexEntry.heightFt/heightIn. main_21 then
-- returns scale 1 even for Gyarados/Lugia/Ho-Oh. Supply the same canonical
-- values Randy uses and keep DSR's existing 50..200% user control.
-- -------------------------------------------------------------------------
local rawHeightMeters = mod.exports.mountPokedexHeightMeters
local rawMountVisualScale = mod.exports.mountVisualScale

local function canonicalHeight(species)
  local key = cleanSpecies(species)
  if not key then return nil end
  return MOUNT_HEIGHT_METERS[key]
end

if type(rawHeightMeters) == "function" and type(rawMountVisualScale) == "function"
   and not mod.exports._gen2VoxelCanonicalHeightFix then
  mod.exports.mountPokedexHeightMeters = function(species)
    local ok, meters = pcall(rawHeightMeters, species)
    meters = ok and tonumber(meters) or nil
    if meters and meters > 0 then return meters end
    meters = canonicalHeight(species)
    if meters then
      visualFix.heightFallbacks = visualFix.heightFallbacks + 1
      visualFix.lastHeightSpecies = species
      visualFix.lastHeightMeters = meters
    end
    return meters
  end

  mod.exports.mountVisualScale = function(species)
    local okHeight, originalMeters = pcall(rawHeightMeters, species)
    originalMeters = okHeight and tonumber(originalMeters) or nil
    if originalMeters and originalMeters > 0 then
      local okScale, scale = pcall(rawMountVisualScale, species)
      if okScale and tonumber(scale) and tonumber(scale) > 0 then return tonumber(scale) end
    end

    local meters = canonicalHeight(species)
    if not meters then
      local okScale, scale = pcall(rawMountVisualScale, species)
      return okScale and tonumber(scale) or 1
    end

    local percent = tonumber(optionValue("mount_size_" .. tostring(species):lower(), 100)) or 100
    percent = clamp(percent, 50, 200)
    if optionValue("pokedex_mount_sizes", true) ~= true then
      return percent / 100
    end
    local canonical = clamp(meters / 1.70, 0.50, 4.00)
    return canonical * percent / 100
  end

  mod.exports._gen2VoxelCanonicalHeightFix = true
end

-- -------------------------------------------------------------------------
-- Rider source repair. Taking off from Gold's bicycle used to crop the active
-- SPRITE_BIKE sheet, which visually put the whole bicycle above Ho-Oh. Always
-- source mounted riders from palette-correct SPRITE_CHRIS when the live native
-- state is a vehicle/surf sheet.
-- -------------------------------------------------------------------------
local rawRiderSource = mod.exports._riderSourceSprite
local function riderSourceIsVehicle(sprite)
  local id = sprite and sprite.def and tostring(sprite.def.id or ""):upper() or ""
  return id:find("BIKE", 1, true) ~= nil
      or id:find("SURF", 1, true) ~= nil
      or id:find("SKATE", 1, true) ~= nil
end

local function normalGoldRiderSource(player)
  local world = liveWorld()
  local normalDef = world and world.sprites and world.sprites.SPRITE_CHRIS or nil
  if not normalDef then return nil end
  local holder = {
    spriteDef = normalDef,
    sprite = SpriteRenderer.new(normalDef, "dsr_gen2_voxel_rider_source"),
  }
  if type(world.applySpritePalette) == "function" then
    pcall(world.applySpritePalette, world, holder)
  elseif player and player.sprite and player.sprite.objColors
     and type(holder.sprite.setObjPalette) == "function" then
    holder.sprite:setObjPalette(player.sprite.objColors, player.sprite.objGroup)
  end
  return holder.sprite
end

if type(rawRiderSource) == "function" and not mod.exports._gen2VoxelRiderSourceFix then
  mod.exports._riderSourceSprite = function(player)
    local sprite = rawRiderSource(player)
    if isGold() and riderSourceIsVehicle(sprite) then
      return normalGoldRiderSource(player) or sprite
    end
    return sprite
  end
  mod.exports._gen2VoxelRiderSourceFix = true
end

local function currentRiderLooksWrong(sprite)
  local id = sprite and sprite.def and tostring(sprite.def.id or ""):upper() or ""
  return id:find("BIKE", 1, true) ~= nil
      or id:find("SURF", 1, true) ~= nil
      or id:find("SKATE", 1, true) ~= nil
end

local function repairLiveRider(world)
  if not (isGold() and world and world.player and type(buildRiderSprite) == "function") then return end
  if flight and flight.active and currentRiderLooksWrong(flight.riderSprite) then
    local sprite = buildRiderSprite(world.player)
    if sprite then
      flight.riderSprite = sprite
      if flight.riderEntity then flight.riderEntity.sprite = sprite end
      visualFix.riderRepairs = visualFix.riderRepairs + 1
    end
  end
  if ground and ground.active and currentRiderLooksWrong(ground.riderSprite) then
    local sprite = buildRiderSprite(world.player)
    if sprite then
      ground.riderSprite = sprite
      visualFix.riderRepairs = visualFix.riderRepairs + 1
    end
  end
end

-- -------------------------------------------------------------------------
-- Native Gold party follower suppression. Randy enables src.world.gen2.Follower
-- for party slot #1 and GoldVoxelBridge merges world.npcs directly BEFORE the
-- extra-entity provider. main_58 can therefore miss it for one ordering shape.
-- Resolve Follower.current(world) explicitly and use party slot #1 as the
-- identity fallback when the provider has not tagged the NPC yet.
-- -------------------------------------------------------------------------
local Follower2 = nil
local function nativeFollower(world)
  if not Follower2 then
    local ok, value = pcall(require, "src.world.gen2.Follower")
    if ok and type(value) == "table" then Follower2 = value else Follower2 = false end
  end
  if not Follower2 or type(Follower2.current) ~= "function" then return nil end
  local ok, entity = pcall(Follower2.current, world)
  return ok and entity or nil
end

local function followerSpecies(entity, world)
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

  -- GoldPartyFollower writes metadata during its own update. If DSR is the
  -- outer updater this can be the first frame before those fields exist.
  if entity == nativeFollower(world) then
    local party = Game.save and Game.save.party or nil
    local lead = type(party) == "table" and party[1] or nil
    return cleanSpecies(type(lead) == "table" and lead.species or lead)
  end
  return nil
end

local function followerMatchesMount(entity, world)
  if type(entity) ~= "table" then return false end
  local _, species = activeMount()
  local mount = cleanSpecies(species)
  if not mount then return false end
  local looksFollower = entity == nativeFollower(world)
    or entity.wildsFollower == true
    or entity.pikachuFollower == true
    or entity._wildsFollowerSpecies ~= nil
    or entity._pokepcFollowerSpecies ~= nil
    or entity.pokepcFollowerSpecies ~= nil
    or entity.pokepcMon ~= nil
    or entity.followerSpecies ~= nil
  return looksFollower and followerSpecies(entity, world) == mount
end

local function restoreFollowerSuppression()
  local entity = visualFix.follower
  if not entity then return end
  if rawget(entity, "pose") == visualFix.followerPoseWrapper then
    rawset(entity, "pose", visualFix.followerPoseRaw)
  end
  entity.stadiumModel = visualFix.followerOldStadium
  entity.pokemonModel = visualFix.followerOldPokemon
  visualFix.follower = nil
  visualFix.followerPoseRaw = nil
  visualFix.followerPoseWrapper = nil
  visualFix.followerOldStadium = nil
  visualFix.followerOldPokemon = nil
end

local function suppressNativeFollower(world)
  local entity = nativeFollower(world)
  if not (voxelActive() and followerMatchesMount(entity, world)) then
    restoreFollowerSuppression()
    return
  end
  if visualFix.follower == entity and rawget(entity, "pose") == visualFix.followerPoseWrapper then
    entity.stadiumModel = false
    entity.pokemonModel = false
    return
  end

  restoreFollowerSuppression()
  local inheritedPose = entity.pose
  if type(inheritedPose) ~= "function" then return end
  local rawPose = rawget(entity, "pose")
  local wrapper = function(self, ...)
    local live = liveWorld()
    if voxelActive() and followerMatchesMount(self, live) then
      return nil, self.px or 0, self.py or 0, self.facing or "down", 0,
        self.stepFlip == true, false
    end
    return inheritedPose(self, ...)
  end

  visualFix.follower = entity
  visualFix.followerPoseRaw = rawPose
  visualFix.followerPoseWrapper = wrapper
  visualFix.followerOldStadium = entity.stadiumModel
  visualFix.followerOldPokemon = entity.pokemonModel
  rawset(entity, "pose", wrapper)
  entity.stadiumModel = false
  entity.pokemonModel = false
  visualFix.followerSuppressions = visualFix.followerSuppressions + 1
  visualFix.lastFollowerSpecies = followerSpecies(entity, world)
end

-- -------------------------------------------------------------------------
-- Stadium rider seat. The 2D rider offsets are authored against a 16px card;
-- Randy's _stadiumSkyRideMount transform instead defines the trainer's feet at
-- mountLift + 7 world px. Use that contract only for the external Stadium 2
-- renderer. 2D mode keeps the mature DSR rider composition unchanged.
-- -------------------------------------------------------------------------
local STADIUM_RIDER_FOOT_LIFT = {
  LUGIA = 8.0,
  HO_OH = 7.5,
  GYARADOS = 7.0,
  LAPRAS = 7.0,
  MANTINE = 6.5,
  SUICUNE = 7.0,
  RAIKOU = 7.0,
  ENTEI = 7.2,
  TYRANITAR = 8.0,
}

local function stadiumRiderPose(sprite, kind, facing, phase, flip, hopping)
  local world = liveWorld()
  local player = world and world.player or nil
  local _, species = activeMount()
  if not (player and sprite and species) then return nil end
  if providerFirstPerson() then return nil end

  local lift = 0
  if kind == "flight" and flight and flight.active then
    local groundHeight = terrainGroundHeight(world.map, player.cellX, player.cellY)
    lift = math.max(0, (tonumber(flight.altitude) or 0) - (tonumber(groundHeight) or 0))
  end
  local seat = STADIUM_RIDER_FOOT_LIFT[cleanSpecies(species)] or 7.0
  return sprite, player.px, player.py - lift - seat,
    facing or player.facing, phase or 0, flip == true, hopping == true
end

local rawFlightRiderPose = riderPose
if type(rawFlightRiderPose) == "function" and not mod.exports._gen2VoxelFlightSeatFix then
  riderPose = function(entity)
    local sprite, px, py, facing, phase, flip, hopping = rawFlightRiderPose(entity)
    if isGold() and gen2StadiumMountMode() and flight and flight.active then
      local a, b, c, d, e, f, g = stadiumRiderPose(
        sprite or flight.riderSprite, "flight", facing, phase, flip, hopping)
      if a then return a, b, c, d, e, f, g end
      if providerFirstPerson() then return nil, px, py, facing, phase, flip, hopping end
    end
    return sprite, px, py, facing, phase, flip, hopping
  end
  mod.exports._gen2VoxelFlightSeatFix = true
end

local rawGroundRiderPose = groundRiderPose
if type(rawGroundRiderPose) == "function" and not mod.exports._gen2VoxelGroundSeatFix then
  groundRiderPose = function(entity)
    local sprite, px, py, facing, phase, flip, hopping = rawGroundRiderPose(entity)
    if isGold() and gen2StadiumMountMode() and ground and ground.active then
      local a, b, c, d, e, f, g = stadiumRiderPose(
        sprite or ground.riderSprite, "ground", facing, phase, flip, hopping)
      if a then return a, b, c, d, e, f, g end
      if providerFirstPerson() then return nil, px, py, facing, phase, flip, hopping end
    end
    return sprite, px, py, facing, phase, flip, hopping
  end
  mod.exports._gen2VoxelGroundSeatFix = true
end

local rawWaterRiderPose = mod.exports._waterRideRiderPose
if type(rawWaterRiderPose) == "function" and not mod.exports._gen2VoxelWaterSeatFix then
  mod.exports._waterRideRiderPose = function(entity)
    local sprite, px, py, facing, phase, flip, hopping = rawWaterRiderPose(entity)
    if isGold() and gen2StadiumMountMode() then
      local a, b, c, d, e, f, g = stadiumRiderPose(
        sprite, "water", facing, phase, flip, hopping)
      if a then return a, b, c, d, e, f, g end
      if providerFirstPerson() then return nil, px, py, facing, phase, flip, hopping end
    end
    return sprite, px, py, facing, phase, flip, hopping
  end
  mod.exports._gen2VoxelWaterSeatFix = true
end

-- Late outer tick: main_58 has already reconciled its proxy/rider hooks. Repair
-- the native rider source and then suppress the exact engine follower that can
-- bypass the extra-entity provider composition.
local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() and Game.overworld == self then
    repairLiveRider(self)
    suppressNativeFollower(self)
  else
    restoreFollowerSuppression()
  end
  return result
end

mod.events:on("map.entered", function()
  restoreFollowerSuppression()
end)

mod.exports.gen2VoxelVisualFixes = {
  api = 1,
  canonicalHeight = canonicalHeight,
  status = function()
    local _, species = activeMount()
    return {
      voxelActive = voxelActive(),
      stadiumMountMode = gen2StadiumMountMode(),
      mountSpecies = species,
      followerSuppressed = visualFix.follower ~= nil,
      followerSuppressions = visualFix.followerSuppressions,
      lastFollowerSpecies = visualFix.lastFollowerSpecies,
      riderRepairs = visualFix.riderRepairs,
      heightFallbacks = visualFix.heightFallbacks,
      lastHeightSpecies = visualFix.lastHeightSpecies,
      lastHeightMeters = visualFix.lastHeightMeters,
      mountScale = species and mod.exports.mountVisualScale
        and mod.exports.mountVisualScale(species) or nil,
    }
  end,
}

log("Gen2 voxel visual fixes loaded (native follower ownership, clean rider source, canonical mount sizes)")
end)();
