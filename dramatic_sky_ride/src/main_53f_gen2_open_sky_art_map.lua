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
  return true
end

local function drawLandingPoints(G, state)
  local nearestSpawn = state.nearest and state.nearest.row
    and state.nearest.row.spawn or nil
  for _, point in ipairs(visitedPoints(state.region)) do
    local anchor = point and point.anchor
    if anchor then
      local x, y = project(state.region, anchor.x, anchor.y)
      local selected = nearestSpawn ~= nil and point.row
        and point.row.spawn == nearestSpawn
      if selected then
        G.setColor(1, 1, 1, 0.98)
        G.circle("line", x, y, 4.5)
      end
      G.setColor(1, 1, 1, 0.95)
      G.circle("fill", x, y, selected and 2.0 or 1.35)
    end
  end
end

local function drawMountMiniature(G, state, x, y)
  local sprite = flight.sprite
  local drawn = false
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(x), math.floor(y))
    G.scale(0.42, 0.42)
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    local ok = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    drawn = ok
    G.pop()
  end

  if not drawn then
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", x, y - 4, x + 4, y + 4,
      x, y + 2, x - 4, y + 4)
  end
  G.setColor(1, 1, 1, 0.98)
  G.circle("line", x, y, 5.5)
end

local function drawHud(G, state)
  G.setColor(0.08, 0.12, 0.16, 0.92)
  G.rectangle("fill", 0, 0, SCREEN_W, MAP_TOP)
  G.rectangle("fill", 0, MAP_BOTTOM, SCREEN_W, SCREEN_H - MAP_BOTTOM)
  G.setColor(1, 1, 1, 1)
  if type(G.print) ~= "function" then return end

  local region = state.region == "kanto" and "KANTO" or "JOHTO"
  local altitude = math.floor((tonumber(state.virtualAltitude) or 88) + 0.5)
  pcall(G.print, "OPEN SKY - " .. region .. "  ALT " .. tostring(altitude), 4, 4)

  local bottom = state.notice
  if not bottom then
    local name = state.nearest and state.nearest.row
      and (state.nearest.row.name or state.nearest.row.landmark)
    bottom = name and ("A DESCEND - " .. cleanMapName(name))
      or "NO VISITED LANDING POINT"
  end
  bottom = tostring(bottom)
  if #bottom > 28 then bottom = bottom:sub(1, 28) end
  pcall(G.print, bottom, 4, 128)
end

local function drawPanel(state)
  local G = love.graphics
  -- Always establish a complete 160x144 picture. No G.clear() is used here:
  -- this function works both as the standalone widescreen page and as the base
  -- state when a TextBox is stacked on top of it.
  G.setColor(0.58, 0.80, 0.96, 1)
  G.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
  drawBackdrop(G, state)
  drawLandingPoints(G, state)
  local x, y = project(state.region, state.x, state.y)
  drawMountMiniature(G, state, x, y)
  drawHud(G, state)
end

local function fitScale(winW, winH)
  local raw = math.min((tonumber(winW) or SCREEN_W) / SCREEN_W,
    (tonumber(winH) or SCREEN_H) / SCREEN_H)
  if raw >= 1 then return math.max(1, math.floor(raw)) end
  return math.max(0.01, raw)
end

local function emergencyWidescreen(state, winW, winH)
  local G = love.graphics
  local pushed = false
  pcall(function()
    G.push("all")
    pushed = true
    G.origin()
    G.setColor(0.08, 0.12, 0.16, 1)
    G.rectangle("fill", 0, 0, winW, winH)
    local scale = fitScale(winW, winH)
    local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
    local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
    G.translate(ox, oy)
    G.scale(scale, scale)
    G.setColor(0.58, 0.80, 0.96, 1)
    G.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    G.setColor(0.08, 0.12, 0.16, 0.92)
    G.rectangle("fill", 0, 0, SCREEN_W, 18)
    G.rectangle("fill", 0, 124, SCREEN_W, 20)
    local x, y = project(state.region, state.x, state.y)
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", x, y - 5, x + 5, y + 5,
      x, y + 2, x - 5, y + 5)
    G.circle("line", x, y, 7)
  end)
  if pushed then pcall(G.pop) end
end

local function drawWidescreen(state, winW, winH)
  if not (love and love.graphics) then return end
  local G = love.graphics
  winW = tonumber(winW) or select(1, G.getDimensions()) or SCREEN_W
  winH = tonumber(winH) or select(2, G.getDimensions()) or SCREEN_H

  local pushed = false
  local ok, err = pcall(function()
    G.push("all")
    pushed = true
    G.origin()

    -- Own the whole window. This prevents Game2's opaque-page safety path from
    -- painting a white field around (or instead of) Open Sky.
    G.setColor(0.08, 0.12, 0.16, 1)
    G.rectangle("fill", 0, 0, winW, winH)

    local scale = fitScale(winW, winH)
    local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
    local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
    G.translate(ox, oy)
    G.scale(scale, scale)
    drawPanel(state)
  end)

  if pushed then pcall(G.pop) end
  if not ok then
    rememberDrawError("widescreen", err)
    emergencyWidescreen(state, winW, winH)
  end
end

local function patchState(state)
  if type(state) ~= "table" or patchedStates[state] then return end
  patchedStates[state] = true

  local fallback = state.draw
  state.draw = function(self)
    local ok, err = pcall(drawPanel, self)
    if not ok then
      rememberDrawError("panel", err)
      if type(fallback) == "function" then pcall(fallback, self) end
    end
  end

  -- Native Gold full-page contract. Game2:drawScene sees this before its
  -- opaque-page white safety net and calls drawWidescreen directly.
  state.wantsFillScale = function() return true end
  state.drawsWidescreen = function() return true end
  state.drawWidescreen = function(self, winW, winH)
    drawWidescreen(self, winW, winH)
  end
  state._dsrOpenSkyIllustratedMap = true
  state._dsrOpenSky2DWidescreen = true
end

local function patchCurrentState()
  if type(playable.state) ~= "function" then return end
  local ok, state = pcall(playable.state)
  if ok and state then patchState(state) end
end

local previousIllustratedOpenSkyUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousIllustratedOpenSkyUpdate(self, dt, ...)
  patchCurrentState()
  return result
end

mod.events:on("game.ready", function()
  mapImage = nil
  mapImageTried = false
  lastIllustratedDrawError = nil
end)

-- Open Sky 3D is intentionally disabled while the 2D path is being stabilized.
-- Keep a diagnostic export so stale tools do not mistake absence for detection.
playable.gen2ThreeD = {
  disabled = true,
  detected = function() return false end,
  ready = function() return false end,
  error = function() return "Open Sky 3D temporarily disabled" end,
}

playable.illustratedMap = function() return true end
playable.mapAsset = function() return MAP_ASSET end
playable.openSkyMapImage = loadMapImage
playable.projectMapPoint = project
playable.drawIllustratedMap = drawPanel
playable.drawOpenSkyWidescreen = drawWidescreen
playable.lastIllustratedDrawError = function() return lastIllustratedDrawError end

log("Gen2 Open Sky 2D widescreen renderer loaded (3D temporarily disabled)")
end)();