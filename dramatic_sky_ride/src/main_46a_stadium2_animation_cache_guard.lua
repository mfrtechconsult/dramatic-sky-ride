(function()
-- -------------------------------------------------------------------------
-- Legacy Stadium 2 animation-cache guard.
-- -------------------------------------------------------------------------
local MARKER = "crystal_251/stadium2/pack.info"
local PROBE_SPECIES = "CHARIZARD"
local state = { checked = false, stale = false, reason = nil, animations = nil, invalidated = false }
local native = mod.exports and mod.exports.stadium3DNative or nil
local rawCacheStatus = native and native.cacheStatus or nil
local rawModelInfo = native and native.modelInfo or nil
local rawClearCache = native and native.clearCache or nil
local rawInstalled = native and native.installed or nil
local rawSupportsSpecies = native and native.supportsSpecies or nil
local rawHasModel = native and native.hasModel or nil
local rawModelAvailable = native and native.modelAvailable or nil

local function inspect()
  if state.checked then return state end
  state.checked = true; state.stale = false; state.reason = nil; state.animations = nil
  if type(rawCacheStatus) ~= "function" then state.reason = "native_status_unavailable"; return state end
  local okStatus, status = pcall(rawCacheStatus)
  if not (okStatus and type(status) == "table" and status.compatible == true) then
    state.reason = status and status.reason or "cache_not_compatible"; return state
  end
  if type(rawModelInfo) ~= "function" then state.reason = "model_info_unavailable"; return state end
  local okInfo, info = pcall(rawModelInfo, PROBE_SPECIES)
  if not (okInfo and type(info) == "table") then state.reason = "probe_model_unavailable"; return state end
  state.animations = tonumber(info.animations)
  if state.animations and state.animations <= 1 then
    state.stale = true; state.reason = "static_animation_cache"
  else state.reason = "animation_cache_ok" end
  return state
end

local function animationUsable() return inspect().stale ~= true end
local function invalidateMarker()
  local current = inspect()
  if not current.stale then return false, current.reason end
  if type(rawClearCache) ~= "function" then return false, "provider_cache_clear_unavailable" end
  local ok, result = pcall(rawClearCache)
  if not ok or result == false then return false, tostring(result or "provider clear failed") end
  state.invalidated = true; state.checked = false; state.stale = false
  state.reason = "provider_cache_invalidated"
  log("Stadium 2 legacy static cache invalidated through provider API")
  return true
end

if native and type(rawCacheStatus) == "function" then
  native.cacheStatus = function()
    local ok, status = pcall(rawCacheStatus); status = ok and type(status) == "table" and status or {}
    local check = inspect()
    status.animationProbe = PROBE_SPECIES; status.animationCount = check.animations
    status.animationCompatible = not check.stale; status.animationReason = check.reason
    if check.stale then status.compatible = false; status.operational = false; status.reason = check.reason end
    return status
  end
  native.installed = function(...)
    if not animationUsable() then return false end
    if type(rawInstalled) ~= "function" then return true end
    local ok, value = pcall(rawInstalled, ...); return ok and value == true
  end
  native.supportsSpecies = function(...)
    if not animationUsable() then return false end
    if type(rawSupportsSpecies) ~= "function" then return false end
    local ok, value = pcall(rawSupportsSpecies, ...); return ok and value == true
  end
  native.hasModel = function(...)
    if not animationUsable() then return false end
    local fn = type(rawHasModel) == "function" and rawHasModel or rawSupportsSpecies
    if type(fn) ~= "function" then return false end
    local ok, value = pcall(fn, ...); return ok and value == true
  end
  native.modelAvailable = function(...)
    if not animationUsable() then return false end
    local fn = type(rawModelAvailable) == "function" and rawModelAvailable or rawSupportsSpecies
    if type(fn) ~= "function" then return false end
    local ok, value = pcall(fn, ...); return ok and value == true
  end
end

mod.exports.stadium3DAnimationCacheGuard = {
  api = 2,
  inspect = function()
    local s = inspect()
    return { checked=s.checked, stale=s.stale, reason=s.reason, animations=s.animations,
      invalidated=s.invalidated, probeSpecies=PROBE_SPECIES }
  end,
  usable = animationUsable,
  invalidateMarker = invalidateMarker,
}
local initial = inspect()
if initial.stale then
  if mod.log and mod.log.warn then pcall(mod.log.warn, mod.log,
    "Stadium 2 cache contains only the one-frame Charizard fallback; treating it as stale") end
else
  log("Stadium 2 animation cache guard loaded (%s, animations=%s)", tostring(initial.reason), tostring(initial.animations))
end
end)();
