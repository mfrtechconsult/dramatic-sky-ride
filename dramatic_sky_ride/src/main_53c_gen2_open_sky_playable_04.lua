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
  local moving = (tonumber(self.speed) or 0) > 0.5
  local bottom = self.notice or ((ready and "A DESCEND - " or "NEAREST - ") .. nearestName)
  if Chrome and type(Chrome.print) == "function" then
    Chrome.print(regionLabel, 1, 0)
    Chrome.print(string.format("ALT %d SPD %d", math.floor(self.virtualAltitude + 0.5), math.floor((self.speed or 0) + 0.5)), 10, 0)
    Chrome.print(bottom, 1, 16)
  else
    G.print(regionLabel, 4, 4)
    G.print(string.format("ALT %d SPD %d", math.floor(self.virtualAltitude + 0.5), math.floor((self.speed or 0) + 0.5)), 88, 4)
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

log("Gen2 Open Sky playable layer loaded (manual ORAS soaring boost=%d dash=%d landingRadius=%d reentry=%d)",
  OPEN_SKY_BOOST_SPEED, OPEN_SKY_DASH_SPEED,
  OPEN_SKY_LAND_RADIUS, OPEN_SKY_REENTRY_ALTITUDE)
end)();
