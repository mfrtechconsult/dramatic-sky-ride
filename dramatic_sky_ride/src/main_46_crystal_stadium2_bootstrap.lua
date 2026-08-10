(function()
-- -------------------------------------------------------------------------
-- Crystal 251 Stadium 2 cache bootstrap.
--
-- Crystal 251 currently installs its Stadium 2 bridge only against the
-- original DRAMATIC_SHAPE id. DSR also supports DRAMALESS_SHAPE and Battle Art.
-- Dramaless exposes the complete Stadium module family the Crystal bridge
-- expects, so when the DSM cache is missing/outdated DSR can safely hand that
-- provider to Crystal and let Crystal's own importer/build UI do the work.
--
-- Battle Art intentionally is NOT faked here: it does not ship StadiumBuild,
-- StadiumFragment, StadiumRig and the other importer modules the Crystal bridge
-- consumes. DSR can render an already-generated DSM cache with Battle Art via
-- main_45, but cache generation must be performed once with a full Stadium
-- provider (Dramaless or the original Dramatic Shape).
-- -------------------------------------------------------------------------

local state = {
  attempts = 0,
  installed = false,
  crystal = false,
  provider = nil,
  needed = nil,
  reason = nil,
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

local function cacheCompatible()
  local native = mod.exports and mod.exports.stadium3DNative or nil
  local fn = native and native.cacheStatus
  if type(fn) ~= "function" then return false end
  local ok, status = pcall(fn)
  return ok and type(status) == "table" and status.compatible == true
end

local function crystalHandle()
  return safeFind("CRYSTAL_251") or safeFind("crystal_251")
end

local function fullStadiumProvider()
  -- Prefer Dramaless: it is the supported modern provider that Crystal does
  -- not currently discover by itself. The original provider is retained as a
  -- defensive load-order fallback; Crystal normally installs against it first.
  local handle = safeFind("DRAMALESS_SHAPE") or safeFind("dramaticless_shape")
  if handle then return handle, "DRAMALESS_SHAPE" end
  handle = safeFind("DRAMATIC_SHAPE") or safeFind("dramatic_shape")
  if handle then return handle, "DRAMATIC_SHAPE" end
  return nil
end

local function providerHasImporterModules(handle)
  local V = handle and handle.exports and handle.exports.lib or nil
  if not (V and type(V.require) == "function") then return false end
  -- Do not instantiate the whole importer here. StadiumRig is the useful
  -- discriminator between full Stadium providers and Battle Art's lean voxel
  -- provider, and the remaining modules are verified by Crystal's own install.
  local ok, rig = pcall(V.require, "StadiumRig")
  return ok and type(rig) == "table" and type(rig.new) == "function"
end

local function tryBootstrap(reason)
  state.attempts = state.attempts + 1
  state.needed = not cacheCompatible()
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

  local bridge = crystal.exports and crystal.exports.crystalStadium2 or nil
  if not (type(bridge) == "table" and type(bridge.install) == "function") then
    -- Crystal exports this only after its own Crystal ROM content cache exists.
    -- Let Crystal's normal importer finish first and retry on game.ready.
    state.reason = "crystal_251_not_ready"
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

  local options = {
    count = 251,
    ownerId = tostring(crystal.id or "CRYSTAL_251"),
    ownerName = "Crystal 251",
    -- Deliberately omit cache: Crystal already called Bridge.configure(cache)
    -- before exporting this bridge. configure(nil) does not clear its palette
    -- table, so the original imported Crystal metadata remains authoritative.
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
  state.reason = reason or "installed"
  log("Crystal 251 Stadium 2 cache bootstrap attached to %s", tostring(providerId))
  return true
end

-- Provider/Crystal mods have lower priority than DSR in the supported stack,
-- so this normally succeeds immediately. game.ready is a second deterministic
-- seam for unusual launcher/load orders and for Crystal finishing setup.
tryBootstrap("load")
if mod.events and mod.events.on then
  mod.events:on("game.ready", function()
    if not state.installed and not cacheCompatible() then
      tryBootstrap("game.ready")
    end
  end)
end

mod.exports.stadium3DCrystalBootstrap = {
  api = 1,
  retry = tryBootstrap,
  status = function()
    state.needed = not cacheCompatible()
    return {
      attempts = state.attempts,
      installed = state.installed,
      crystal = state.crystal,
      provider = state.provider,
      needed = state.needed,
      reason = state.reason,
    }
  end,
}
end)();
