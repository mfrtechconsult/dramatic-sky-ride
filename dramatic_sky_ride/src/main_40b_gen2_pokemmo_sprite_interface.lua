;(function()
-- -------------------------------------------------------------------------
-- Gen 2 SpriteRenderer interface adapter for DSR's native HGSS/PokeMMO cards.
--
-- Gold's world palette pass calls :setObjPalette() on every live actor sprite.
-- DSR's high-resolution PokeMMO renderer is intentionally true-color and does
-- not use the GBC OBJ palette bake, but it still has to implement the same
-- method contract as src.render.SpriteRenderer or Gold will crash as soon as
-- World:applySpritePalette() reaches a mounted player.
--
-- Keep this adapter source-agnostic: it covers both standalone Wilds and the
-- Wilds runtime embedded by STADIUM2_OVERWORLD_MODELS. The renderer remains
-- true-color; palette data is remembered only to satisfy/diagnose the engine
-- contract and is never applied to the source atlas.
-- -------------------------------------------------------------------------

local function nativePokeMMORenderer(renderer)
  return renderer and renderer.def
    and renderer.def.dramaticSkyRideNativePokeMMO == true
end

local function decorate(renderer)
  if not nativePokeMMORenderer(renderer) then return renderer end
  if renderer.dramaticSkyRideGen2SpriteInterface then return renderer end

  if type(renderer.setObjPalette) ~= "function" then
    function renderer:setObjPalette(colors, group)
      -- SpriteRenderer stores these fields before resolveImage()/draw(). Our
      -- atlas is trueColor, so retaining the values is enough while avoiding
      -- an incorrect palette bake over HGSS/PokeMMO art.
      self.objColors = colors
      self.objGroup = group or "gen2"
      return self
    end
  end

  -- Mirror the harmless metadata exposed by SpriteRenderer. A few render
  -- pipelines inspect these fields even when they do not call its geometry
  -- helpers. The actual DSR draw/voxel paths continue to use the native 4x4
  -- atlas and opaque crop established by main_38/main_40.
  renderer.frameCount = tonumber(renderer.frameCount)
    or tonumber(renderer.def.frames) or 6
  renderer.frameWidth = tonumber(renderer.frameWidth)
    or tonumber(renderer.def.dramaticSkyRideNativeTileW) or 16
  renderer.frameHeight = tonumber(renderer.frameHeight)
    or tonumber(renderer.def.dramaticSkyRideNativeTileH) or 16
  renderer.anchorX = tonumber(renderer.anchorX) or renderer.frameWidth / 2
  renderer.anchorY = tonumber(renderer.anchorY) or renderer.frameHeight

  renderer.dramaticSkyRideGen2SpriteInterface = true
  return renderer
end

local function wrapBuilder(name)
  local current = _G[name]
  if type(current) ~= "function" then return end
  _G[name] = function(...)
    return decorate(current(...))
  end
end

-- These builders are globals in DSR's concatenated runtime and are the paths
-- used by Flight, Ground Ride and Visible Surf respectively.
wrapBuilder("buildMountSprite")
wrapBuilder("buildGroundMountSprite")
wrapBuilder("buildWaterSprite")

-- main_40a resolves through this export directly, so decorate that public seam
-- as well. This also covers callers that bypass the builders for diagnostics.
local nativeApi = mod.exports and mod.exports.nativePokeMMOMounts or nil
if nativeApi and type(nativeApi.resolve) == "function"
    and nativeApi.dramaticSkyRideGen2Interface ~= true then
  local previousResolve = nativeApi.resolve
  nativeApi.resolve = function(...)
    return decorate(previousResolve(...))
  end
  nativeApi.dramaticSkyRideGen2Interface = true
end

local embeddedApi = mod.exports and mod.exports.gen2EmbeddedPokeMMOMounts or nil
if embeddedApi and type(embeddedApi.resolve) == "function"
    and embeddedApi.dramaticSkyRideGen2Interface ~= true then
  local previousResolve = embeddedApi.resolve
  embeddedApi.resolve = function(...)
    return decorate(previousResolve(...))
  end
  embeddedApi.dramaticSkyRideGen2Interface = true
end

mod.exports.gen2PokeMMOSpriteInterface = {
  api = 1,
  decorate = decorate,
  compatible = function(renderer)
    return nativePokeMMORenderer(renderer)
      and type(renderer.setObjPalette) == "function"
  end,
}

log("Gen2 HGSS/PokeMMO SpriteRenderer interface adapter loaded")
end)();
