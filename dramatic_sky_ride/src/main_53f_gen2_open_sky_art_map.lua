;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky illustrated regional map.
--
-- The supplied artwork is treated ONLY as a geographic backdrop. Its printed
-- labels/numbers are never used for game logic. Real Gold landmark/fly-point
-- data remains authoritative and is projected onto the corresponding Johto
-- and Kanto halves of the picture.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local mapImage = nil
local mapImageTried = false
local MAP_ASSET = "assets/open_sky_region_map.jpg.b64"

-- Gold's town-map coordinates are full-screen coordinates for EACH region.
-- Project each 160x144 regional coordinate space onto the matching half of the
-- combined artwork. These bounds follow the geography in the supplied image,
-- not any text/number printed on it.
local SOURCE_X0, SOURCE_X1 = 6, 154
local SOURCE_Y0, SOURCE_Y1 = 22, 138
local REGION_RECT = {
  johto = { x0 = 7,  x1 = 83,  y0 = 26, y1 = 105 },
  kanto = { x0 = 95, x1 = 151, y0 = 24, y1 = 105 },
}

local function clampMap(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function cleanMapName(value)
  return tostring(value or ""):gsub("\n", " ")
    :gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function loadMapImage()
  if mapImageTried then return mapImage end
  mapImageTried = true
  if not (love and love.data and love.filesystem and love.graphics) then return nil end

  local encoded = mod.read and mod:read(MAP_ASSET) or nil
  if type(encoded) ~= "string" or encoded == "" then return nil end
  encoded = encoded:gsub("%s", "")

  local okDecode, decoded = pcall(love.data.decode, "string", "base64", encoded)
  if not okDecode or type(decoded) ~= "string" then return nil end
  local okData, fileData = pcall(love.filesystem.newFileData,
    decoded, "open_sky_region_map.jpg")
  if not okData or not fileData then return nil end
  local okImage, image = pcall(love.graphics.newImage, fileData)
  if not okImage or not image then return nil end
  pcall(image.setFilter, image, "linear", "linear")
  mapImage = image
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
  local scale = 160 / math.max(1, iw)
  -- Keep the full supplied composition visible. The 16:9 map occupies the
  -- centre of Gold's 160x144 panel, leaving room for the Open Sky HUD.
  G.draw(image, 0, 18, 0, scale, scale)
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
    -- Open Sky uses a screen-space miniature, independent of the mount's
    -- overworld/Pokedex size multiplier. This keeps even very large species
    -- readable without covering half the regional map.
    G.scale(0.42, 0.42)
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    local ok = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    G.pop()
    drawn = ok
  end

  if not drawn then
    -- Last-resort marker only. Normal DSR 2D mounts use the actual selected
    -- mount sprite above.
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
    if name then
      bottom = "A DESCEND - " .. cleanMapName(name)
    else
      bottom = "NO VISITED LANDING POINT"
    end
  end
  -- The source artwork's annotations are ignored; this label comes from the
  -- real Fly Point/landmark record in Gold.
  if #bottom > 28 then bottom = bottom:sub(1, 28) end
  G.print(bottom, 4, 128)
end

local function drawIllustratedMap(state)
  if not (love and love.graphics) then return end
  local G = love.graphics
  local pushed = false
  local ok, err = pcall(function()
    G.push()
    pushed = true
    drawBackdrop(G)
    drawLandingPoints(G, state)
    local x, y = project(state.region, state.x, state.y)
    drawMountMiniature(G, state, x, y)
    drawHud(G, state)
  end)
  if pushed then pcall(G.pop) end
  if not ok then
    pcall(function()
      log("Open Sky illustrated map draw failed: %s", tostring(err))
    end)
  end
end

local function patchState(state)
  if type(state) ~= "table" or patchedStates[state] then return end
  patchedStates[state] = true
  state.draw = function(self)
    drawIllustratedMap(self)
  end
  state._dsrOpenSkyIllustratedMap = true
end

local function patchCurrentState()
  if type(playable.state) ~= "function" then return end
  local ok, state = pcall(playable.state)
  if ok and state then patchState(state) end
end

-- This loads after the runtime guard and input latch. On the transition frame
-- those layers first make the state safe, then this final wrapper replaces only
-- its presentation. Navigation, altitude hysteresis and landing remain theirs.
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
playable.projectMapPoint = project

log("Gen2 Open Sky illustrated regional map loaded")
end)();
