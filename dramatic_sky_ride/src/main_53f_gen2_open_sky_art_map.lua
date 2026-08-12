;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky illustrated regional map.
--
-- The supplied artwork is only a geographic backdrop. Its visual landmarks
-- are never trusted as game data: real Gold/Silver landmark and visited Fly
-- Point records remain authoritative and are projected onto the picture.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local mapImage = nil
local mapImageTried = false
local MAP_ASSET = "assets/open_sky_region_map.jpg"
local MAP_ASSET_PARTS = {
  "assets/open_sky_map/part01.b64",
  "assets/open_sky_map/part02.b64",
  "assets/open_sky_map/part03.b64",
  "assets/open_sky_map/part04.b64",
}

local SOURCE_X0, SOURCE_X1 = 6, 154
local SOURCE_Y0, SOURCE_Y1 = 22, 138
local REGION_RECT = {
  johto = { x0 = 5,  x1 = 85,  y0 = 22, y1 = 106 },
  kanto = { x0 = 90, x1 = 154, y0 = 22, y1 = 106 },
}

local function clampMap(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function cleanMapName(value)
  return tostring(value or ""):gsub("\n", " ")
    :gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function loadImageFromRaw(raw, filename)
  if type(raw) ~= "string" or raw == "" then return nil end
  if not (love and love.graphics and love.filesystem
      and love.filesystem.newFileData) then return nil end
  local okData, fileData = pcall(love.filesystem.newFileData, raw, filename)
  if not okData or not fileData then return nil end
  local okImage, image = pcall(love.graphics.newImage, fileData)
  if not okImage or not image then return nil end
  return image
end

local function readMapBytes()
  if not (mod.read and love and love.data and love.data.decode) then return nil end
  local encoded = {}
  for _, relative in ipairs(MAP_ASSET_PARTS) do
    local okRead, part = pcall(mod.read, mod, relative)
    if not okRead or type(part) ~= "string" or part == "" then return nil end
    encoded[#encoded + 1] = part:gsub("%s", "")
  end
  local okDecode, raw = pcall(love.data.decode, "string", "base64",
    table.concat(encoded))
  return okDecode and type(raw) == "string" and raw or nil
end

local function loadMapImage()
  if mapImageTried then return mapImage end
  mapImageTried = true
  if not (love and love.graphics) then return nil end

  -- The binary artwork is split into small Base64 package fragments. This
  -- avoids launcher/Git transport corruption while still decoding to one
  -- normal LÖVE image entirely in memory.
  mapImage = loadImageFromRaw(readMapBytes(), "open_sky_region_map.jpg")
  if mapImage then pcall(mapImage.setFilter, mapImage, "linear", "linear") end
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

local function drawBackdrop(G)
  local image = loadMapImage()
  if not image then
    G.setColor(0.58, 0.80, 0.96, 1)
    G.rectangle("fill", 0, 0, 160, 144)
    return false
  end

  G.setColor(1, 1, 1, 1)
  local iw, ih = image:getDimensions()
  local scale = math.min(160 / math.max(1, iw), 106 / math.max(1, ih))
  local dw, dh = iw * scale, ih * scale
  G.draw(image, (160 - dw) * 0.5, 18 + (106 - dh) * 0.5, 0, scale, scale)
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
        G.setColor(1, 1, 1, 0.95)
        G.circle("line", x, y, 4.5)
      end
      G.setColor(1, 1, 1, 0.92)
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
    drawn = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    G.pop()
  end

  if not drawn then
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", x, y - 4, x + 4, y + 4,
      x, y + 2, x - 4, y + 4)
  end
  G.setColor(1, 1, 1, 0.95)
  G.circle("line", x, y, 5.5)
end

local function drawHud(G, state)
  G.setColor(0, 0, 0, 0.72)
  G.rectangle("fill", 0, 0, 160, 18)
  G.rectangle("fill", 0, 124, 160, 20)
  G.setColor(1, 1, 1, 1)
  if type(G.print) ~= "function" then return end

  local region = state.region == "kanto" and "KANTO" or "JOHTO"
  local altitude = math.floor((tonumber(state.virtualAltitude) or 88) + 0.5)
  G.print("OPEN SKY - " .. region .. "  ALT " .. tostring(altitude), 4, 4)

  local bottom = state.notice
  if not bottom then
    local name = state.nearest and state.nearest.row
      and (state.nearest.row.name or state.nearest.row.landmark)
    bottom = name and ("A DESCEND - " .. cleanMapName(name))
      or "NO VISITED LANDING POINT"
  end
  if #bottom > 28 then bottom = bottom:sub(1, 28) end
  G.print(bottom, 4, 128)
end

local function drawIllustratedMap(state)
  if not (love and love.graphics) then return end
  local G = love.graphics
  local pushed = false
  local ok, err = pcall(function()
    G.push("all")
    pushed = true
    G.clear(0.58, 0.80, 0.96, 1)
    drawBackdrop(G)
    drawLandingPoints(G, state)
    local x, y = project(state.region, state.x, state.y)
    drawMountMiniature(G, state, x, y)
    drawHud(G, state)
  end)
  if pushed then pcall(G.pop) end
  if not ok then
    pcall(function() log("Open Sky illustrated map draw failed: %s", tostring(err)) end)
  end
end

local function patchState(state)
  if type(state) ~= "table" or patchedStates[state] then return end
  patchedStates[state] = true
  state.draw = function(self) drawIllustratedMap(self) end
  state._dsrOpenSkyIllustratedMap = true
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
end)

playable.illustratedMap = function() return true end
playable.mapAsset = function() return MAP_ASSET end
playable.openSkyMapImage = loadMapImage
playable.projectMapPoint = project
playable.drawIllustratedMap = drawIllustratedMap

log("Gen2 Open Sky illustrated regional map loaded")
end)();