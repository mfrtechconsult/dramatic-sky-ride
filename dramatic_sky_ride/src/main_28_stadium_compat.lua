(function()
-- -------------------------------------------------------------------------
-- Pokemon Stadium Overworld Models compatibility API.
--
-- 2D sprites are deliberately the default and remain authoritative unless the
-- player explicitly opts into Stadium 3D. The canonical inter-mod state stays
-- Shane-compatible (isFlying / altitude / mount); Stadium-specific aliases are
-- retained only for the existing bridge and never take ownership of movement.
-- -------------------------------------------------------------------------

local FLIGHT_RENDERER_OPTION = "flight_mount_renderer"
local RENDERER_2D = "2d"
local RENDERER_STADIUM = "stadium"

OPTION_SCHEMA[#OPTION_SCHEMA + 1] = {
  key = FLIGHT_RENDERER_OPTION,
  type = "choice",
  label = "FLIGHT RENDERER",
  default = RENDERER_2D,
  choices = {
    { "2D SPRITES", RENDERER_2D },
    { "STADIUM 3D", RENDERER_STADIUM },
  },
  help = "2D sprites are the default. Stadium 3D is used only when explicitly selected and available.",
}
if mod.options and mod.options.define then mod.options:define(OPTION_SCHEMA) end

local function stadiumHandle()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, "STADIUM_OVERWORLD_MODELS")
  return ok and handle or nil
end

local function requestedRenderer()
  local value = tostring(optionValue(FLIGHT_RENDERER_OPTION, RENDERER_2D)
    or RENDERER_2D):lower()
  return value == RENDERER_STADIUM and RENDERER_STADIUM or RENDERER_2D
end

local function activeMountSpecies()
  if not flight.active then return nil end
  return flight.species or (flight.mon and flight.mon.species) or nil
end

local function speciesDex(species)
  if not species then return nil end
  local cfg = ELIGIBLE and ELIGIBLE[species] or nil
  if cfg and tonumber(cfg.dex) then return tonumber(cfg.dex) end
  local pokemon = Game.data and Game.data.pokemon or nil
  local def = pokemon and pokemon[species] or nil
  return def and tonumber(def.dex) or nil
end

local function stadiumSupportsSpecies(species)
  if not species then return true end
  local handle = stadiumHandle()
  if not handle then return false end
  local ex = handle.exports or {}

  -- Future Stadium/3D providers may explicitly advertise broader coverage.
  -- Prefer that capability when available instead of hard-coding generations.
  for _, name in ipairs({ "supportsSpecies", "hasModel", "modelAvailable" }) do
    local fn = ex[name]
    if type(fn) == "function" then
      local ok, supported = pcall(fn, species, speciesDex(species))
      if ok then return supported == true end
    end
  end

  -- Current Pokemon Stadium model imports naturally cover Gen 1. Gen 2 keeps
  -- the normal DSR billboard even when STADIUM 3D was selected, preventing an
  -- invisible Noctowl/Crobat/Lugia/etc. until a renderer explicitly supports it.
  local dex = speciesDex(species)
  return dex ~= nil and dex >= 1 and dex <= 151
end

local function stadiumRendererAvailable()
  -- Stadium models are a voxel renderer. If VOXEL is off, or the current mount
  -- has no model, keep flight fully functional and fall back to the native 2D
  -- billboard instead of refusing takeoff or producing an invisible mount.
  return stadiumHandle() ~= nil and voxelLevel() > 0
    and stadiumSupportsSpecies(activeMountSpecies())
end

local function effectiveRenderer()
  if requestedRenderer() == RENDERER_STADIUM and stadiumRendererAvailable() then
    return RENDERER_STADIUM
  end
  return RENDERER_2D
end

-- Canonical flight contract. Keep these truthful regardless of renderer so
-- Wild Skies and other ecosystem mods never need to know how DSR is drawn.
mod.exports.isFlying = function()
  return flight.active == true
end

-- Existing Stadium bridge aliases. currentAltitude remains a harmless alias;
-- mountSpecies is intentionally gated by the explicit 3D opt-in so merely
-- installing Stadium cannot replace DSR's preferred 2D flying mount.
mod.exports.currentAltitude = function()
  local altitude = mod.exports.altitude
  if type(altitude) == "function" then
    local ok, value = pcall(altitude)
    if ok then return tonumber(value) or 0 end
  end
  return flight.active and (tonumber(flight.altitude) or 0) or 0
end

mod.exports.mountSpecies = function()
  if effectiveRenderer() ~= RENDERER_STADIUM then return nil end
  local mount = mod.exports.mount
  if type(mount) == "function" then
    local ok, value = pcall(mount)
    if ok and type(value) == "table" and value.species ~= nil then
      return value.species
    end
  end
  return activeMountSpecies()
end

mod.exports.flightRendering = {
  requested = requestedRenderer,
  effective = effectiveRenderer,
  uses2D = function() return effectiveRenderer() == RENDERER_2D end,
  usesStadium = function() return effectiveRenderer() == RENDERER_STADIUM end,
}

mod.exports.stadiumCompatibility = {
  api = 3,
  installed = function() return stadiumHandle() ~= nil end,
  requested = function() return requestedRenderer() == RENDERER_STADIUM end,
  enabled = function() return effectiveRenderer() == RENDERER_STADIUM end,
  supportsSpecies = stadiumSupportsSpecies,
  effectiveRenderer = effectiveRenderer,
}

log("Pokemon Stadium compatibility API loaded (2D renderer default)")
end)();
