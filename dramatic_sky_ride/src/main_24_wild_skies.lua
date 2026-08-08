(function()
-- alpha.16 optional Wild Skies integration.
-- Wild Skies remains an independent mod and owns its flyers. DSR only uses
-- its documented exports: registerSpriteSource() and takeFlyer().
-- Wild Skies does not expose flyer altitude through takeFlyer(), so DSR uses
-- a two-cell interception envelope to make visually near passes forgiving.

local WILD_SKIES_SOURCE_ID = "dramatic_sky_ride_followers"
local WILD_SKIES_INTERCEPT_RADIUS = 2
local wildSkies = { handle = nil, take = nil, registered = false,
                    cooldown = 0, expectedBattle = 0 }

local function wildSkiesHandle()
  if wildSkies.handle ~= nil then return wildSkies.handle or nil end
  if not mod.find then wildSkies.handle = false return nil end
  local ok, handle = pcall(mod.find, mod, "wild_skies")
  wildSkies.handle = ok and handle or false
  return wildSkies.handle or nil
end

-- Generic follower resolver for every Gen 1 species, not just DSR's rideable
-- roster. This lets Pidgey, Spearow, Zubat, etc. use their actual imported
-- follower/overworld art when Wild Skies asks for an in-air sprite.
local function followerAssetForDex(dex)
  dex = tonumber(dex)
  if not dex or not (love and love.filesystem and love.filesystem.getDirectoryItems) then
    return nil
  end
  local filename = string.format("follower_%03d.png", dex)
  local ok, names = pcall(love.filesystem.getDirectoryItems, "mods")
  if ok and type(names) == "table" then
    local fallback = nil
    for _, name in ipairs(names) do
      local root = "mods/" .. name
      local asset = root .. "/assets/sprites/" .. filename
      if fileExists(asset) then
        local raw = love.filesystem.read(root .. "/manifest.json")
        local decoded = raw and Json.decode(raw) or nil
        local id = decoded and decoded.id
        if id and FOLLOWER_IDS[id] then return asset end
        fallback = fallback or asset
      end
    end
    if fallback then return fallback end
  end
  for _, root in ipairs({
    "mods/pokepcfollowers/assets/sprites/",
    "mods/PokePCFollowers/assets/sprites/",
    "mods/PokePCFollowers_VoxelMerge/assets/sprites/",
  }) do
    local asset = root .. filename
    if fileExists(asset) then return asset end
  end
  return nil
end

local function registerWildSkiesSpriteSource()
  local handle = wildSkiesHandle()
  local exports = handle and handle.exports
  local register = exports and exports.registerSpriteSource
  if type(register) ~= "function" then return false end
  local source = {
    id = WILD_SKIES_SOURCE_ID,
    resolve = function(_, game, species, dex)
      game = game or Game
      local def = game and game.data and game.data.pokemon
        and game.data.pokemon[species]
      dex = tonumber(dex) or (def and tonumber(def.dex))
      local path = followerAssetForDex(dex)
      if not path then return nil end
      return {
        id = "DSR_WILD_SKIES_" .. tostring(species),
        image = path,
        frames = 6,
        walker = true,
        trueColor = true,
      }
    end,
  }
  local ok, accepted = pcall(register, source)
  wildSkies.registered = ok and accepted ~= false
  if wildSkies.registered then
    log("Wild Skies sprite source registered")
  end
  return wildSkies.registered
end

registerWildSkiesSpriteSource()
mod.events:on("game.ready", function()
  wildSkies.handle = nil
  registerWildSkiesSpriteSource()
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
}

log("alpha.16 optional Wild Skies integration loaded")
end)()
