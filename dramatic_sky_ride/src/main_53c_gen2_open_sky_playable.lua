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
local OPEN_SKY_MOVE_SPEED = 62 -- town-map pixels / second
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
    facing = "right",
    anim = 0,
    virtualAltitude = tonumber(status.enteredAtAltitude)
      or tonumber(flight.altitude) or 88,
    notice = nil,
    noticeTimer = 0,
    nearest = nil,
    nearestDistance = math.huge,
    gear = nil,
    gearRegion = nil,
  }, OpenSkyState)
  self:refreshNearest()
  return self
end

function OpenSkyState:kantoUnlocked()
  if type(openSkyApi.kantoUnlocked) ~= "function" then return false end
  local ok, value = pcall(openSkyApi.kantoUnlocked, self.world)
  return ok and value == true
end

function OpenSkyState:setNotice(text, seconds)
  self.notice = text
  self.noticeTimer = seconds or 1.3
end

function OpenSkyState:refreshNearest()
  self.nearest, self.nearestDistance = nearestVisited(
    self.game, self.region, self.x, self.y)
end

function OpenSkyState:setRegion(region, x)
  if region == self.region then return end
  self.region = region
  self.x = clampSky(x or self.x, MAP_MIN_X, MAP_MAX_X)
  self.gear = nil
  self.gearRegion = nil
  self:refreshNearest()
  self:setNotice(region == "kanto" and "KANTO AIRSPACE" or "JOHTO AIRSPACE", 1.5)
end

function OpenSkyState:returnToLocal(reason)
  flight.altitude = clampSky(tonumber(self.virtualAltitude) or OPEN_SKY_REENTRY_ALTITUDE,
    MIN_MANUAL_HEIGHT, OPEN_SKY_REENTRY_ALTITUDE)
  flight.requestedAltitude = flight.altitude
  flight.targetAltitude = flight.altitude
  if type(openSkyApi.leave) == "function" then openSkyApi.leave(reason or "return") end
  if self.game and self.game.stack and self.game.stack:top() == self then
    self.game.stack:pop()
  end
end

function OpenSkyState:descendAt(point)
  point = point or self.nearest
  if not (point and point.row and point.row.spawn) then
    self:setNotice("NO VISITED LANDING POINT")
    return false
  end
  if (self.nearestDistance or math.huge) > OPEN_SKY_LAND_RADIUS then
    self:setNotice("FLY CLOSER TO A VISITED TOWN")
    return false
  end

  local world = self.world or liveWorld()
  local spawns = world and world.landmarks and world.landmarks.spawns
  local spawn = spawns and spawns[point.row.spawn] or nil
  if not (world and spawn and spawn.map and spawn.x and spawn.y
      and world.maps and world.maps[spawn.map]) then
    self:setNotice("LANDING DATA UNAVAILABLE")
    return false
  end

  -- Do not call World:flyTo(): it deliberately ends in PLAYER_NORMAL and owns
  -- the vanilla Fly animation. Open Sky wants the opposite contract: change
  -- the authoritative local map, then hand control back to DSR still airborne.
  local ok, loaded = pcall(world.setMap, world,
    spawn.map, spawn.x, spawn.y, self.facing or "down")
  if not ok or loaded == false then
    self:setNotice("COULD NOT REENTER THIS AREA")
    return false
  end

  flight.active = true
  flight.phase = "cruise"
  flight.altitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.requestedAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.targetAltitude = OPEN_SKY_REENTRY_ALTITUDE
  flight.safetyAltitude = 0
  flight.verticalInput = 0
  flight.landingX, flight.landingY, flight.landingKind = nil, nil, nil
  -- Emergency landing must now regard the new local map as the safe origin;
  -- otherwise a battle/save transition after regional travel could snap the
  -- player all the way back to the map where Open Sky was first entered.
  flight.originMap = spawn.map
  flight.originX, flight.originY = spawn.x, spawn.y
  flight.originSurf = false
  flight.originSurfMon = nil

  if type(openSkyApi.leave) == "function" then
    openSkyApi.leave("regional_descent")
  end
  if self.game and self.game.stack and self.game.stack:top() == self then
    self.game.stack:pop()
  end
  notifyHud("DESCENDING: " .. cleanName(point.row.name), 2.0)
  return true
end

function OpenSkyState:update(dt)
  dt = tonumber(dt) or (1 / 60)
  self.anim = (self.anim + dt * 28) % 32
  if self.noticeTimer > 0 then
    self.noticeTimer = math.max(0, self.noticeTimer - dt)
    if self.noticeTimer == 0 then self.notice = nil end
  end

  if not (isGen2() and flight.active and type(openSkyApi.active) == "function"
      and openSkyApi.active()) then
    self:returnToLocal("state_invalid")
    return
  end

  -- Keep DSR's familiar altitude controls meaningful while the local world is
  -- frozen under this state. Descending through the Stage-1 hysteresis floor
  -- returns to the exact local position from which Open Sky was entered.
  local vertical = type(altitudeInputDirection) == "function"
    and altitudeInputDirection() or 0
  if vertical ~= 0 then
    local rate = type(verticalRate) == "function" and verticalRate() or 48
    self.virtualAltitude = clampSky(self.virtualAltitude + vertical * rate * dt,
      OPEN_SKY_EXIT_ALTITUDE, MAX_MANUAL_HEIGHT)
    if vertical < 0 and self.virtualAltitude <= OPEN_SKY_EXIT_ALTITUDE + 0.01 then
      self:returnToLocal("descended")
      return
    end
  end

  local input = self.game and self.game.input
  if not input then return end
  local dx = (input:isDown("right") and 1 or 0) - (input:isDown("left") and 1 or 0)
  local dy = (input:isDown("down") and 1 or 0) - (input:isDown("up") and 1 or 0)
  if dx ~= 0 or dy ~= 0 then
    local length = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / length, dy / length
    local nx = self.x + dx * OPEN_SKY_MOVE_SPEED * dt
    local ny = self.y + dy * OPEN_SKY_MOVE_SPEED * dt
    if math.abs(dx) >= math.abs(dy) then
      self.facing = dx > 0 and "right" or "left"
    else
      self.facing = dy > 0 and "down" or "up"
    end

    if self.region == "johto" and nx > MAP_MAX_X then
      if self:kantoUnlocked() then
        self:setRegion("kanto", MAP_MIN_X + 2)
      else
        self.x = MAP_MAX_X
        self:setNotice("KANTO IS NOT UNLOCKED YET")
      end
    elseif self.region == "kanto" and nx < MAP_MIN_X then
      self:setRegion("johto", MAP_MAX_X - 2)
    else
      self.x = clampSky(nx, MAP_MIN_X, MAP_MAX_X)
    end
    self.y = clampSky(ny, MAP_MIN_Y, MAP_MAX_Y)
    self:refreshNearest()
  end

  if input:wasPressed("a") then
    self:descendAt(self.nearest)
    return
  end
  if input:wasPressed("b") then
    self:returnToLocal("cancelled")
    return
  end
end

function OpenSkyState:mapGear()
  if self.gear and self.gearRegion == self.region then return self.gear end
  local Pokegear = pokegearModule()
  if not (Pokegear and type(Pokegear.new) == "function") then return nil end
  local landmark = self.nearest and self.nearest.row and self.nearest.row.landmark
  local ok, gear = pcall(Pokegear.new, self.game, {
    save = self.game and self.game.save,
    currentLandmark = landmark,
  })
  if not ok then return nil end
  self.gear, self.gearRegion = gear, self.region
  return gear
end

function OpenSkyState:drawFallbackMap()
  local G = love.graphics
  G.setColor(0.60, 0.82, 0.95, 1)
  G.rectangle("fill", 0, 0, 160, 144)
  local atlas = type(openSkyApi.atlas) == "function" and openSkyApi.atlas() or nil
  G.setColor(0.20, 0.45, 0.28, 1)
  for _, anchor in ipairs((atlas and atlas[self.region]) or {}) do
    G.circle("fill", anchor.x or 0, anchor.y or 0, 2)
  end
end

function OpenSkyState:drawRegionalMap()
  local gear = self:mapGear()
  local cells = gear and gear.gfx and gear.gfx.maps and gear.gfx.maps[self.region]
  if gear and cells and type(gear.drawTilemap) == "function" then
    local ok = pcall(gear.drawTilemap, gear, cells)
    if ok then return true end
  end
  self:drawFallbackMap()
  return false
end

function OpenSkyState:drawMount()
  local G = love.graphics
  local sprite = flight.sprite
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(self.x), math.floor(self.y))
    -- Regional map coordinates are already screen pixels. A half-scale mount
    -- reads as a soaring icon while still using DSR's selected Pokemon art.
    G.scale(0.5, 0.5)
    G.setColor(1, 1, 1, 1)
    local phase = self.anim >= 16 and 1 or 0
    pcall(sprite.draw, sprite, -8, -8, 0, 0, self.facing, phase, false)
    G.pop()
  else
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", self.x, self.y - 4, self.x + 4, self.y + 4,
      self.x, self.y + 2, self.x - 4, self.y + 4)
  end

  -- The ring stays readable even when a large Stadium/Pokedex-scaled mount
  -- covers its own centre point.
  G.setColor(1, 1, 1, 0.85)
  G.circle("line", math.floor(self.x), math.floor(self.y), 6)
end

function OpenSkyState:draw()
  if not (love and love.graphics) then return end
  local G = love.graphics
  G.push("all")
  G.clear(0.58, 0.80, 0.96, 1)
  self:drawRegionalMap()

  -- Visited Fly Points are landing beacons. Other landmarks remain part of the
  -- native town-map art but cannot be used to sequence-break progression.
  for _, point in ipairs(visitedPoints(self.game, self.region)) do
    local a = point.anchor
    local close = self.nearest == point
      or (self.nearest and self.nearest.row.spawn == point.row.spawn)
    if close then
      G.setColor(1, 1, 1, 0.95)
      G.circle("line", a.x, a.y, OPEN_SKY_LAND_RADIUS)
    end
    G.setColor(1, 1, 1, 0.85)
    G.circle("fill", a.x, a.y, 1.5)
  end

  self:drawMount()

  -- Compact HUD strips; use Gold's own Chrome font when available so the state
  -- remains legible at the native 160x144 resolution.
  G.setColor(0, 0, 0, 0.72)
  G.rectangle("fill", 0, 0, 160, 18)
  G.rectangle("fill", 0, 124, 160, 20)
  G.setColor(1, 1, 1, 1)
  local Chrome = chromeModule()
  local regionLabel = self.region == "kanto" and "OPEN SKY - KANTO" or "OPEN SKY - JOHTO"
  local nearestName = self.nearest and cleanName(self.nearest.row.name) or "NO LANDING POINT"
  local ready = (self.nearestDistance or math.huge) <= OPEN_SKY_LAND_RADIUS
  local bottom = self.notice or ((ready and "A DESCEND - " or "NEAREST - ") .. nearestName)
  if Chrome and type(Chrome.print) == "function" then
    Chrome.print(regionLabel, 1, 0)
    Chrome.print(string.format("ALT %d", math.floor(self.virtualAltitude + 0.5)), 14, 0)
    Chrome.print(bottom, 1, 16)
  else
    G.print(regionLabel, 4, 4)
    G.print(bottom, 4, 128)
  end
  G.pop()
end

local pushedState = nil
local function ensureOpenSkyState()
  if not isGen2() then return end
  local active = type(openSkyApi.active) == "function" and openSkyApi.active()
  local world = liveWorld()
  local game = world and world.game or nil
  if not active then
    pushedState = nil
    return
  end
  if not (game and game.stack and world and flight.active) then return end

  local top = game.stack:top()
  if pushedState and top == pushedState then return end
  if top ~= nil then return end -- never cover a dialogue/menu/cutscene
  pushedState = OpenSkyState.new(game, world)
  game.stack:push(pushedState)
  notifyHud("OPEN SKY", 1.2)
end

-- Stage 1 sets flight.openSky.active after the mature flight tick. This outer
-- observer pushes the opaque navigation state only after that decision, so the
-- map underneath has completed the frame that crossed altitude 88.
local previousOpenSkyPlayableUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousOpenSkyPlayableUpdate(self, dt, ...)
  ensureOpenSkyState()
  return result
end

mod.exports.openSkyPlayable = {
  api = 1,
  active = function()
    return pushedState ~= nil
      and pushedState.game and pushedState.game.stack
      and pushedState.game.stack:top() == pushedState
  end,
  state = function() return pushedState end,
  landingRadius = function() return OPEN_SKY_LAND_RADIUS end,
  reentryAltitude = function() return OPEN_SKY_REENTRY_ALTITUDE end,
  visitedPoints = function(region)
    local world = liveWorld()
    local game = world and world.game
    return game and visitedPoints(game, region or "johto") or {}
  end,
}

log("Gen2 Open Sky playable layer loaded (speed=%d landingRadius=%d reentry=%d)",
  OPEN_SKY_MOVE_SPEED, OPEN_SKY_LAND_RADIUS, OPEN_SKY_REENTRY_ALTITUDE)
end)();
