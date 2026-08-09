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

local function stadiumRendererAvailable()
  -- Stadium models are a voxel renderer. If VOXEL is off, keep flight fully
  -- functional and fall back to the native 2D composition instead of refusing
  -- takeoff or producing an invisible mount.
  return stadiumHandle() ~= nil and voxelLevel() > 0
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
  if flight.active then
    return flight.species or (flight.mon and flight.mon.species) or nil
  end
  return nil
end

mod.exports.flightRendering = {
  requested = requestedRenderer,
  effective = effectiveRenderer,
  uses2D = function() return effectiveRenderer() == RENDERER_2D end,
  usesStadium = function() return effectiveRenderer() == RENDERER_STADIUM end,
}

mod.exports.stadiumCompatibility = {
  api = 2,
  installed = function() return stadiumHandle() ~= nil end,
  requested = function() return requestedRenderer() == RENDERER_STADIUM end,
  enabled = function() return effectiveRenderer() == RENDERER_STADIUM end,
  effectiveRenderer = effectiveRenderer,
}

log("Pokemon Stadium compatibility API loaded (2D renderer default)")
end)();
