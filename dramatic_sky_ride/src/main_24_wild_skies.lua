(function()
-- Optional Wild Skies integration.
-- Wild Skies remains an independent mod and owns its flyers, ecology,
-- persistence and rendering. DSR only advertises its airborne state and uses
-- documented Wild Skies exports to consume a flyer for an aerial encounter.

local WILD_SKIES_SOURCE_ID = "dramatic_sky_ride_followers"
local WILDS_MOD_ID = "overworld_wild_spawns"
local WILD_SKIES_INTERCEPT_RADIUS = 1
local DOUBLE_BATTLES_SOURCE_ID = "dramatic_sky_ride_flock"
local FALLBACK_PROVIDER_IDS = {
  "PokePCFollowers_VoxelMerge",
  "pokepcfollowers",
  "FOLLOWERS_EX",
  "followers_ex",
}

local wildSkies = {
  handle = nil,
  take = nil,
  registered = false,
  spriteMode = "native",
  cooldown = 0,
  lastIntercept = nil,
  interceptCount = 0,
  doubleBattlesRegistered = false,
}

local function enabledModHandle(id)
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

local function wildSkiesHandle()
  if wildSkies.handle ~= nil then return wildSkies.handle or nil end
  wildSkies.handle = enabledModHandle("wild_skies") or false
  return wildSkies.handle or nil
end

local function isGen2Runtime(game)
  local runtime = mod.exports.runtimeGeneration
  local check = runtime and runtime.isGen2
  if type(check) ~= "function" then return false end
  local ok, value = pcall(check, game or Game)
  return ok and value == true
end

local function wildsEnabled()
  return enabledModHandle(WILDS_MOD_ID) ~= nil
end

local function fallbackProvider()
  for _, id in ipairs(FALLBACK_PROVIDER_IDS) do
    local handle = enabledModHandle(id)
    local exports = handle and handle.exports
    if exports and type(exports.resolveFollowerSprite) == "function" then
      return id, exports
    end
  end
  return nil
end

-- Gen 1 compatibility only. Wild Skies 1.9 owns the full Gold sprite-source
-- ladder (native Gold, Wilds/HGSS, embedded Wilds/Stadium 2, registered packs),
-- so DSR must not outrank it with follower land art on Gen 2.
local function fallbackAirSprite(game, species, dex)
  local providerId, exports = fallbackProvider()
  if not exports then return nil end
  game = game or Game
  local ok, provided = pcall(exports.resolveFollowerSprite, {
    species = species,
    speciesId = tonumber(dex),
    surface = "land",
    role = "wild_skies_airborne_fallback",
    game = game,
  })
  if not (ok and type(provided) == "table"
      and type(provided.image) == "string") then
    return nil
  end
  local frames = tonumber(provided.frames) or 0
  if frames < 2 then return nil end
  return {
    id = provided.id or ("DSR_WILD_SKIES_" .. tostring(species)),
    image = provided.image,
    frames = frames,
    walker = provided.walker ~= false,
    trueColor = provided.trueColor ~= false,
    providerId = provided.providerId or providerId,
  }
end

local lastSpriteMode = nil
local function setSpriteMode(mode)
  wildSkies.spriteMode = mode
  if mode ~= lastSpriteMode then
    lastSpriteMode = mode
    log("Wild Skies sprite integration: %s", tostring(mode))
  end
end

local function configureWildSkiesSpriteSource()
  local handle = wildSkiesHandle()
  local exports = handle and handle.exports
  if not exports then
    wildSkies.registered = false
    setSpriteMode("wild_skies_unavailable")
    return false
  end

  if type(exports.unregisterSpriteSource) == "function" then
    pcall(exports.unregisterSpriteSource, WILD_SKIES_SOURCE_ID)
  end
  wildSkies.registered = false

  if isGen2Runtime(Game) then
    setSpriteMode("gen2_wild_skies_native")
    return true
  end

  if wildsEnabled() then
    setSpriteMode("gen1_wild_skies_native_wilds")
    return true
  end

  local providerId = fallbackProvider()
  if not providerId then
    setSpriteMode("gen1_wild_skies_native")
    return true
  end

  local register = exports.registerSpriteSource
  if type(register) ~= "function" then
    setSpriteMode("gen1_wild_skies_no_sprite_api")
    return false
  end

  local source = {
    id = WILD_SKIES_SOURCE_ID,
    resolve = function(_, game, species, dex)
      return fallbackAirSprite(game, species, dex)
    end,
  }
  local ok, accepted = pcall(register, source)
  wildSkies.registered = ok and accepted ~= false
  if wildSkies.registered then
    setSpriteMode("gen1_dsr_fallback_" .. tostring(providerId))
  else
    setSpriteMode("gen1_wild_skies_fallback_rejected")
  end
  return wildSkies.registered
end

local function clearWildSkiesAirborneMarker(ow)
  local p = ow and ow.player
  if not (p and p.dramaticSkyRideFreeFlying) then return end
  p.freeFlying = nil
  p.dramaticSkyRideFreeFlying = nil
end

local function syncWildSkiesAirborneMarker(ow)
  local p = ow and ow.player
  if not p then return end
  if flight.active then
    p.freeFlying = true
    p.dramaticSkyRideFreeFlying = true
  else
    clearWildSkiesAirborneMarker(ow)
  end
end

local function wildSkiesTakeFlyer()
  if wildSkies.take ~= nil then return wildSkies.take or nil end
  local handle = wildSkiesHandle()
  local take = handle and handle.exports and handle.exports.takeFlyer
  wildSkies.take = type(take) == "function" and take or false
  return wildSkies.take or nil
end

local function now()
  if love and love.timer and love.timer.getTime then
    return love.timer.getTime()
  end
  return os.clock()
end

local function tagOrganicDoubleBattle()
  local db = enabledModHandle("double_battles")
  local tag = db and db.exports and db.exports.tagOrganic
  if type(tag) == "function" then pcall(tag) end
end

local function configureDoubleBattlesPartnerSource()
  if wildSkies.doubleBattlesRegistered then return true end
  local db = enabledModHandle("double_battles")
  local exports = db and db.exports
  local register = exports and exports.registerPartnerSource
  if type(register) ~= "function" then return false end

  local ok, accepted = pcall(register, {
    id = DOUBLE_BATTLES_SOURCE_ID,
    priority = 40,
    provide = function(game, battle)
      local it = wildSkies.lastIntercept
      if not it or now() - (it.at or 0) > 10 then return nil end
      local enemy = battle and battle.enemy
      if not (enemy and enemy.mon and enemy.mon.species == it.species) then
        return nil
      end
      local skies = wildSkiesHandle()
      local takeFlockmate = skies and skies.exports and skies.exports.takeFlockmate
      if type(takeFlockmate) ~= "function" then return nil end
      local p = game and game.overworld and game.overworld.player
      if not p then return nil end
      local okMate, mate = pcall(takeFlockmate, p.cellX, p.cellY, 8)
      if not (okMate and mate and mate.species) then return nil end
      return mate.species, mate.level
    end,
  })
  wildSkies.doubleBattlesRegistered = ok and accepted ~= false
  return wildSkies.doubleBattlesRegistered
end

local function resetIntegrationHandles()
  wildSkies.handle = nil
  wildSkies.take = nil
  wildSkies.doubleBattlesRegistered = false
  configureWildSkiesSpriteSource()
  configureDoubleBattlesPartnerSource()
end

configureWildSkiesSpriteSource()
configureDoubleBattlesPartnerSource()
mod.events:on("mods.loaded", resetIntegrationHandles)
mod.events:on("game.ready", resetIntegrationHandles)

local function tryWildSkiesIntercept(ow)
  if not (flight.active and flight.phase == "cruise"
      and mod.exports.flightRules.airEncountersEnabled()) then
    return
  end
  local freeRoam = mod.exports and mod.exports._mountFreeRoam
  if type(freeRoam) ~= "function" then return end
  local okRoam, roam = pcall(freeRoam, Game, ow)
  if not okRoam or roam ~= true then return end
  if wildSkies.cooldown > 0 then return end
  local take = wildSkiesTakeFlyer()
  if not take then return end
  local p = ow.player
  if not p then return end
  local ok, hit = pcall(take, p.cellX, p.cellY, WILD_SKIES_INTERCEPT_RADIUS)
  if not (ok and hit and hit.species) then return end

  local level = hit.level or 5
  wildSkies.cooldown = 2
  wildSkies.interceptCount = wildSkies.interceptCount + 1
  wildSkies.lastIntercept = {
    species = hit.species,
    level = level,
    altitude = flight.altitude,
    mount = flight.species,
    at = now(),
  }
  pcall(function() require("src.core.Sound").playCry(Game.data, hit.species) end)
  log("intercepted Wild Skies %s Lv.%s", tostring(hit.species), tostring(level))
  pcall(function()
    mod.events:emit("mod.dramatic_sky_ride.flyer_intercepted", {
      species = hit.species,
      level = level,
      altitude = flight.altitude,
      mount = flight.species,
    })
  end)

  tagOrganicDoubleBattle()
  if mod.world and mod.world.queueScript then
    mod.world:queueScript({
      { "start_battle", "wild", hit.species, level },
    })
  end
end

local wildSkiesUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local frameDt = tonumber(dt) or 1 / 60
  syncWildSkiesAirborneMarker(self)
  local result = wildSkiesUpdate(self, dt, ...)
  syncWildSkiesAirborneMarker(self)
  wildSkies.cooldown = math.max(0, (wildSkies.cooldown or 0) - frameDt)
  if Game.overworld == self then tryWildSkiesIntercept(self) end
  return result
end

if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap("encounter.species", function(next, encounter, ctx)
    if flight.active then return nil end
    return next(encounter, ctx)
  end, 90)
end

mod.events:on("battle.ended", function()
  wildSkies.lastIntercept = nil
end)

mod.exports.altitude = function() return flight.active and flight.altitude or 0 end
mod.exports.mount = function()
  if not (flight.active and flight.mon) then return nil end
  return { species = flight.species or flight.mon.species,
           level = flight.mon.level }
end
mod.exports.wildSkies = {
  installed = function() return wildSkiesHandle() ~= nil end,
  integrationMode = function()
    if not wildSkiesHandle() then return "absent" end
    return isGen2Runtime(Game) and "gen2" or "gen1"
  end,
  isPlayerAdvertisedAirborne = function()
    local ow = Game and Game.overworld
    local p = ow and ow.player
    return p ~= nil and p.dramaticSkyRideFreeFlying == true and p.freeFlying == true
  end,
  lastIntercept = function() return wildSkies.lastIntercept end,
  interceptCount = function() return wildSkies.interceptCount end,
  spriteSourceRegistered = function() return wildSkies.registered == true end,
  spriteIntegrationMode = function() return wildSkies.spriteMode end,
  doubleBattlesPartnerRegistered = function()
    return wildSkies.doubleBattlesRegistered == true
  end,
}

log("Wild Skies Gen1/Gen2 integration loaded")
end)()