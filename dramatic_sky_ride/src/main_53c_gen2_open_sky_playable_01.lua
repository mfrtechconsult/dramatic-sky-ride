;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky playable regional layer.
--
-- The local overworld remains the authoritative world underneath this opaque
-- state. Entering Open Sky freezes that map in place, moves a virtual mount
-- over the native Gold town-map coordinates, and only changes maps when the
-- player deliberately descends over a VISITED Fly Point. Re-entry keeps DSR
-- airborne so the final descent/landing still happens through Dramatic Sky
-- Ride rather than through the vanilla Fly animation.
-- -------------------------------------------------------------------------
local OPEN_SKY_REENTRY_ALTITUDE = 78
-- ORAS-style regional soaring, but with MANUAL forward movement: the player
-- must actively throttle. The previous test auto-cruised at all times, which
-- made Ho-Oh advance on its own and felt wrong for this regional layer.
local OPEN_SKY_FAST_SPEED = 3.4
local OPEN_SKY_BOOST_SPEED = 5.4
local OPEN_SKY_DASH_SPEED = 5.4
local OPEN_SKY_ACCEL = 5.2
local OPEN_SKY_BRAKE = 8.5
local OPEN_SKY_IDLE_DRAG = 6.5
local OPEN_SKY_TURN_RATE = math.rad(42)
local OPEN_SKY_BANK_ANGLE = 12
local OPEN_SKY_PITCH_ANGLE = 13
local OPEN_SKY_LAND_RADIUS = 11
local MAP_MIN_X, MAP_MAX_X = 6, 154
local MAP_MIN_Y, MAP_MAX_Y = 22, 138

local generation = mod.exports.runtimeGeneration or {}
local openSkyApi = mod.exports.openSky or {}
local FieldMoves2 = nil
local Pokegear2 = nil
local Chrome2 = nil

local function isGen2()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function liveWorld()
  return mod.exports._mountWorld(Game)
end

local function fieldMovesModule()
  if FieldMoves2 ~= nil then return FieldMoves2 or nil end
  local ok, value = pcall(require, "src.world.gen2.FieldMoves")
  FieldMoves2 = ok and value or false
  return FieldMoves2 or nil
end

local function pokegearModule()
  if Pokegear2 ~= nil then return Pokegear2 or nil end
  local ok, value = pcall(require, "src.ui.gen2.Pokegear")
  Pokegear2 = ok and value or false
  return Pokegear2 or nil
end

local function chromeModule()
  if Chrome2 ~= nil then return Chrome2 or nil end
  local ok, value = pcall(require, "src.ui.gen2.Chrome")
  Chrome2 = ok and value or false
  return Chrome2 or nil
end

local function clampSky(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

local function approachSky(current, target, rate, dt)
  current, target = tonumber(current) or 0, tonumber(target) or 0
  local step = math.max(0, tonumber(rate) or 0) * math.max(0, tonumber(dt) or 0)
  if current < target then return math.min(target, current + step) end
  if current > target then return math.max(target, current - step) end
  return current
end

local function smoothSky(current, target, sharpness, dt)
  current, target = tonumber(current) or 0, tonumber(target) or 0
  local a = 1 - math.exp(-math.max(0, tonumber(sharpness) or 0)
    * math.max(0, tonumber(dt) or 0))
  return current + (target - current) * a
end

local function wrapAngleSky(value)
  local tau = math.pi * 2
  value = tonumber(value) or 0
  value = value % tau
  if value > math.pi then value = value - tau end
  return value
end

local function facingFromHeading(heading)
  local cx, sy = math.cos(heading or 0), math.sin(heading or 0)
  if math.abs(cx) >= math.abs(sy) then return cx >= 0 and "right" or "left" end
  return sy >= 0 and "down" or "up"
end

local function cleanName(value)
  return tostring(value or ""):gsub("\n", " ")
    :gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function atlasAnchor(id, region)
  if type(openSkyApi.atlas) ~= "function" then return nil end
  local ok, atlas = pcall(openSkyApi.atlas)
  if not ok or type(atlas) ~= "table" then return nil end
  for _, anchor in ipairs(atlas[region] or {}) do
    if anchor.id == id then return anchor end
  end
  return nil
end

local function visitedPoints(game, region)
  local fieldMoves = fieldMovesModule()
  local landmarks = game and game.data and game.data.gen2Landmarks
  if not (fieldMoves and type(fieldMoves.flyPoints) == "function"
      and landmarks) then return {} end
  local ok, rows = pcall(fieldMoves.flyPoints, game.save, landmarks, region)
  if not ok or type(rows) ~= "table" then return {} end
  local out = {}
  for _, row in ipairs(rows) do
    local anchor = atlasAnchor(row.landmark, region)
    if anchor then
      out[#out + 1] = { row = row, anchor = anchor }
    end
  end
  return out
end

local function nearestVisited(game, region, x, y)
  local nearest, distance = nil, math.huge
  for _, point in ipairs(visitedPoints(game, region)) do
    local dx = (point.anchor.x or 0) - x
    local dy = (point.anchor.y or 0) - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < distance then
      nearest, distance = point, d
    end
  end
  return nearest, distance
end

local OpenSkyState = {}
OpenSkyState.__index = OpenSkyState
OpenSkyState.isOpaque = true

function OpenSkyState.new(game, world)
  local status = type(openSkyApi.status) == "function" and openSkyApi.status() or {}
  local anchor = status.anchor or (type(openSkyApi.currentAnchor) == "function"
    and openSkyApi.currentAnchor(world) or nil)
  local self = setmetatable({
    game = game,
    world = world,
    region = status.region or (anchor and anchor.region) or "johto",
    x = clampSky(tonumber(anchor and anchor.x) or 80, MAP_MIN_X, MAP_MAX_X),
    y = clampSky(tonumber(anchor and anchor.y) or 78, MAP_MIN_Y, MAP_MAX_Y),
