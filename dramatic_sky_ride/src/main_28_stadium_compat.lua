(function()
-- -------------------------------------------------------------------------
-- Stadium 3D renderer compatibility contract.
--
-- Stable DSR historically spoke only to STADIUM_OVERWORLD_MODELS (Randy's
-- Stadium 1 companion).  The experimental renderer now also accepts DSR's
-- own native Stadium 2 provider, which is registered later in the load order.
-- The option key is intentionally kept for save compatibility.
-- -------------------------------------------------------------------------

local FLIGHT_RENDERER_OPTION = "flight_mount_renderer"
local RENDERER_2D = "2d"
local RENDERER_STADIUM = "stadium"

OPTION_SCHEMA[#OPTION_SCHEMA + 1] = {
  key = FLIGHT_RENDERER_OPTION,
  type = "choice",
  label = "MOUNT RENDERER",
  default = RENDERER_2D,
  choices = {
    { "2D SPRITES", RENDERER_2D },
    { "STADIUM 3D", RENDERER_STADIUM },
  },
  help = "Use 2D mount sprites or compatible Stadium 3D models in voxel views. 2D remains the safe fallback.",
}
if mod.options and mod.options.define then mod.options:define(OPTION_SCHEMA) end

local function randyHandle()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, "STADIUM_OVERWORLD_MODELS")
  return ok and handle or nil
end

local function nativeProvider()
  local ex = mod.exports
  local api = ex and ex.stadium3DNative
  return type(api) == "table" and api or nil
end

local function requestedRenderer()
  local value = tostring(optionValue(FLIGHT_RENDERER_OPTION, RENDERER_2D)
    or RENDERER_2D):lower()
  return value == RENDERER_STADIUM and RENDERER_STADIUM or RENDERER_2D
end

local function activeMountSpecies()
  if flight and flight.active then
    return flight.species or (flight.mon and flight.mon.species) or nil
  end
  if ground and ground.active then
    return ground.species or (ground.mon and ground.mon.species) or nil
  end
  local ex = mod.exports or {}
  if type(ex.isWaterRiding) == "function" and type(ex.waterMountSpecies) == "function" then
    local okActive, active = pcall(ex.isWaterRiding)
    if okActive and active == true then
      local okSpecies, species = pcall(ex.waterMountSpecies)
      if okSpecies then return species end
    end
  end
  return nil
end

local function speciesDex(species)
  if not species then return nil end
  local cfg = (ELIGIBLE and ELIGIBLE[species])
    or (GROUND_ELIGIBLE and GROUND_ELIGIBLE[species])
  if cfg and tonumber(cfg.dex) then return tonumber(cfg.dex) end
  local pokemon = Game.data and Game.data.pokemon or nil
  local def = pokemon and pokemon[species] or nil
  return def and tonumber(def.dex) or nil
end

local function callSupport(api, species, dex)
  if type(api) ~= "table" then return nil end
  for _, name in ipairs({ "supportsSpecies", "hasModel", "modelAvailable" }) do
    local fn = api[name]
    if type(fn) == "function" then
      local ok, supported = pcall(fn, species, dex)
      if ok then return supported == true end
    end
  end
  return nil
end

local function stadiumSupportsSpecies(species)
  if not species then return true end
  local dex = speciesDex(species)

  -- Prefer DSR's native provider. Stadium 2 packs can cover National Dex
  -- 1..251 and therefore remove the old Gen-1-only renderer ceiling.
  local native = nativeProvider()
  local nativeAnswer = callSupport(native, species, dex)
  if nativeAnswer ~= nil then return nativeAnswer end

  -- Randy's companion remains a supported Stadium 1 fallback.
  local handle = randyHandle()
  local ex = handle and handle.exports or nil
  local randyAnswer = callSupport(ex, species, dex)
  if randyAnswer ~= nil then return randyAnswer end

  -- Only assume the natural Stadium 1 range when Randy is actually present.
  return handle ~= nil and dex ~= nil and dex >= 1 and dex <= 151
end

local function nativeInstalled()
  local api = nativeProvider()
  if not api then return false end
  if type(api.installed) == "function" then
    local ok, value = pcall(api.installed)
    return ok and value == true
  end
  return true
end

local function stadiumRendererAvailable()
  if voxelLevel() <= 0 then return false end
  if not (nativeInstalled() or randyHandle() ~= nil) then return false end
  return stadiumSupportsSpecies(activeMountSpecies())
end

local function effectiveRenderer()
  if requestedRenderer() == RENDERER_STADIUM and stadiumRendererAvailable() then
    return RENDERER_STADIUM
  end
  return RENDERER_2D
end

-- Canonical flight state stays renderer-independent for Wild Skies and other
-- ecosystem consumers.
mod.exports.isFlying = function()
  return flight.active == true
end

mod.exports.currentAltitude = function()
  local altitude = mod.exports.altitude
  if type(altitude) == "function" then
    local ok, value = pcall(altitude)
    if ok then return tonumber(value) or 0 end
  end
  return flight.active and (tonumber(flight.altitude) or 0) or 0
end

-- Stadium providers use this as the exact currently-rendered mount identity.
-- It now covers Flight, Ground Ride and Visible Surf while STADIUM 3D is the
-- effective renderer; outside that mode it remains nil so installing a Stadium
-- provider cannot silently take ownership of DSR's normal 2D presentation.
mod.exports.mountSpecies = function()
  if effectiveRenderer() ~= RENDERER_STADIUM then return nil end
  return activeMountSpecies()
end

mod.exports.flightRendering = {
  requested = requestedRenderer,
  effective = effectiveRenderer,
  uses2D = function() return effectiveRenderer() == RENDERER_2D end,
  usesStadium = function() return effectiveRenderer() == RENDERER_STADIUM end,
}

mod.exports.stadiumCompatibility = {
  api = 4,
  installed = function() return nativeInstalled() or randyHandle() ~= nil end,
  requested = function() return requestedRenderer() == RENDERER_STADIUM end,
  enabled = function() return effectiveRenderer() == RENDERER_STADIUM end,
  supportsSpecies = stadiumSupportsSpecies,
  effectiveRenderer = effectiveRenderer,
  activeMountSpecies = activeMountSpecies,
  native = function() return nativeProvider() ~= nil end,
  randy = function() return randyHandle() ~= nil end,
}

log("Stadium renderer compatibility API loaded (native Stadium 2 capable; 2D default)")
end)();
