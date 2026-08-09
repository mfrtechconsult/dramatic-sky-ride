
-- -------------------------------------------------------------------------
-- Capability-based follower / sprite compatibility.
--
-- Wilds of Kanto owns its own follower runtime and can also expose the active
-- sprite style. Keep those two concerns separate: use one authoritative
-- follower runtime, but allow any compatible public sprite provider to feed
-- the Sky Ride mount.
-- -------------------------------------------------------------------------
local WILDS_MOD_ID = "overworld_wild_spawns"
local SPRITE_PROVIDER_IDS = {
  WILDS_MOD_ID,
  "PokePCFollowers_VoxelMerge",
  "pokepcfollowers",
  "FOLLOWERS_EX",
  "followers_ex",
}

local function compatExports(id)
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle and handle.exports or nil
end

local function usableProviderMount(id, ex, species, style)
  local opts = {
    species = species,
    surface = "land",
    role = "mount",
    game = Game,
  }
  if style then opts.style = style end

  local okDef, provided = pcall(ex.resolveFollowerSprite, opts)
  local frames = provided and tonumber(provided.frames) or 0
  if not (okDef and provided and provided.image and frames >= 6) then return nil end

  local okImage, image = pcall(Assets.image, provided.image)
  if not (okImage and image) then return nil end
  setNearest(image)
  local width, height = image:getDimensions()
  if width < 16 or height < 96 then return nil end

  local def = {
    id = "SKY_RIDE_" .. species,
    image = provided.image,
    frames = 6,
    walker = true,
    trueColor = provided.trueColor ~= false,
    skyRideSpriteProvider = provided.providerId or id,
  }
  local sprite = SpriteRenderer.new(def, "sky_ride_" .. species)
  sprite.image = image
  return sprite, provided.providerId or id
end

local function buildProviderMountSprite(species)
  for _, id in ipairs(SPRITE_PROVIDER_IDS) do
    local ex = compatExports(id)
    if ex and type(ex.resolveFollowerSprite) == "function" then
      -- Prefer the provider's active style. Wilds' Pokédex style can be a
      -- static front sprite rather than a 6-frame walker; in that one case,
      -- retry Wilds' built-in follower/GSC style so Wilds-only installs still
      -- have a rideable mount without requiring PokéPC.
      local sprite, provider = usableProviderMount(id, ex, species, nil)
      if sprite then return sprite, nil, provider end
      if id == WILDS_MOD_ID then
        sprite, provider = usableProviderMount(id, ex, species, "followers")
        if sprite then return sprite, nil, provider end
      end
    end
  end
  return nil
end

local legacyBuildMountSprite = buildMountSprite
local lastCompatSpriteProvider = nil
buildMountSprite = function(species)
  local sprite, reason, provider = buildProviderMountSprite(species)
  if sprite then
    if provider ~= lastCompatSpriteProvider then
      log("Mount sprite provider: %s", tostring(provider))
      lastCompatSpriteProvider = provider
    end
    return sprite
  end
  return legacyBuildMountSprite(species)
end

-- Wilds is authoritative when installed: asking PokéPC / Followers EX to sync
-- after Wilds would create competing lifecycle owners. A successful Wilds
-- sync is authoritative even when the configured follower count is zero.
local legacySyncFollowerMods = syncFollowerMods
syncFollowerMods = function(ow)
  local wilds = compatExports(WILDS_MOD_ID)
  if wilds and type(wilds.syncAll) == "function" then
    local ok, err = pcall(wilds.syncAll, Game, ow)
    if not ok then
      log("Wilds follower sync failed: %s", tostring(err))
      return false
    end
    return true
  end
  return legacySyncFollowerMods(ow)
end

-- -------------------------------------------------------------------------
-- Cooperative update-hook guard.
--
-- Some follower runtimes restore OverworldController.update to a previously
-- captured function after all mods have loaded. Sky Ride's existing update
-- wrapper is intentionally left unchanged. We instrument its `update`
-- upvalue with a heartbeat; if a real LOGIC STEP runs while flying and that
-- heartbeat is absent, the wrapper is no longer anywhere in the active chain.
-- Only then do we retarget it around the CURRENT handler. We never restore an
-- old global function, so healthy wrappers from Battle Art, Dramaless, Wilds,
-- or unrelated mods remain composed.
-- -------------------------------------------------------------------------
local skyRideCoreUpdate = OverworldState.update
local skyRideUpdateHeartbeat = 0
local skyRideHookRecoveries = 0
local skyRideUpdateUpvalue = nil

local function findUpdateUpvalue(fn)
  if type(fn) ~= "function" or not (debug and debug.getupvalue and debug.setupvalue) then
    return nil, nil
  end
  local index = 1
  while true do
    local name, value = debug.getupvalue(fn, index)
    if not name then return nil, nil end
    if name == "update" and type(value) == "function" then
      return index, value
    end
    index = index + 1
  end
end

local function bindSkyRideNext(nextUpdate)
  if type(nextUpdate) ~= "function" then return false end
  if not skyRideUpdateUpvalue then
    skyRideUpdateUpvalue = select(1, findUpdateUpvalue(skyRideCoreUpdate))
  end
  if not skyRideUpdateUpvalue then return false end

  local function heartbeatNext(self, dt, ...)
    skyRideUpdateHeartbeat = skyRideUpdateHeartbeat + 1
    return nextUpdate(self, dt, ...)
  end
  debug.setupvalue(skyRideCoreUpdate, skyRideUpdateUpvalue, heartbeatNext)
  return true
end

local _, initialSkyRideNext = findUpdateUpvalue(skyRideCoreUpdate)
local skyRideGuardReady = initialSkyRideNext and bindSkyRideNext(initialSkyRideNext) or false

local function recoverSkyRideUpdate(reason)
  if not skyRideGuardReady then return false end
  local current = OverworldState.update
  if current == skyRideCoreUpdate then return true end
  if type(current) ~= "function" then return false end
  if not bindSkyRideNext(current) then return false end
  OverworldState.update = skyRideCoreUpdate
  skyRideHookRecoveries = skyRideHookRecoveries + 1
  log("Flight update hook was displaced; reattached around current handler (%s)",
      tostring(reason or "heartbeat"))
  return true
end

-- Game.step is the fixed logic boundary. Using Game.update here would be
-- unsafe because a high-refresh display can render a frame without executing
-- a fixed step, which would look like a missing heartbeat even when the hook
-- chain is healthy.
local gameStepBeforeCompat = Game.step
if skyRideGuardReady and type(gameStepBeforeCompat) == "function" then
  local function gameStepCompatGuard(...)
    local owBefore = Game.overworld
    local stackBefore = Game.stack
    local topBefore = stackBefore and stackBefore.top and stackBefore:top() or nil
    local expectedOverworldTick = owBefore ~= nil
      and (not stackBefore or topBefore == owBefore)
    local before = skyRideUpdateHeartbeat

    local a, b, c, d, e = gameStepBeforeCompat(...)

    local owAfter = Game.overworld
    local stackAfter = Game.stack
    local topAfter = stackAfter and stackAfter.top and stackAfter:top() or nil
    local stillInOverworld = owAfter ~= nil
      and (not stackAfter or topAfter == owAfter)
    if flight.active and expectedOverworldTick and stillInOverworld
        and skyRideUpdateHeartbeat == before then
      recoverSkyRideUpdate("active-flight logic heartbeat")
    end
    return a, b, c, d, e
  end
  Game.step = gameStepCompatGuard
end

mod.exports.wildsCompatibility = {
  wildsId = WILDS_MOD_ID,
  spriteProviders = SPRITE_PROVIDER_IDS,
  ensureUpdateHook = recoverSkyRideUpdate,
  hookRecoveries = function() return skyRideHookRecoveries end,
  updateHeartbeat = function() return skyRideUpdateHeartbeat end,
}
