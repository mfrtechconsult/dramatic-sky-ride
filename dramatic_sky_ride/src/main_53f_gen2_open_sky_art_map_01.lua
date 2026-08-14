;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky illustrated regional map -- 2D-first runtime.
--
-- IMPORTANT: Gold's Game2 renderer treats an opaque state without a native
-- widescreen layer as a paper-white page. Open Sky is therefore implemented as
-- a real widescreen state, matching the contract used by Gold's own full-page
-- screens. This makes the 2D renderer independent from the live overworld zoom,
-- the Pokegear renderer and any Stadium/voxel compositor.
--
-- The supplied artwork is only a geographic backdrop. Its labels are never
-- trusted as game data: real Gold/Silver landmarks and visited Fly Points stay
-- authoritative and are projected onto the picture.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local mapImage = nil
local mapImageTried = false
local lastIllustratedDrawError = nil

local MAP_ASSET = "assets/open_sky_region_map.jpg"
local MAP_ASSET_PARTS = {
  "assets/open_sky_map/part01.b64",
  "assets/open_sky_map/part02.b64",
  "assets/open_sky_map/part03a.b64",
  "assets/open_sky_map/part03b.b64",
  "assets/open_sky_map/part04.b64",
}

local SCREEN_W, SCREEN_H = 160, 144
local MAP_TOP, MAP_BOTTOM = 18, 124
local MAP_HEIGHT = MAP_BOTTOM - MAP_TOP
local SOURCE_X0, SOURCE_X1 = 6, 154
local SOURCE_Y0, SOURCE_Y1 = 22, 138

-- Visual placement on the user-supplied combined Johto/Kanto artwork.
-- These rectangles are presentation only; actual landing availability still
-- comes from FieldMoves.flyPoints via main_53c.
local REGION_RECT = {
  johto = { x0 = 5,  x1 = 85,  y0 = 24, y1 = 105 },
  kanto = { x0 = 90, x1 = 154, y0 = 24, y1 = 105 },
}

local function clampMap(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function cleanMapName(value)
  return tostring(value or ""):gsub("\n", " ")
    :gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function rememberDrawError(kind, err)
  lastIllustratedDrawError = {
    kind = tostring(kind or "draw"),
    message = tostring(err or "unknown error"),
  }
  pcall(function()
    log("Open Sky 2D %s failed: %s",
      lastIllustratedDrawError.kind, lastIllustratedDrawError.message)
  end)
end

local function loadImageFromRaw(raw, filename)
  if type(raw) ~= "string" or raw == "" then return nil end
  if not (love and love.graphics and love.filesystem
      and love.filesystem.newFileData) then return nil end
  local okData, fileData = pcall(love.filesystem.newFileData, raw, filename)
  if not okData or not fileData then return nil end
  local okImage, image = pcall(love.graphics.newImage, fileData)
  if not okImage or not image then return nil end
  pcall(image.setFilter, image, "linear", "linear")
  return image
end

local function readMapBytes()
  if not (mod.read and love and love.data and love.data.decode) then return nil end
  local encoded = {}
  for _, relative in ipairs(MAP_ASSET_PARTS) do
    local okRead, part = pcall(mod.read, mod, relative)
    if not okRead or type(part) ~= "string" or part == "" then
      return nil
    end
    encoded[#encoded + 1] = part:gsub("%s", "")
  end
  local okDecode, raw = pcall(love.data.decode, "string", "base64",
    table.concat(encoded))
  return okDecode and type(raw) == "string" and raw or nil
end

local function loadMapImage()
  if mapImageTried then return mapImage end
  mapImageTried = true
  mapImage = loadImageFromRaw(readMapBytes(), "open_sky_region_map.jpg")
  return mapImage
end

local function project(region, x, y)
  local rect = REGION_RECT[region] or REGION_RECT.johto
  local nx = (clampMap(x, SOURCE_X0, SOURCE_X1) - SOURCE_X0)
    / (SOURCE_X1 - SOURCE_X0)
  local ny = (clampMap(y, SOURCE_Y0, SOURCE_Y1) - SOURCE_Y0)
    / (SOURCE_Y1 - SOURCE_Y0)
  return rect.x0 + nx * (rect.x1 - rect.x0),
    rect.y0 + ny * (rect.y1 - rect.y0)
end

local function visitedPoints(region)
  if type(playable.visitedPoints) ~= "function" then return {} end
  local ok, rows = pcall(playable.visitedPoints, region)
  return ok and type(rows) == "table" and rows or {}
end

local function drawFallbackGeography(G, state)
  -- Deliberately obvious fallback. If the JPEG cannot be decoded, Open Sky is
  -- still visibly alive instead of becoming Gold's white opaque-page surround.
  G.setColor(0.58, 0.80, 0.96, 1)
  G.rectangle("fill", 0, MAP_TOP, SCREEN_W, MAP_HEIGHT)

  G.setColor(0.20, 0.43, 0.27, 0.95)
  local rect = REGION_RECT[state.region] or REGION_RECT.johto
  G.rectangle("fill", rect.x0, rect.y0,
    math.max(1, rect.x1 - rect.x0), math.max(1, rect.y1 - rect.y0))

  -- A simple coast-like inset makes the fallback unmistakable from a blank
  -- page while requiring only core LOVE primitives.
  G.setColor(0.58, 0.80, 0.96, 1)
  G.rectangle("line", rect.x0 + 4, rect.y0 + 4,
    math.max(1, rect.x1 - rect.x0 - 8), math.max(1, rect.y1 - rect.y0 - 8))
end

local function drawBackdrop(G, state)
  local image = loadMapImage()
  if not image then
    drawFallbackGeography(G, state)
    return false
  end

  G.setColor(0.58, 0.80, 0.96, 1)
  G.rectangle("fill", 0, MAP_TOP, SCREEN_W, MAP_HEIGHT)

  local iw, ih = image:getDimensions()
  local scale = math.min(SCREEN_W / math.max(1, iw),
    MAP_HEIGHT / math.max(1, ih))
  local dw, dh = iw * scale, ih * scale
  G.setColor(1, 1, 1, 1)
  G.draw(image, (SCREEN_W - dw) * 0.5,
    MAP_TOP + (MAP_HEIGHT - dh) * 0.5, 0, scale, scale)
