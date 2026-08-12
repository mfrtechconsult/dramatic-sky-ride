;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites embedded HGSS / PokeMMO mount bridge.
--
-- STADIUM2_OVERWORLD_MODELS embeds Wilds instead of exposing it through the
-- standalone overworld_wild_spawns mod id. Reuse main_38's already-tested
-- native 4x4 PokeMMO atlas resolver by presenting the embedded Wilds export to
-- it only for the duration of a synchronous resolve call. The normal mod.find
-- surface is restored immediately afterwards.
--
-- This bridge is intentionally 2D-only. STADIUM 3D remains owned by the Gen2
-- voxel interoperability path and never receives one of these player sprites.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local WILDS_ID = "overworld_wild_spawns"
local PaletteFX = require("src.render.PaletteFX")
local state = {
  resolves = 0,
  flight = 0,
  ground = 0,
  water = 0,
  lastSpecies = nil,
  lastStyle = nil,
  lastProviderVersion = nil,
  lastError = nil,
}

local function isGold()
  local generation = mod.exports and mod.exports.runtimeGeneration or nil
  if generation and type(generation.isGen2) == "function" then
    local ok, value = pcall(generation.isGen2, Game)
    if ok then return value == true end
  end
  return false
end

local function requested2D()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.requested) == "function" then
    local ok, value = pcall(rendering.requested)
    if ok and value ~= nil then return tostring(value):lower() ~= "stadium" end
  end
  local value = optionValue and optionValue("flight_mount_renderer", "2d") or "2d"
  return tostring(value or "2d"):lower() ~= "stadium"
end

local function findHandle(id)
  if type(mod.find) ~= "function" then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  return ok and handle or nil
end

local function standaloneWildsInstalled()
  return findHandle(WILDS_ID) ~= nil
end

local function embeddedContext()
  if not isGold() or not requested2D() or standaloneWildsInstalled() then return nil end
  local provider = findHandle(PROVIDER_ID)
  local ex = provider and provider.exports or nil
  local wilds = ex and ex.wilds or nil
  local render = wilds and wilds.render or nil
  local wildsMod = render and render.mod or nil
  local options = wildsMod and wildsMod.options or nil
  if not (wilds and render and options and type(options.get) == "function") then return nil end

  local okStyle, style = pcall(options.get, options, "sprite_style")
  if not okStyle then return nil end
  state.lastStyle = style
  state.lastProviderVersion = ex and ex.version or nil
  if tostring(style or ""):lower() ~= "pokemmo" then return nil end
  return {
    provider = provider,
    exports = ex,
    wilds = wilds,
  }
end

local function resolveEmbeddedNative(species)
  local ctx = embeddedContext()
  local api = mod.exports and mod.exports.nativePokeMMOMounts or nil
  if not (ctx and api and type(api.resolve) == "function" and type(mod.find) == "function") then
    return nil
  end

  local originalFind = mod.find
  local alias = {
    id = WILDS_ID,
    name = WILDS_ID,
    exports = ctx.wilds,
    dramaticSkyRideEmbeddedAlias = true,
    sourceHandle = ctx.provider,
  }

  mod.find = function(self, id, ...)
    if self == mod and id == WILDS_ID then
      local okReal, real = pcall(originalFind, self, id, ...)
      if okReal and real ~= nil then return real end
      return alias
    end
    return originalFind(self, id, ...)
  end

  local ok, renderer = pcall(api.resolve, species)
  mod.find = originalFind
  if not ok then
    state.lastError = tostring(renderer)
    return nil
  end
  if not renderer then return nil end

  state.resolves = state.resolves + 1
  state.lastSpecies = species
  state.lastError = nil
  return renderer
end

local function rowForFacing(facing)
  if facing == "left" then return 1 end
  if facing == "right" then return 2 end
  if facing == "up" then return 3 end
  return 0
end

local function walkColumn(walkPhase)
  if tonumber(walkPhase) ~= 1 then return 0 end
  local ow = Game and Game.overworld or nil
  local player = ow and ow.player or nil
  local clock = tonumber(player and player.animClock) or 0
  return math.floor(clock / 8) % 4
end

local function decorateForGold(renderer, species)
  if not (renderer and renderer.def and renderer.def.dramaticSkyRideNativePokeMMO
      and renderer.image) then return renderer end
  if renderer.dramaticSkyRideGen2EmbeddedCrop then return renderer end

  local correction = mod.exports and mod.exports.nativePokeMMOSizeCorrection or nil
  local crop = correction and type(correction.cropForDef) == "function"
    and correction.cropForDef(renderer.def) or nil
  if not crop then return renderer end

  renderer.dramaticSkyRideGen2EmbeddedCrop = true
  renderer.dsrGen2EmbeddedQuads = renderer.dsrGen2EmbeddedQuads or {}

  local function quadFor(row, col)
    row = math.max(0, math.min(3, tonumber(row) or 0))
    col = math.max(0, math.min(3, tonumber(col) or 0))
    local key = row * 4 + col
    local quad = renderer.dsrGen2EmbeddedQuads[key]
    if quad then return quad end
    if not (love and love.graphics and love.graphics.newQuad) then return nil end
    quad = love.graphics.newQuad(
      col * crop.tileW + crop.left,
      row * crop.tileH + crop.top,
      crop.width, crop.height, crop.atlasW, crop.atlasH)
    renderer.dsrGen2EmbeddedQuads[key] = quad
    return quad
  end

  renderer.draw = function(self, px, py, camX, camY, facing, walkPhase,
                           _stepFlip, _topHalf)
    if not (love and love.graphics and love.graphics.draw) then return end
    local quad = quadFor(rowForFacing(facing), walkColumn(walkPhase))
    if not quad then return end

    local mountScale = 1
    local liveCorrection = mod.exports and mod.exports.nativePokeMMOSizeCorrection or nil
    if liveCorrection and type(liveCorrection.scale) == "function" then
      local okScale, value = pcall(liveCorrection.scale, species)
      value = okScale and tonumber(value) or nil
      if value and value > 0 then mountScale = value end
    end
    local scale = (tonumber(crop.fit) or 1) * mountScale
    local drawnW, drawnH = crop.width * scale, crop.height * scale
    local x = math.floor((px or 0) - (camX or 0))
    local y = math.floor((py or 0) - (camY or 0)) - 4
    local anchorX, anchorY = x + 8, y + 16

    if PaletteFX and PaletteFX.markTrueColor then
      PaletteFX.markTrueColor(
        math.floor(anchorX - drawnW / 2), math.floor(anchorY - drawnH),
        math.ceil(drawnW), math.ceil(drawnH))
    end
    love.graphics.draw(self.image, quad, anchorX, anchorY,
      0, scale, scale, crop.width / 2, crop.height)
  end
  return renderer
end

local function embeddedSprite(species, role)
  local renderer = resolveEmbeddedNative(species)
  if not renderer then return nil end
  decorateForGold(renderer, species)
  state[role] = (tonumber(state[role]) or 0) + 1
  return renderer
end

local previousFlightBuilder = buildMountSprite
buildMountSprite = function(species, ...)
  return embeddedSprite(species, "flight") or previousFlightBuilder(species, ...)
end

local previousGroundBuilder = buildGroundMountSprite
buildGroundMountSprite = function(species, ...)
  return embeddedSprite(species, "ground") or previousGroundBuilder(species, ...)
end

if type(buildWaterSprite) == "function" then
  local previousWaterBuilder = buildWaterSprite
  buildWaterSprite = function(species, ...)
    return embeddedSprite(species, "water") or previousWaterBuilder(species, ...)
  end
end

local function refreshActive2D()
  if not requested2D() then return end
  if flight and flight.active and flight.species then
    local ok, sprite = pcall(buildMountSprite, flight.species)
    if ok and sprite then flight.sprite = sprite end
  end
  if ground and ground.active and ground.species then
    local ok, sprite = pcall(buildGroundMountSprite, ground.species)
    if ok and sprite then ground.sprite = sprite end
  end
end

mod.events:on("mod.options_changed", function(payload)
  if not payload then return end
  if payload.mod == PROVIDER_ID and payload.key == "sprite_style" then
    refreshActive2D()
  elseif payload.mod == mod.id and payload.key == "flight_mount_renderer" then
    refreshActive2D()
  end
end)

mod.exports.gen2EmbeddedPokeMMOMounts = {
  api = 1,
  providerId = PROVIDER_ID,
  active = function() return embeddedContext() ~= nil end,
  resolve = function(species)
    local renderer = resolveEmbeddedNative(species)
    return renderer and decorateForGold(renderer, species) or nil
  end,
  status = function()
    local active = embeddedContext() ~= nil
    return {
      active = active,
      providerId = PROVIDER_ID,
      providerVersion = state.lastProviderVersion,
      style = state.lastStyle,
      resolves = state.resolves,
      flightResolves = state.flight,
      groundResolves = state.ground,
      waterResolves = state.water,
      lastSpecies = state.lastSpecies,
      lastError = state.lastError,
      requested2D = requested2D(),
      standaloneWilds = standaloneWildsInstalled(),
    }
  end,
}

log("Gen2 embedded HGSS/PokeMMO 2D mount bridge loaded")
end)();
