(function()
-- -------------------------------------------------------------------------
-- Crystal 251 Stadium 2 cache bootstrap.
--
-- DSR can render Crystal's DSM4 packs with either Dramaless or Battle Art.
-- Cache generation, however, needs the full Stadium importer module family.
-- Dramaless provides that family, while Battle Art intentionally does not.
--
-- Crystal's historical Stadium 2 importer also produced valid-looking
-- C2DSM10 caches containing only a synthetic one-frame bind pose when motion
-- extraction failed. main_46a detects those legacy caches. If a current
-- Crystal bridge with the fixed motion decoder is installed, this bootstrap
-- invalidates only the completion marker and lets Crystal rebuild the DSM
-- files from the user's ROM through Dramaless.
-- -------------------------------------------------------------------------

local state = {
  attempts = 0,
  installed = false,
  crystal = false,
  provider = nil,
  needed = nil,
  reason = nil,
  invalidatedStaticCache = false,
  bridgeSource = nil,
}
local warned = {}

local function warnOnce(key, fmt, ...)
  if warned[key] then return end
  warned[key] = true
  if mod.log and mod.log.warn then pcall(mod.log.warn, mod.log, fmt, ...) end
end

local function safeFind(id)
  if not (mod and mod.find) then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

local function cacheStatus()
  local native = mod.exports and mod.exports.stadium3DNative or nil
  local fn = native and native.cacheStatus
  if type(fn) ~= "function" then return {} end
  local ok, status = pcall(fn)
  return ok and type(status) == "table" and status or {}
end

local function cacheCompatible()
  return cacheStatus().compatible == true
end

local function crystalHandle()
  return safeFind("CRYSTAL_251") or safeFind("crystal_251")
end

local function fullStadiumProvider()
  local handle = safeFind("DRAMALESS_SHAPE") or safeFind("dramaticless_shape")
  if handle then return handle, "DRAMALESS_SHAPE" end
  handle = safeFind("DRAMATIC_SHAPE") or safeFind("dramatic_shape")
  if handle then return handle, "DRAMATIC_SHAPE" end
  return nil
end

local function providerHasImporterModules(handle)
  local V = handle and handle.exports and handle.exports.lib or nil
  if not (V and type(V.require) == "function") then return false end
  local required = { "StadiumRig", "StadiumBuild", "StadiumFragment",
                     "StadiumInstall", "StadiumRom", "StadiumFx" }
  for _, name in ipairs(required) do
    local ok, value = pcall(V.require, name)
    if not (ok and type(value) == "table") then return false end
  end
  return true
end

-- Crystal only exports crystalStadium2 after its own install() succeeds against
-- a provider it discovered. With Dramaless-only setups that export can be nil,
-- even though the bridge module itself is present and is explicitly designed
-- to accept a provider argument. Load the module directly as the fallback.
local function crystalBridge(crystal)
  local exported = crystal and crystal.exports and crystal.exports.crystalStadium2 or nil
  if type(exported) == "table" and type(exported.install) == "function" then
    state.bridgeSource = "export"
    return exported
  end
  local ok, bridge = pcall(require, "mods.CRYSTAL_251.lib.stadium2_bridge")
  if ok and type(bridge) == "table" and type(bridge.install) == "function" then
    state.bridgeSource = "module"
    return bridge
  end
  state.bridgeSource = nil
  return nil
end

local function bridgeHasFixedMotionDecoder(bridge)
  local test = bridge and bridge._test or nil
  return type(test) == "table"
    and type(test.decodeAnimationSources) == "function"
    and type(test.poseSourcesForRecord) == "function"
end

local function invalidateLegacyStaticCache(bridge, status)
  if not (status and status.animationReason == "static_animation_cache") then
    return true
  end
  if not bridgeHasFixedMotionDecoder(bridge) then
    state.reason = "crystal_251_motion_decoder_too_old"
    warnOnce("old_crystal_motion_decoder",
      "Stadium 2 cache is a legacy one-frame cache, but this Crystal 251 build does not expose the fixed Stadium 2 motion decoder. Update Crystal 251 before rebuilding the cache.")
    return false
  end
  local guard = mod.exports and mod.exports.stadium3DAnimationCacheGuard or nil
  if not (guard and type(guard.invalidateMarker) == "function") then
    state.reason = "animation_cache_guard_missing"
    return false
  end
  local ok, removed, why = pcall(guard.invalidateMarker)
  if not ok or removed ~= true then
    state.reason = "static_cache_invalidation_failed"
    warnOnce("static_cache_invalidation",
      "Could not invalidate legacy static Stadium 2 cache marker: %s",
      tostring(ok and why or removed))
    return false
  end
  state.invalidatedStaticCache = true
  state.reason = "static_cache_invalidated"
  return true
end

local function tryBootstrap(reason)
  state.attempts = state.attempts + 1
  local status = cacheStatus()
  state.needed = status.compatible ~= true
  if not state.needed then
    state.reason = "cache_ready"
    return true
  end

  local crystal = crystalHandle()
  state.crystal = crystal ~= nil
  if not crystal then
    state.reason = "crystal_251_missing"
    return false
  end

  local bridge = crystalBridge(crystal)
  if not bridge then
    state.reason = "crystal_251_bridge_unavailable"
    return false
  end

  local provider, providerId = fullStadiumProvider()
  state.provider = providerId
  if not provider then
    state.reason = safeFind("BATTLE_ART_VOXEL_FORK")
      and "battle_art_requires_prebuilt_cache" or "stadium_import_provider_missing"
    if state.reason == "battle_art_requires_prebuilt_cache" then
      warnOnce("battle_art_cache",
        "Native Stadium 2 cache is not ready. Battle Art can render DSR's DSM mounts but cannot build Crystal 251's Stadium cache; generate it once with Dramaless Shape or Dramatic Shape, then return to Battle Art.")
    end
    return false
  end
  if not providerHasImporterModules(provider) then
    state.reason = "provider_missing_stadium_modules"
    warnOnce("provider_modules:" .. tostring(providerId),
      "%s was found but does not expose the Stadium importer modules Crystal 251 requires",
      tostring(providerId))
    return false
  end

  -- Only remove the completion marker once we know both sides required for a
  -- correct rebuild are present: a Crystal bridge with the fixed decoder and
  -- a full Stadium provider. Existing DSM files remain until overwritten.
  if not invalidateLegacyStaticCache(bridge, status) then return false end

  local options = {
    count = 251,
    ownerId = tostring(crystal.id or "CRYSTAL_251"),
    ownerName = "Crystal 251",
  }
  local ok, active = pcall(bridge.install, crystal, nil, provider, options)
  if not ok or not active then
    state.reason = "bridge_install_failed"
    warnOnce("install:" .. tostring(providerId),
      "Could not attach Crystal 251's Stadium 2 importer to %s: %s",
      tostring(providerId), tostring(active))
    return false
  end

  state.installed = true
  state.provider = providerId
  state.reason = state.invalidatedStaticCache and "rebuild_attached" or (reason or "installed")
  log("Crystal 251 Stadium 2 cache bootstrap attached to %s (bridge=%s, rebuild=%s)",
    tostring(providerId), tostring(state.bridgeSource),
    tostring(state.invalidatedStaticCache))
  return true
end

tryBootstrap("load")
if mod.events and mod.events.on then
  mod.events:on("game.ready", function()
    if not state.installed and not cacheCompatible() then
      tryBootstrap("game.ready")
    end
  end)
end

mod.exports.stadium3DCrystalBootstrap = {
  api = 2,
  retry = tryBootstrap,
  status = function()
    local status = cacheStatus()
    state.needed = status.compatible ~= true
    return {
      attempts = state.attempts,
      installed = state.installed,
      crystal = state.crystal,
      provider = state.provider,
      needed = state.needed,
      reason = state.reason,
      invalidatedStaticCache = state.invalidatedStaticCache,
      bridgeSource = state.bridgeSource,
      animationReason = status.animationReason,
      animationCount = status.animationCount,
    }
  end,
}
end)();
