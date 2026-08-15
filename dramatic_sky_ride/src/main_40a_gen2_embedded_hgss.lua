;(function()
-- Gen2-3D-Sprites embedded sprite-provider bridge.
--
-- STADIUM2_OVERWORLD_MODELS embeds Wilds instead of exposing a standalone
-- overworld_wild_spawns handle. 0.2.81 also defaults its 2D Pokemon art to the
-- built-in Poke Followers/GSC provider, while older DSR code only recognized
-- the explicit PokeMMO style. That left Flight/Ground/Surf without the selected
-- Pokemon sprite whenever Stadium 3D fell back to 2D.
--
-- Treat Randy's public wilds.spriteProviders registry as the authoritative 2D
-- source. Keep the native high-resolution PokeMMO path when that style is
-- selected, but accept any six-frame walker returned by the embedded provider
-- chain (notably the new default "followers" style). The 2D sprite is prepared
-- even while Stadium 3D is requested so an unavailable/disabled model can fall
-- back immediately without turning the mount invisible.

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local WILDS_ID = "overworld_wild_spawns"
local PaletteFX = require("src.render.PaletteFX")
local state = {
  resolves = 0,
  providerResolves = 0,
  nativeResolves = 0,
  sourceRegistered = false,
  lastSpecies = nil,
  lastStyle = nil,
  lastProviderId = nil,
  lastError = nil,
}
local providerRendererCache = {}

local function isGold()
  local generation = mod.exports and mod.exports.runtimeGeneration or nil
  if generation and type(generation.isGen2) == "function" then
    local ok, value = pcall(generation.isGen2, Game)
    return ok and value == true
  end
  return false
end

local function findHandle(id)
  if type(mod.find) ~= "function" then return nil end
  local ok, handle = pcall(mod.find, mod, id)
  if ok and handle then return handle end
  ok, handle = pcall(mod.find, id)
  return ok and handle or nil
end

local function providerContext(exportsOverride)
  if not isGold() or findHandle(WILDS_ID) then return nil end
  local provider = findHandle(PROVIDER_ID)
  local ex = exportsOverride or (provider and provider.exports) or nil
  local wilds = ex and ex.wilds or nil
  if type(wilds) ~= "table" then return nil end

  -- 0.2.81 exposes a standalone-Wilds-compatible resolveFollowerSprite()
  -- directly on its embedded export. Prefer that public seam: unlike the
  -- internal SpriteProviders object it is explicitly intended for companion
  -- mods and already translates the selected style into a sandbox-safe asset
  -- path. Keep spriteProviders only as a compatibility fallback.
  local directResolve = type(wilds.resolveFollowerSprite) == "function"
  local spriteProviders = wilds.spriteProviders
  local registryResolve = type(spriteProviders) == "table"
    and type(spriteProviders.resolve) == "function"
  if not directResolve and not registryResolve then return nil end

  local style = "followers"
  local render = wilds.render
  local wildsMod = render and render.mod or nil
  local options = wildsMod and wildsMod.options or nil
  if options and type(options.get) == "function" then
    local okStyle, value = pcall(options.get, options, "sprite_style")
    if okStyle and value ~= nil then style = tostring(value):lower() end
  end
  state.lastStyle = style
  return {
    provider = provider,
    exports = ex,
    wilds = wilds,
    spriteProviders = spriteProviders,
    directResolve = directResolve,
    registryResolve = registryResolve,
    style = style,
  }
end

local function copyMountDef(def, species, providerId, style)
  if type(def) ~= "table" or type(def.image) ~= "string" or def.image == "" then
    return nil
  end
  local frames = tonumber(def.frames) or 1
  -- DSR's mounted walker contract is six directional/walk frames. Static
  -- Pokédex cards remain an intentional fallback to DSR's own mount art.
  if frames < 6 or def.walker == false then return nil end

  local out = {}
  for k, v in pairs(def) do out[k] = v end
  out.frames = frames
  out.walker = true
  out.trueColor = def.trueColor ~= false
  out.id = "DSR_GEN2_PROVIDER_" .. tostring(species)
  out.dramaticSkyRideMountSpecies = species
  out.dramaticSkyRideEmbeddedSpriteProvider = true
  out.dramaticSkyRideEmbeddedProviderId = providerId
  out.dramaticSkyRideEmbeddedStyle = style
  return out
end

local function speciesDex(species)
  local cfg = (ELIGIBLE and ELIGIBLE[species])
    or (GROUND_ELIGIBLE and GROUND_ELIGIBLE[species])
  if cfg and tonumber(cfg.dex) then return math.floor(tonumber(cfg.dex)) end
  local pokemon = Game and Game.data and Game.data.pokemon or nil
  local def = pokemon and pokemon[species] or nil
  return def and tonumber(def.dex) and math.floor(tonumber(def.dex)) or nil
end

local function directProviderAttempt(ctx, species, style)
  if not (ctx and ctx.directResolve and type(ctx.wilds.resolveFollowerSprite) == "function") then
    return nil, nil
  end
  local dex = speciesDex(species)
  local ok, raw = pcall(ctx.wilds.resolveFollowerSprite, {
    species = species,
    dex = dex,
    surface = "land",
    style = style,
    role = "mount",
    game = mod.game or (mod.world and mod.world.game) or Game,
  })
  if not ok then return nil, tostring(raw) end
  if type(raw) == "table" and raw.def then raw = raw.def end
  if type(raw) ~= "table" then return nil, "direct resolver returned no definition" end
  return raw, nil
end

local function registryProviderAttempt(ctx, species, style)
  if not (ctx and ctx.registryResolve and ctx.spriteProviders) then return nil, nil, nil end
  local ok, result = pcall(ctx.spriteProviders.resolve, ctx.spriteProviders,
    style, species, "normal", mod.game or (mod.world and mod.world.game) or Game)
  if not ok then return nil, nil, tostring(result) end
  return type(result) == "table" and result.def or nil, result, nil
end

local function resolveProviderDef(species, exportsOverride)
  local ctx = providerContext(exportsOverride)
  if not (ctx and species) then return nil, nil, ctx end

  -- A static Pokédex front is not a mount. Try the user's current selection
  -- first, then Randy's built-in Followers/GSC walker, then PokeMMO. This also
  -- means a user can leave Randy on POKEDEX for roaming mons while DSR still
  -- gets a real animated six-frame Pokemon for riding.
  local styles, seen = {}, {}
  for _, style in ipairs({ ctx.style, "followers", "pokemmo" }) do
    style = tostring(style or "followers"):lower()
    if not seen[style] then styles[#styles + 1], seen[style] = style, true end
  end

  local lastResult, lastError = nil, nil
  for _, style in ipairs(styles) do
    local rawDef, directErr = directProviderAttempt(ctx, species, style)
    local providerId = rawDef and (rawDef.providerId or style) or nil
    local def = copyMountDef(rawDef, species, providerId, style)
    if def then
      state.providerResolves = state.providerResolves + 1
      state.lastSpecies = species
      state.lastProviderId = providerId or "embedded_direct"
      state.lastStyle = style
      state.lastError = nil
      return def, { def = rawDef, providerId = providerId }, ctx
    end
    if directErr then lastError = directErr end

    local registryDef, result, registryErr = registryProviderAttempt(ctx, species, style)
    lastResult = result or lastResult
    providerId = type(result) == "table" and result.providerId or nil
    def = copyMountDef(registryDef, species, providerId, style)
    if def then
      state.providerResolves = state.providerResolves + 1
      state.lastSpecies = species
      state.lastProviderId = providerId or "embedded_registry"
      state.lastStyle = style
      state.lastError = nil
      return def, result, ctx
    end
    if registryErr then lastError = registryErr end
  end

  state.lastError = lastError or "embedded provider returned no six-frame walker"
  return nil, lastResult, ctx
end

local function rendererFromProvider(species)
  local def, result, ctx = resolveProviderDef(species)
  if not def then return nil end

  local key = table.concat({
    tostring(species), tostring(ctx and ctx.style), tostring(def.image),
    tostring(def.frames), tostring(result and result.providerId),
  }, "|")
  local cached = providerRendererCache[key]
  if cached then return cached end

  local ok, renderer = pcall(SpriteRenderer.new, def,
    "dsr_gen2_provider_" .. tostring(species))
  if not ok or not renderer then
    state.lastError = tostring(renderer or "SpriteRenderer.new failed")
    return nil
  end
  providerRendererCache[key] = renderer
  return renderer
end

-- Preserve the existing native PokeMMO resolver. It expects a standalone
-- overworld_wild_spawns handle, so expose Randy's embedded Wilds exports only
-- during this synchronous call. Nothing is persisted or patched globally.
local function resolveNativePokeMMO(species)
  local ctx = providerContext()
  local api = mod.exports and mod.exports.nativePokeMMOMounts or nil
  if not (ctx and ctx.style == "pokemmo" and api and type(api.resolve) == "function"
      and type(mod.find) == "function") then
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
  if renderer then
    state.nativeResolves = state.nativeResolves + 1
    state.lastSpecies = species
    state.lastProviderId = "pokemmo_native"
    state.lastError = nil
  end
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
  local ow = Game and (Game.overworld or Game.world) or nil
  local player = ow and ow.player or nil
  local clock = tonumber(player and player.animClock) or 0
  return math.floor(clock / 8) % 4
end

local function decorateNative(renderer, species)
  if not (renderer and renderer.def and renderer.def.dramaticSkyRideNativePokeMMO) then
    return renderer
  end

  if type(renderer.setObjPalette) ~= "function" then
    function renderer:setObjPalette(colors, group)
      self.objColors = colors
      self.objGroup = group or "gen2"
      return self
    end
  end

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

  renderer.draw = function(self, px, py, camX, camY, facing, walkPhase)
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

local function resolveEmbeddedRenderer(species)
  if not species then return nil end
  local native = decorateNative(resolveNativePokeMMO(species), species)
  local renderer = native or rendererFromProvider(species)
  if renderer then
    state.resolves = state.resolves + 1
    state.lastSpecies = species
  end
  return renderer
end

-- Also register Randy as a normal DSR sprite source. This makes the provider
-- visible through airborneSpriteSources() and lets the existing followerPath
-- chain use the same public contract whenever the direct renderer wrapper is
-- not involved.
local function registerSource()
  local register = mod.exports and mod.exports.registerSpriteSource or nil
  if type(register) ~= "function" then return false end
  local ok, registered = pcall(register, {
    id = PROVIDER_ID,
    mod = PROVIDER_ID,
    resolve = function(exports, game, species, dex)
      if not isGold() then return nil end
      local key = species or dex
      local def, result = resolveProviderDef(key, exports)
      if not def then return nil end
      return {
        image = def.image,
        frames = def.frames,
        walker = def.walker,
        trueColor = def.trueColor,
        providerId = result and result.providerId or nil,
      }
    end,
  })
  state.sourceRegistered = ok and registered == true
  return state.sourceRegistered
end

-- Flight and Ground always retain a ready 2D Pokemon sprite, including while
-- Stadium 3D is requested. main_28 decides whether that sprite or the model is
-- actually presented this frame.
local previousFlightBuilder = buildMountSprite
if type(previousFlightBuilder) == "function" then
  buildMountSprite = function(species, ...)
    local embedded = resolveEmbeddedRenderer(species)
    return embedded or previousFlightBuilder(species, ...)
  end
end

local previousGroundBuilder = buildGroundMountSprite
if type(previousGroundBuilder) == "function" then
  buildGroundMountSprite = function(species, ...)
    local embedded = resolveEmbeddedRenderer(species)
    return embedded or previousGroundBuilder(species, ...)
  end
end

local function clearProviderCache()
  providerRendererCache = {}
end

local function refreshActiveSprites()
  if flight and flight.active and flight.species and type(buildMountSprite) == "function" then
    local ok, sprite = pcall(buildMountSprite, flight.species)
    if ok and sprite then flight.sprite = sprite end
  end
  if ground and ground.active and ground.species and type(buildGroundMountSprite) == "function" then
    local ok, sprite = pcall(buildGroundMountSprite, ground.species)
    if ok and sprite then ground.sprite = sprite end
  end
end

mod.events:on("mods.loaded", function()
  if not state.sourceRegistered then registerSource() end
end)

mod.events:on("mod.options_changed", function(payload)
  if not payload then return end
  if payload.mod == PROVIDER_ID then
    local key = tostring(payload.key or "")
    if key == "sprite_style" or key == "stadium3dSprites" then
      clearProviderCache()
      refreshActiveSprites()
    end
  elseif payload.mod == mod.id and payload.key == "flight_mount_renderer" then
    refreshActiveSprites()
  end
end)

mod.exports.gen2EmbeddedSpriteMounts = {
  api = 4,
  providerId = PROVIDER_ID,
  active = function() return providerContext() ~= nil end,
  resolve = resolveEmbeddedRenderer,
  resolveProviderDef = function(species) return resolveProviderDef(species) end,
  status = function()
    return {
      active = providerContext() ~= nil,
      sourceRegistered = state.sourceRegistered,
      resolves = state.resolves,
      providerResolves = state.providerResolves,
      nativeResolves = state.nativeResolves,
      lastSpecies = state.lastSpecies,
      style = state.lastStyle,
      providerId = state.lastProviderId,
      lastError = state.lastError,
    }
  end,
}

-- Backward-compatible name used by main_40b and older diagnostics.
mod.exports.gen2EmbeddedPokeMMOMounts = mod.exports.gen2EmbeddedSpriteMounts

registerSource()
log("Gen2 embedded Wilds sprite-provider bridge loaded")
end)();
