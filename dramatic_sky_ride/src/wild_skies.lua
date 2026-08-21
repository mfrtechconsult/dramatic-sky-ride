local mod = ...

local WildSkies = {}
local runtime, compat, sprites
local SOURCE_ID = "dramatic_sky_ride_fallback"
local registered = false

local function handle()
  return compat and compat.find("wild_skies") or nil
end

local function syncAirborne()
  local p = compat and compat.player()
  if not p then return end
  local flying = runtime and runtime.public.isFlying()
  if flying then
    p.freeFlying = true
    p.dramaticSkyRideFreeFlying = true
  elseif p.dramaticSkyRideFreeFlying then
    p.freeFlying = nil
    p.dramaticSkyRideFreeFlying = nil
  end
end

local function registerFallback()
  local h = handle()
  local ex = h and h.exports
  if not ex then return false end
  if type(ex.unregisterSpriteSource) == "function" then pcall(ex.unregisterSpriteSource, SOURCE_ID) end
  if type(ex.registerSpriteSource) ~= "function" then return false end
  local ok, accepted = pcall(ex.registerSpriteSource, {
    id = SOURCE_ID,
    resolve = function(_, game, species, dex)
      local def = sprites.resolve(game, species, dex, "flight")
      if def and def.providerId ~= "wild_skies" then return def end
      return nil
    end,
  })
  registered = ok and accepted ~= false
  return registered
end

function WildSkies.install(deps)
  runtime, compat, sprites = deps.runtime, deps.compat, deps.sprites
  mod.events:on("mods.loaded", function() registerFallback(); syncAirborne() end)
  mod.events:on("game.ready", function() registerFallback(); syncAirborne() end)
  mod.hooks:wrap("core.update", function(nextFn, game, dt)
    nextFn(game, dt)
    syncAirborne()
  end, 910)
end

function WildSkies.status()
  local h = handle()
  local ex = h and h.exports
  return { active=h ~= nil, version=ex and ex.version or nil, spriteSourceRegistered=registered,
    takeFlyer=ex and type(ex.takeFlyer)=="function" or false,
    sharedSky=ex and type(ex.sharedSkyFieldSnapshot)=="function" or false }
end

return WildSkies
