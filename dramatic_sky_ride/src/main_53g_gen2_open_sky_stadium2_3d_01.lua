;(function()
-- -------------------------------------------------------------------------
-- Gen2 Open Sky: large regional 3D terrain baked from the user's GLB.
--
-- Source model:
--   Meshy_AI_map_monde_de_la_regio_0812201706_texture.glb
--
-- The raw GLB is ~82 MB / ~1.95M triangles, far too heavy to parse and upload
-- every frame in the current Lua/LÖVE mod runtime. It is therefore baked once
-- into a textured heightfield (same model relief + albedo) and rendered by the
-- already installed Gen2-3D-Sprites Voxel3D provider. The old illustrated town
-- map is only a fallback if this scene cannot initialize.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local HEIGHT_ASSET_PARTS = {
  "assets/open_sky_glb/height_part01.b64",
}
local ALBEDO_ASSET_PARTS = {
  "assets/open_sky_glb/albedo_part01.b64",
  "assets/open_sky_glb/albedo_part02.b64",
  "assets/open_sky_glb/albedo_part03.b64",
  "assets/open_sky_glb/albedo_part04.b64",
  "assets/open_sky_glb/albedo_part05.b64",
  "assets/open_sky_glb/albedo_part06.b64",
  "assets/open_sky_glb/albedo_part07.b64",
  "assets/open_sky_glb/albedo_part08.b64",
  "assets/open_sky_glb/albedo_part09.b64",
  "assets/open_sky_glb/albedo_part10.b64",
  "assets/open_sky_glb/albedo_part11.b64",
}

local SCREEN_W, SCREEN_H = 160, 144
local SOURCE_X0, SOURCE_X1 = 6, 154
local SOURCE_Y0, SOURCE_Y1 = 22, 138

-- This is intentionally a REGION, not a miniature map. The player only sees a
-- local slice from the chase camera and must actually cross the terrain.
local WORLD_X0, WORLD_X1 = -650, 650
local WORLD_Z0, WORLD_Z1 = -500, 500
local WORLD_RELIEF = 112
-- Open Sky uses an absolute flight level, not terrain-following clearance.
-- Highest terrain is WORLD_RELIEF; keeping the mount well above that removes
-- the roller-coaster motion over mountains/valleys while preserving manual
-- altitude input as a deliberate adjustment.
local CRUISE_FLIGHT_Y = WORLD_RELIEF + 92
local ALTITUDE_INPUT_SCALE = 0.70
local MAX_RENDER_W, MAX_RENDER_H = 1920, 1080

-- Gold's Johto/Kanto town-map coordinates remain authoritative for progression
-- and landing points. They are projected into two contiguous halves of the
-- supplied regional model so crossing the seam still has real spatial meaning.
local REGION_RECT = {
  johto = { WORLD_X0 + 24, -10, WORLD_Z0 + 28, WORLD_Z1 - 28 },
  kanto = { 10, WORLD_X1 - 24, WORLD_Z0 + 28, WORLD_Z1 - 28 },
}

local patched = setmetatable({}, { __mode = "k" })
local cache = {}

local function resetCache()
  cache = {
    provider = nil,
    Voxel3D = nil,
    mesh = nil,
    texture = nil,
    heights = nil,
    w = 0,
    h = 0,
    ready = false,
    disabled = false,
    stage = "INIT",
    error = nil,
  }
end
resetCache()

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function setStage(stage, err)
  cache.stage = tostring(stage or "?")
  cache.error = err and tostring(err) or nil
end

local function disableThreeD(stage, err)
  cache.disabled = true
  cache.ready = false
  setStage(stage or "ERR", err or "Open Sky 3D error")
  pcall(function()
    log("Open Sky GLB terrain disabled [%s]: %s", cache.stage, cache.error)
  end)
end

local function provider()
  if cache.provider and type(cache.provider.lib) == "table"
      and type(cache.provider.lib.require) == "function" then
    return cache.provider
  end
  if type(mod.find) ~= "function" then
    setStage("NOAPI", "mod.find unavailable")
    return nil
  end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then ok, handle = pcall(function() return mod.find(PROVIDER_ID) end) end
  if not ok or not handle then
    setStage("NOMOD", "Gen2-3D-Sprites not found")
    return nil
  end
  local ex = handle.exports
  if type(ex) ~= "table" or type(ex.lib) ~= "table"
      or type(ex.lib.require) ~= "function" then
    setStage("NOLIB", "provider lib.require unavailable")
    return nil
  end
  cache.provider = ex
  setStage("PROVIDER")
  return ex
end

local function readImageData(parts, filename)
  if not (mod.read and love and love.data and love.data.decode
      and love.image and love.image.newImageData
      and love.filesystem and love.filesystem.newFileData) then
    return nil, "image decoder unavailable"
  end
  local encoded = {}
  for _, relative in ipairs(parts or {}) do
    local okRead, part = pcall(mod.read, mod, relative)
    if not okRead or type(part) ~= "string" or part == "" then
      return nil, "asset unavailable: " .. tostring(relative)
    end
    encoded[#encoded + 1] = part:gsub("%s", "")
  end
  local okDecode, raw = pcall(love.data.decode, "string", "base64",
    table.concat(encoded))
  if not okDecode or type(raw) ~= "string" or raw == "" then
    return nil, "base64 decode failed: " .. tostring(filename)
  end
  local okData, data = pcall(love.filesystem.newFileData, raw, filename)
  if not okData or not data then return nil, "FileData failed: " .. tostring(filename) end
  local okImage, image = pcall(love.image.newImageData, data)
  if not okImage or not image then return nil, "ImageData failed: " .. tostring(filename) end
  return image
end

local function readTexture()
  local imageData, err = readImageData(ALBEDO_ASSET_PARTS, "open_sky_glb_albedo.png")
  if not imageData then return nil, err end
  if not (love and love.graphics and love.graphics.newImage) then
