(function()
-- alpha.16 optional Wild Skies integration.
-- Wild Skies remains an independent mod and owns its flyers. DSR only uses
-- documented Wild Skies exports for sprite-source fallback and flyer consume.
-- When Wilds of Kanto is enabled, Wild Skies' own native Wilds adapter is
-- authoritative for airborne species art; DSR does not override it.

local WILD_SKIES_SOURCE_ID = "dramatic_sky_ride_followers"
local WILDS_MOD_ID = "overworld_wild_spawns"
local WILD_SKIES_INTERCEPT_RADIUS = 2
local FALLBACK_PROVIDER_IDS = {
  "PokePCFollowers_VoxelMerge",
  "pokepcfollowers",
  "FOLLOWERS_EX",
  "followers_ex",
}

local wildSkies = { handle = nil, take = nil, registered = false,
                    spriteMode = "native", cooldown = 0, expectedBattle = 0 }

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

-- DSR's Wild Skies sprite source is deliberately only a fallback for setups
-- without Wilds of Kanto. It consumes the enabled provider's public export and
-- never scans the mods directory, so a disabled/stale install cannot influence
-- Wild Skies rendering.
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

  -- Hot reloads and old DSR builds can leave our source registered. Remove it
  -- first so Wild Skies' own built-in sources regain their normal priority.
  if type(exports.unregisterSpriteSource) == "function" then
    pcall(exports.unregisterSpriteSource, WILD_SKIES_SOURCE_ID)
  end
  wildSkies.registered = false

  -- Preferred path: Wild Skies already has a first-class Wilds of Kanto
  -- adapter that resolves the style-independent levitates registry and strips
  -- the water splash. Do not duplicate or outrank that integration in DSR.
  if wildsEnabled() then
    setSpriteMode("wild_skies_native_wilds")
    return true
  end

  -- Without Wilds, retain species-specific art when a compatible follower
  -- provider is actually enabled. This is intentionally secondary to Wild
  -- Skies' own source chain and disappears as soon as Wilds becomes available.
  local providerId = fallbackProvider()
  if not providerId then
    setSpriteMode("wild_skies_native_generic")
    return true
  end

  local register = exports.registerSpriteSource
  if type(register) ~= "function" then
    setSpriteMode("wild_skies_no_sprite_api")
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
    setSpriteMode("dsr_fallback_" .. tostring(providerId))
  else
    setSpriteMode("wild_skies_fallback_rejected")
  end
  return wildSkies.registered
end

configureWildSkiesSpriteSource()
mod.events:on("mods.loaded", function()
  wildSkies.handle = nil
  wildSkies.take = nil
  configureWildSkiesSpriteSource()
end)
mod.events:on("game.ready", function()
  wildSkies.handle = nil
  wildSkies.take = nil
  configureWildSkiesSpriteSource()
end)

local function syncWildSkiesAirborneMarker(ow)
  local p = ow and ow.player
  if not p then return end
  if flight.active then
    p.freeFlying = true
    p.dramaticSkyRideFreeFlying = true
  elseif p.dramaticSkyRideFreeFlying then
    p.freeFlying = nil
    p.dramaticSkyRideFreeFlying = nil
  end
end

local function wildSkiesTakeFlyer()
  if wildSkies.take ~= nil then return wildSkies.take or nil end
  local handle = wildSkiesHandle()
  local take = handle and handle.exports and handle.exports.takeFlyer
  wildSkies.take = type(take) == "function" and take or false
  return wildSkies.take or nil
end

local function tryWildSkiesIntercept(ow)
  if not (flight.active and flight.phase == "cruise" and mod.exports.flightRules.airEncountersEnabled()) then
    return
  end
  if not (Game.stack and Game.stack:top() == ow) then return end
  if wildSkies.cooldown > 0 or wildSkies.expectedBattle > 0 then return end
  local take = wildSkiesTakeFlyer()
  if not take then return end
  local p = ow.player
  if not p then return end
  local ok, hit = pcall(take, p.cellX, p.cellY, WILD_SKIES_INTERCEPT_RADIUS)
  if not (ok and hit and hit.species) then return end

  wildSkies.cooldown = 2
  wildSkies.expectedBattle = 4
  pcall(function() require("src.core.Sound").playCry(Game.data, hit.species) end)
  log("intercepted Wild Skies %s Lv.%s", tostring(hit.species), tostring(hit.level or 5))
  pcall(function()
    mod.events:emit("mod.dramatic_sky_ride.flyer_intercepted", {
      species = hit.species,
      level = hit.level or 5,
      altitude = flight.altitude,
      mount = flight.species,
    })
  end)
  if mod.world and mod.world.queueScript then
    mod.world:queueScript({
      { "start_battle", "wild", hit.species, hit.level or 5 },
    })
  end
end

-- Wild Skies currently recognises Free Fly's export or the legacy
-- player.freeFlying marker. Because DSR and free_fly are declared conflicting
-- flight engines, stamping that marker is safe and gives Wild Skies the exact
-- airborne/grounded answer it needs without reaching into its internals.
local wildSkiesUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local frameDt = tonumber(dt) or 1 / 60
  syncWildSkiesAirborneMarker(self)
  local result = wildSkiesUpdate(self, dt, ...)
  syncWildSkiesAirborneMarker(self)
  wildSkies.cooldown = math.max(0, (wildSkies.cooldown or 0) - frameDt)
  wildSkies.expectedBattle = math.max(0, (wildSkies.expectedBattle or 0) - frameDt)
  if Game.overworld == self then tryWildSkiesIntercept(self) end
  return result
end

-- Other overworld encounter mods can start BattleState.newWild directly from
-- entity collision. While DSR is airborne those are ground encounters and are
-- suppressed; only the Wild Skies battle DSR just queued is allowed through.
local okBattleState, BattleState = pcall(require, "src.battle.BattleState")
if okBattleState and BattleState and not BattleState.dramaticSkyRideAirGateWrapped then
  local nativeNewWild = BattleState.newWild
  if type(nativeNewWild) == "function" then
    BattleState.newWild = function(...)
      if flight.active and (wildSkies.expectedBattle or 0) <= 0 then return nil end
      return nativeNewWild(...)
    end
  end
  BattleState.dramaticSkyRideAirGateWrapped = true
end

mod.events:on("battle.started", function()
  wildSkies.expectedBattle = 0
end)

-- Stable inter-mod surface matching the shape Shane already uses for Free Fly.
mod.exports.altitude = function() return flight.active and flight.altitude or 0 end
mod.exports.mount = function()
  if not (flight.active and flight.mon) then return nil end
  return { species = flight.species or flight.mon.species,
           level = flight.mon.level }
end
mod.exports.wildSkies = {
  installed = function() return wildSkiesHandle() ~= nil end,
  spriteSourceRegistered = function() return wildSkies.registered == true end,
  spriteIntegrationMode = function() return wildSkies.spriteMode end,
}

log("alpha.16 optional Wild Skies integration loaded")
end)()