(function()
-- -------------------------------------------------------------------------
-- Stadium 3D renderer compatibility contract.
--
-- DSR keeps one renderer setting while allowing multiple optional providers.
-- Gen 2 prefers Randy's STADIUM2_OVERWORLD_MODELS voxel/Stadium provider when
-- it is installed, active and can render the requested mount. DSR's native
-- Stadium 2 cache remains the fallback, followed by the historical Gen 1
-- STADIUM_OVERWORLD_MODELS companion. The option key is intentionally kept for
-- save compatibility.
-- -------------------------------------------------------------------------

local FLIGHT_RENDERER_OPTION = "flight_mount_renderer"
local RENDERER_2D = "2d"
local RENDERER_STADIUM = "stadium"
local GEN1_COMPANION_ID = "STADIUM_OVERWORLD_MODELS"
local GEN2_COMPANION_ID = "STADIUM2_OVERWORLD_MODELS"

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

local function safeHandle(id)
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

local function legacyCompanionHandle()
  return safeHandle(GEN1_COMPANION_ID)
end

local function gen2CompanionHandle()
  return safeHandle(GEN2_COMPANION_ID)
end

local function nativeProvider()
  local ex = mod.exports
  local api = ex and ex.stadium3DNative
  return type(api) == "table" and api or nil
end

local function isGen2()
  local generation = mod.exports and mod.exports.runtimeGeneration or nil
  if generation and type(generation.isGen2) == "function" then
    local ok, value = pcall(generation.isGen2, Game)
    if ok then return value == true end
  end
  return false
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

-- Providers may expose support helpers at the top level or through their
-- OverworldStadium object. Probe the latter with an inert entity so provider
-- availability is authoritative and no live follower/player state is touched.
local function companionSupport(handle, species, dex)
  local ex = handle and handle.exports or nil
  local direct = callSupport(ex, species, dex)
  if direct ~= nil then return direct end

  local ow = ex and ex.overworld or nil
  local nested = callSupport(ow, species, dex)
  if nested ~= nil then return nested end

  local canRender = ow and ow.canRenderEntity or nil
  if type(canRender) == "function" and dex then
    local probe = {
      stadiumDex = dex,
      pokemonDex = dex,
      stadiumSpecies = species,
      pokemonSpecies = species,
      stadiumModel = true,
      pokemonModel = true,
      dramaticSkyRideMountSpecies = species,
    }
    local ok, supported = pcall(canRender, probe)
    if ok then return supported == true end
  end
  return nil
end

local function gen2VoxelActive(handle)
  if not handle then return false end
  local ex = handle.exports or nil
  if type(ex) ~= "table" then return false end

  local state = ex.voxelPipelineState
  if type(state) == "table" then
    if type(state.status) == "function" then
      local ok, status = pcall(state.status)
      if ok and type(status) == "table" and status.active ~= nil then
        return status.active == true
      end
    end
    if state.active ~= nil then return state.active == true end
  end

  -- Older compatible builds may expose only the compose-hook capability.
  if ex.voxelComposeHook ~= nil then return ex.voxelComposeHook == true end
  return ex.rendererInstalled == true
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

local function gen2ProviderSupports(species)
  if not isGen2() then return false end
  local handle = gen2CompanionHandle()
  if not (handle and gen2VoxelActive(handle)) then return false end
  if not species then return true end
  local answer = companionSupport(handle, species, speciesDex(species))
  return answer == true
end

local function nativeSupports(species)
  if not nativeInstalled() then return false end
  if not species then return true end
  local answer = callSupport(nativeProvider(), species, speciesDex(species))
  return answer == true
end

local function legacySupports(species)
  local handle = legacyCompanionHandle()
  if not handle then return false end
  if not species then return true end
  local dex = speciesDex(species)
  local answer = companionSupport(handle, species, dex)
  if answer ~= nil then return answer end
  -- Compatibility fallback for old Stadium 1 builds without capability APIs.
  return dex ~= nil and dex >= 1 and dex <= 151
end

local function selectedProvider(species)
  species = species or activeMountSpecies()
  if gen2ProviderSupports(species) then return "gen2_stadium2_voxel" end
  if nativeSupports(species) then return "native_stadium2" end
  if legacySupports(species) then return "stadium_overworld_models" end
  return nil
end

local function stadiumSupportsSpecies(species)
  return selectedProvider(species) ~= nil
end

local function stadiumRendererAvailable()
  local provider = selectedProvider(activeMountSpecies())
  if not provider then return false end
  -- External Gold voxel owns its own camera/compose level and does not use
  -- DSR's Gen-1 voxelLevel() state. Native/legacy providers still do.
  if provider == "gen2_stadium2_voxel" then return true end
  return voxelLevel() > 0
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
-- It covers Flight, Ground Ride and Visible Surf while STADIUM 3D is effective.
mod.exports.mountSpecies = function()
  if effectiveRenderer() ~= RENDERER_STADIUM then return nil end
  return activeMountSpecies()
end

mod.exports.flightRendering = {
  requested = requestedRenderer,
  effective = effectiveRenderer,
  provider = function() return selectedProvider(activeMountSpecies()) end,
  uses2D = function() return effectiveRenderer() == RENDERER_2D end,
  usesStadium = function() return effectiveRenderer() == RENDERER_STADIUM end,
  usesNativeStadium = function()
    return effectiveRenderer() == RENDERER_STADIUM
      and selectedProvider(activeMountSpecies()) == "native_stadium2"
  end,
  usesGen2VoxelStadium = function()
    return effectiveRenderer() == RENDERER_STADIUM
      and selectedProvider(activeMountSpecies()) == "gen2_stadium2_voxel"
  end,
}

mod.exports.stadiumCompatibility = {
  api = 6,
  installed = function()
    return nativeInstalled() or gen2CompanionHandle() ~= nil
      or legacyCompanionHandle() ~= nil
  end,
  requested = function() return requestedRenderer() == RENDERER_STADIUM end,
  enabled = function() return effectiveRenderer() == RENDERER_STADIUM end,
  supportsSpecies = stadiumSupportsSpecies,
  effectiveRenderer = effectiveRenderer,
  activeMountSpecies = activeMountSpecies,
  native = function() return nativeProvider() ~= nil end,
  gen2Voxel = function()
    local handle = gen2CompanionHandle()
    return handle ~= nil and gen2VoxelActive(handle)
  end,
  gen2VoxelId = GEN2_COMPANION_ID,
  legacyCompanionId = GEN1_COMPANION_ID,
  randy = function()
    return gen2CompanionHandle() ~= nil or legacyCompanionHandle() ~= nil
  end,
  companion = function()
    return gen2CompanionHandle() ~= nil or legacyCompanionHandle() ~= nil
  end,
  provider = function() return selectedProvider(activeMountSpecies()) end,
}

log("Stadium renderer compatibility API loaded (Gen2 voxel -> native Stadium 2 -> legacy companion; 2D default)")
end)();
