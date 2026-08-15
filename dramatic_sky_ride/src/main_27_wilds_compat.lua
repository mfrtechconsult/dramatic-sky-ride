
(function()
-- -------------------------------------------------------------------------
-- Wilds of Kanto / follower-provider compatibility.
--
-- Gen1Recomp's current sandbox removes raw filesystem and introspection
-- globals from mods. Wilds 2.1.5 moved to the supported public surfaces as
-- well, so this bridge deliberately uses only mod.find(...).exports plus the
-- engine Assets API. There is no longer any update-chain/upvalue surgery here:
-- Wilds owns its follower lifecycle and battle-return reconciliation, DSR only
-- consumes its sprite service and asks it to resync followers when a mount is
-- restored.
-- -------------------------------------------------------------------------
local WILDS_MOD_ID = "overworld_wild_spawns"
local WILDS_SANDBOX_BASELINE = "2.1.5"
local SPRITE_PROVIDER_IDS = {
  WILDS_MOD_ID,
  "PokePCFollowers_VoxelMerge",
  "pokepcfollowers",
  "FOLLOWERS_EX",
  "followers_ex",
}

local function compatHandle(id)
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

local function compatExports(id)
  local handle = compatHandle(id)
  return handle and handle.exports or nil
end

local function liveGame()
  return mod.game or (mod.world and mod.world.game) or Game
end

-- Every compatibility path ends at the same strict mount-sheet validation.
-- Providers may expose a modern definition API or the older assetPath seam,
-- but neither path is trusted until the engine can load a six-frame 16x96+
-- walker sheet. No foreign mod directory is inspected directly.
local function validatedProviderDefinition(id, provided)
  local frames = provided and tonumber(provided.frames) or 0
  if not (provided and type(provided.image) == "string"
      and provided.image ~= "" and frames >= 6
      and provided.walker ~= false) then
    return nil
  end
  local okImage, image = pcall(Assets.image, provided.image)
  if not (okImage and image) then return nil end
  local width, height = image:getDimensions()
  if width < 16 or height < 96 then return nil end
  return provided, provided.providerId or id
end

local function usableProviderDefinition(id, ex, species, role, style)
  if not (ex and type(ex.resolveFollowerSprite) == "function") then return nil end
  local opts = {
    species = species,
    surface = "land",
    role = role or "mount",
    game = liveGame(),
  }
  if style then opts.style = style end
  local okDef, provided = pcall(ex.resolveFollowerSprite, opts)
  if not okDef then return nil end
  return validatedProviderDefinition(id, provided)
end

-- Temporary compatibility for providers that have not migrated to
-- resolveFollowerSprite yet. assetPath is already a public export used by old
-- PokéPC releases, so calling it through mod.find(...).exports remains
-- sandbox-safe.
local function usableLegacyProviderDefinition(id, ex, species)
  if not (ex and type(ex.assetPath) == "function") then return nil end
  local okPath, path = pcall(ex.assetPath, species)
  if not okPath or type(path) ~= "string" or path == "" then return nil end
  return validatedProviderDefinition(id, {
    image = path,
    frames = 6,
    walker = true,
    providerId = id,
  })
end

local function compatibleSpriteDefinition(species, role)
  for _, id in ipairs(SPRITE_PROVIDER_IDS) do
    local ex = compatExports(id)

    -- Preferred contract. Wilds 2.1.5 returns sandbox-safe mod.assets paths.
    local def, provider = usableProviderDefinition(id, ex, species, role, nil)
    if def then return def, provider end

    if id == WILDS_MOD_ID then
      -- Wilds' configured Pokédex style may resolve to a static front image.
      -- Ask its own follower style for a walking sheet before considering
      -- legacy providers.
      def, provider = usableProviderDefinition(id, ex, species, role, "followers")
      if def then return def, provider end
    end

    def, provider = usableLegacyProviderDefinition(id, ex, species)
    if def then return def, provider end
  end
  return nil
end

local lastCompatSpriteProvider = nil
local function providerPath(species, role)
  local def, provider = compatibleSpriteDefinition(species, role)
  if not def then return nil end
  if provider ~= lastCompatSpriteProvider then
    log("Mount sprite provider: %s", tostring(provider))
    lastCompatSpriteProvider = provider
  end
  return def.image
end

-- Replace only path resolvers. Existing buildMountSprite / ground-mount chains
-- retain DSR sizing, rider offsets and voxel integration.
local legacyFollowerPath = followerPath
followerPath = function(species)
  return providerPath(species, "flight_mount") or legacyFollowerPath(species)
end

local legacyGroundFollowerPath = groundFollowerPath
groundFollowerPath = function(species)
  return providerPath(species, "ground_mount") or legacyGroundFollowerPath(species)
end

-- Wilds owns follower runtime when installed. A successful sync is
-- authoritative even when its configured follower count is zero.
local function syncWildsFollowers(ow)
  local wilds = compatExports(WILDS_MOD_ID)
  if not (wilds and type(wilds.syncAll) == "function") then
    return false, "unavailable"
  end
  local ok, result, detail = pcall(wilds.syncAll, liveGame(), ow)
  if not ok then
    log("Wilds follower sync failed: %s", tostring(result))
    return false, result
  end
  if result == false then
    return false, detail or "sync rejected"
  end
  return true, result
end

local legacySyncFollowerMods = syncFollowerMods
syncFollowerMods = function(ow)
  local wilds = compatExports(WILDS_MOD_ID)
  if wilds and type(wilds.syncAll) == "function" then
    local ok = syncWildsFollowers(ow)
    -- Wilds is still the lifecycle owner if its sync reports a transient
    -- not-ready state. Do not run PokéPC / Followers EX on top of it.
    return ok
  end
  return legacySyncFollowerMods(ow)
end

local function wildsVersion()
  local handle = compatHandle(WILDS_MOD_ID)
  if handle and handle.version then return tostring(handle.version) end
  local ex = handle and handle.exports or nil
  if ex and ex.version then return tostring(ex.version) end
  return nil
end

local function wildsAvailable()
  local ex = compatExports(WILDS_MOD_ID)
  return ex ~= nil
    and type(ex.resolveFollowerSprite) == "function"
    and type(ex.syncAll) == "function"
end

-- Public compatibility status. The legacy guard-shaped methods are retained as
-- harmless shims for companion mods that queried them, but no function below
-- inspects or rewrites another function's upvalues. In the sandbox-era bridge
-- an update guard is explicitly not required: Wilds 2.1.5 uses public
-- events/hooks and performs its own battle-return reattachment.
mod.exports.wildsCompatibility = {
  mode = "sandbox_public_exports",
  wildsId = WILDS_MOD_ID,
  sandboxBaseline = WILDS_SANDBOX_BASELINE,
  spriteProviders = SPRITE_PROVIDER_IDS,
  available = wildsAvailable,
  version = wildsVersion,
  syncFollowers = syncWildsFollowers,
  updateGuardRequired = false,

  -- Deprecated compatibility shims. Keep these callable for older companion
  -- integrations while making their no-op sandbox semantics explicit.
  ensureUpdateHook = function() return true end,
  composeAround = function(current) return current end,
  rootUpdate = function() return OverworldState.update end,
  ownsUpdate = function(fn) return fn == OverworldState.update end,
  hookGuardReady = function() return false end,
  hookRecoveries = function() return 0 end,
  updateHeartbeat = function() return 0 end,
  protectedWrappers = function() return 0 end,
}

mod.events:on("mods.loaded", function()
  if not wildsAvailable() then return end
  log("Wilds compatibility: sandbox public API active (Wilds %s; baseline %s)",
      tostring(wildsVersion() or "unknown"), WILDS_SANDBOX_BASELINE)
end)
end)();