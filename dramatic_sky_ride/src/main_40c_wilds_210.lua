;(function()
local WILDS_ID = "overworld_wild_spawns"
local state = {
  epoch = 0,
  cache = {},
  resolves = 0,
  blockedGroundBattles = 0,
  battleGateInstalled = false,
  lastSpecies = nil,
  lastSurface = nil,
  lastProvider = nil,
  lastError = nil,
}

local function isGold()
  local generation = mod.exports and mod.exports.runtimeGeneration or nil
  if not (generation and type(generation.isGen2) == "function") then return false end
  local ok, value = pcall(generation.isGen2, Game)
  return ok and value == true
end

local function wildsExports()
  if type(mod.find) ~= "function" then return nil end
  local ok, handle = pcall(mod.find, mod, WILDS_ID)
  return ok and handle and handle.exports or nil
end

local function copyDef(source)
  local out = {}
  for k, v in pairs(source or {}) do out[k] = v end
  return out
end

local function usableDef(def, surface)
  if type(def) ~= "table" or type(def.image) ~= "string" or def.image == "" then
    return false
  end
  if def.fallback == true or tostring(def.providerId or ""):lower() == "fallback" then
    return false
  end
  if surface == "water" then
    local got = tostring(def.surface or ""):lower()
    if got ~= "water" and got ~= "surfing" then return false end
  end
  return (tonumber(def.frames) or 1) >= 6 and def.walker ~= false
end

local function resolveDef(species, surface, role)
  if not (isGold() and species) then return nil end
  local ex = wildsExports()
  local resolve = ex and ex.resolveFollowerSprite
  if type(resolve) ~= "function" then return nil end

  local opts = {
    species = species,
    surface = surface,
    role = role,
    game = Game,
  }
  local ok, def = pcall(resolve, opts)
  if ok and usableDef(def, surface) then return def end

  if surface == "land" then
    opts.style = "followers"
    ok, def = pcall(resolve, opts)
    if ok and usableDef(def, surface) then return def end
  end
  if not ok then state.lastError = tostring(def) end
  return nil
end

local function mountScale(species)
  local fn = mod.exports and mod.exports.mountVisualScale or nil
  if type(fn) == "function" then
    local ok, value = pcall(fn, species)
    value = ok and tonumber(value) or nil
    if value and value > 0 then return value end
  end
  return 1
end

local function geometry(def)
  local fw = math.max(1, tonumber(def and def.frameWidth) or 16)
  local fh = math.max(1, tonumber(def and def.frameHeight) or 16)
  local ax = tonumber(def and def.anchorX)
  local ay = tonumber(def and def.anchorY)
  if ax == nil then ax = fw / 2 end
  if ay == nil then ay = fh end
  return fw, fh, ax, ay
end

local function cardFit(def)
  local fw, fh = geometry(def)
  return math.min(16 / fw, 16 / fh, 1)
end

local function decorateRenderer(renderer, species, provider, surface)
  if not (renderer and renderer.def) then return renderer end
  if renderer.dramaticSkyRideWilds21Decorated then return renderer end
  renderer.dramaticSkyRideWilds21Decorated = true
  renderer.def.dramaticSkyRideMountSpecies = species
  renderer.def.dramaticSkyRideWilds21 = true
  renderer.def.dramaticSkyRideWildsProvider = provider
  renderer.def.dramaticSkyRideWildsSurface = surface

  local rawDraw = renderer.draw
  renderer.draw = function(self, px, py, camX, camY, facing, walkPhase,
                           stepFlip, topHalf, ...)
    if topHalf or not (love and love.graphics and love.graphics.draw) then
      return rawDraw(self, px, py, camX, camY, facing, walkPhase,
                     stepFlip, topHalf, ...)
    end

    local def = self.def or {}
    local pose = nil
    if type(self.getPoseGeometry) == "function" then
      local ok, value = pcall(self.getPoseGeometry, self, facing, walkPhase, stepFlip)
      if ok and type(value) == "table" then pose = value end
    end

    local frame, mirror, quad = 0, false, nil
    local fw, fh, ax, ay = geometry(def)
    if pose then
      frame = tonumber(pose.frame) or 0
      mirror = pose.mirror == true
      quad = pose.quad
      fw = tonumber(pose.width) or fw
      fh = tonumber(pose.height) or fh
      ax = tonumber(pose.anchorX) or ax
      ay = tonumber(pose.anchorY) or ay
    else
      if (def.frames or 1) > 1 then
        frame = (def.walker and walkPhase == 1)
          and SpriteRenderer.WALK[facing] or SpriteRenderer.STAND[facing]
      end
      mirror = facing == "right"
        or ((facing == "down" or facing == "up")
          and walkPhase == 1 and stepFlip)
      quad = self.frames and (self.frames[frame] or self.frames[0])
    end
    if not quad then
      return rawDraw(self, px, py, camX, camY, facing, walkPhase,
                     stepFlip, topHalf, ...)
    end

    local image = self.image
    if type(self.resolveImage) == "function" then
      local ok, resolved = pcall(self.resolveImage, self)
      if ok and resolved then image = resolved end
    end
    if not image then
      return rawDraw(self, px, py, camX, camY, facing, walkPhase,
                     stepFlip, topHalf, ...)
    end

    local scale = cardFit(def) * mountScale(species)
    local baseX = math.floor((px or 0) - (camX or 0)) + 8
    local baseY = math.floor((py or 0) - (camY or 0)) + 12
    if def.trueColor and PaletteFX and PaletteFX.markTrueColor then
      local left = mirror and (baseX - (fw - ax) * scale)
        or (baseX - ax * scale)
      local top = baseY - ay * scale
      PaletteFX.markTrueColor(math.floor(left), math.floor(top),
        math.ceil(fw * scale), math.ceil(fh * scale))
    end

    love.graphics.draw(image, quad, baseX, baseY, 0,
      mirror and -scale or scale, scale, ax, ay)
  end
  return renderer
end

local function cacheKey(species, surface, role)
  return table.concat({ tostring(state.epoch), tostring(species),
    tostring(surface), tostring(role) }, "|")
end

local function buildWildsRenderer(species, surface, role)
  if not isGold() then return nil end
  local key = cacheKey(species, surface, role)
  if state.cache[key] ~= nil then return state.cache[key] or nil end

  local provided = resolveDef(species, surface, role)
  if not provided then
    state.cache[key] = false
    return nil
  end

  local def = copyDef(provided)
  def.id = string.format("DSR_WILDS21_%s_%s", tostring(surface):upper(), tostring(species))
  local ok, renderer = pcall(SpriteRenderer.new, def,
    string.format("dsr_wilds21_%s_%s", tostring(surface), tostring(species)))
  if not (ok and renderer) then
    state.lastError = tostring(renderer)
    state.cache[key] = false
    return nil
  end
  if renderer.image then setNearest(renderer.image) end
  renderer = decorateRenderer(renderer, species, provided.providerId, surface)
  state.cache[key] = renderer
  state.resolves = state.resolves + 1
  state.lastSpecies = species
  state.lastSurface = surface
  state.lastProvider = provided.providerId
  state.lastError = nil
  return renderer
end

local function installBattleGate()
  if not isGold() then return false end
  local ex = wildsExports()
  local logic = ex and ex.logic or nil
  if not (type(logic) == "table" and type(logic._startBattle) == "function") then
    return false
  end
  local marker = logic._dramaticSkyRideGen2FlightGate
  if type(marker) == "table" and marker.owner == mod.id
      and logic._startBattle == marker.wrapper then
    state.battleGateInstalled = true
    return true
  end
  local raw = logic._startBattle
  local wrapper = function(self, record, ...)
    if isGold() and flight and flight.active == true then
      state.blockedGroundBattles = state.blockedGroundBattles + 1
      return false
    end
    return raw(self, record, ...)
  end
  logic._startBattle = wrapper
  logic._dramaticSkyRideGen2FlightGate = {
    owner = mod.id,
    raw = raw,
    wrapper = wrapper,
  }
  state.battleGateInstalled = true
  return true
end

local previousFlightBuilder = buildMountSprite
if type(previousFlightBuilder) == "function" then
  buildMountSprite = function(species, ...)
    return buildWildsRenderer(species, "land", "flight_mount")
      or previousFlightBuilder(species, ...)
  end
end

local previousGroundBuilder = buildGroundMountSprite
if type(previousGroundBuilder) == "function" then
  buildGroundMountSprite = function(species, ...)
    return buildWildsRenderer(species, "land", "ground_mount")
      or previousGroundBuilder(species, ...)
  end
end

local previousWaterVisual = mod.exports and mod.exports._waterRideVisual or nil
local function currentWaterSpecies()
  local active = mod.exports and mod.exports.isWaterRiding or nil
  local species = mod.exports and mod.exports.waterMountSpecies or nil
  if not (type(active) == "function" and type(species) == "function") then return nil end
  local okActive, yes = pcall(active)
  if not (okActive and yes == true) then return nil end
  local okSpecies, value = pcall(species)
  return okSpecies and value or nil
end

if type(previousWaterVisual) == "function" then
  mod.exports._waterRideVisual = function(...)
    if isGold() then
      local species = currentWaterSpecies()
      local renderer = species and buildWildsRenderer(species, "water", "surf_mount") or nil
      if renderer then return renderer end
    end
    return previousWaterVisual(...)
  end
end

local function clearCache()
  state.epoch = state.epoch + 1
  state.cache = {}
end

local function refreshActiveMounts()
  if not isGold() then return end
  if flight and flight.active and flight.species and type(buildMountSprite) == "function" then
    local ok, sprite = pcall(buildMountSprite, flight.species)
    if ok and sprite then flight.sprite = sprite end
  end
  if ground and ground.active and ground.species and type(buildGroundMountSprite) == "function" then
    local ok, sprite = pcall(buildGroundMountSprite, ground.species)
    if ok and sprite then ground.sprite = sprite end
  end
end

mod.events:on("mods.loaded", installBattleGate)
mod.events:on("game.ready", installBattleGate)
mod.events:on("mod.options_changed", function(payload)
  if not payload then return end
  if payload.mod == WILDS_ID then
    clearCache()
    refreshActiveMounts()
    installBattleGate()
  elseif payload.mod == mod.id then
    local key = tostring(payload.key or "")
    if key == "pokedex_mount_sizes" or key:match("^mount_size_") then
      clearCache()
      refreshActiveMounts()
    end
  end
end)
if Assets and Assets.register then Assets.register(clearCache) end

local compat = mod.exports.wildsCompatibility
if type(compat) == "table" then
  compat.version = function()
    local ex = wildsExports()
    return ex and ex.version or nil
  end
  compat.gen2PublicSpriteBridge = function()
    local ex = wildsExports()
    return isGold() and ex ~= nil and type(ex.resolveFollowerSprite) == "function"
  end
  compat.blockedGroundBattles = function() return state.blockedGroundBattles end
  compat.lastResolvedProvider = function() return state.lastProvider end
end

mod.exports.wilds210Compatibility = {
  api = 1,
  targetRelease = "2.1.0",
  installed = function() return wildsExports() ~= nil end,
  version = function()
    local ex = wildsExports()
    return ex and ex.version or nil
  end,
  active = function()
    local ex = wildsExports()
    return isGold() and ex ~= nil and type(ex.resolveFollowerSprite) == "function"
  end,
  status = function()
    local ex = wildsExports()
    return {
      active = isGold() and ex ~= nil,
      version = ex and ex.version or nil,
      resolves = state.resolves,
      blockedGroundBattles = state.blockedGroundBattles,
      battleGateInstalled = state.battleGateInstalled,
      lastSpecies = state.lastSpecies,
      lastSurface = state.lastSurface,
      lastProvider = state.lastProvider,
      lastError = state.lastError,
    }
  end,
}

installBattleGate()
log("Wilds of Kanto 2.1 Gen2 compatibility loaded")
end)();
