    for _, id in ipairs(FOLLOWER_MOD_IDS) do
      local okFind, handle = pcall(mod.find, mod, id)
      local ex = okFind and handle and handle.exports or nil
      if ex then
        if type(ex.syncAll) == "function" then
          pcall(ex.syncAll, Game, ow)
        elseif type(ex.sync) == "function" then
          pcall(ex.sync, Game, ow)
        end
      end
    end
  end
  return hasFollowerEntity(ow)
end

local function restoreFollowers(ow)
  local captured = flight.suspended
  flight.suspended = nil
  if not (ow and ow.map) then return false end
  purgeFollowersDuringFlight(ow)
  if syncFollowerMods(ow) then return true end

  if captured and captured.mapId == ow.map.id then
    for _, e in ipairs(captured.npcs or {}) do
      if not contains(ow.npcs, e) then table.insert(ow.npcs, e) end
    end
    for _, e in ipairs(captured.entities or {}) do
      if not contains(ow.entities, e) then table.insert(ow.entities, e) end
    end
    return hasFollowerEntity(ow) or (#(captured.entities or {}) == 0
      and #(captured.npcs or {}) == 0)
  end

  pendingFollowerRestore = { frames = FOLLOWER_RESTORE_FRAMES }
  return false
end

local function occupiedForLanding(ow, x, y)
  for _, e in ipairs(ow.entities or {}) do
    if e ~= ow.player and not e.passable then
      if (e.cellX == x and e.cellY == y)
         or (e.targetX == x and e.targetY == y) then
        return true
      end
    end
  end
  return false
end


local function isStoryCriticalEntity(e)
  if not e or e.skyRideRider or e.skyRideGroundFx then return false end
  if isFollowerEntity(e, Game.overworld and Game.overworld.player) then return false end
  local def = e.def or {}
  local id = tostring(e.id or ""):lower()
  return def.runtime == true or def.owner ~= nil
      or e.questId ~= nil or e.quest ~= nil or e.questRuntime == true
      or id:find("quest", 1, true) ~= nil
end

local function storyOccupied(entities, x, y, except)
  if not storySafeEnabled() then return false end
  for _, e in ipairs(entities or {}) do
    if e ~= except and isStoryCriticalEntity(e)
       and ((e.cellX == x and e.cellY == y)
            or (e.targetX == x and e.targetY == y)) then
      return true
    end
  end
  return false
end

landingCellValid = function(ow, x, y)
  local map = ow and ow.map
  if not (map and map:inBounds(x, y)) then return false end
  if not map:isWalkableCell(x, y) then return false end
  if map.isWaterCell and map:isWaterCell(x, y) then return false end
  if occupiedForLanding(ow, x, y) then return false end
  return true
end

local function findLandingCell(ow)
  local p = ow.player
  if landingCellValid(ow, p.cellX, p.cellY) then
    return p.cellX, p.cellY
  end
  for radius = 1, LANDING_RADIUS do
    for dy = -radius, radius do
      for dx = -radius, radius do
        if math.max(math.abs(dx), math.abs(dy)) == radius then
          local x, y = p.cellX + dx, p.cellY + dy
          if landingCellValid(ow, x, y) then return x, y end
        end
      end
    end
  end
  return nil
end

local function clearFlight(ow, landingFeedback)
  removeRiderEntity(ow)
  removeGroundFxEntity(ow)
  local p = ow and ow.player
  if p then
    p.bumpFrames = nil
    p.moving = false
    p.targetX, p.targetY = nil, nil
    p.progress = 0
    p.px, p.py = p.cellX * 16, p.cellY * 16
  end
  restoreFollowers(ow)
  if landingFeedback then feedback("landing") end
  flight.active = false
  flight.phase = "idle"
  flight.altitude = 0
  flight.requestedAltitude = CRUISE_HEIGHT
  flight.targetAltitude = CRUISE_HEIGHT
  flight.safetyAltitude = 0
  flight.verticalInput = 0
  flight.hudTimer = 0
  flight.notice = nil
  flight.noticeTimer = 0
  flight.species = nil
  flight.mon = nil
  flight.sprite = nil
  flight.riderSprite = nil
  flight.riderEntity = nil
  flight.groundFxSprite = nil
  flight.groundFxEntity = nil
  flight.anim = 0
  flight.boost = 0
  flight.boostWasHeld = false
  flight.autoSafetyWasActive = false
  flight.cameraManualTimer = 0
  flight.landingX, flight.landingY = nil, nil
  flight.originMap, flight.originX, flight.originY = nil, nil, nil
  if ow and ow.refreshStandingOnWarp then ow:refreshStandingOnWarp() end
end

local function beginLanding(game, forced)
  local ow = game and game.overworld
  if not (flight.active and ow and ow.player) then return false end
  local x, y = ow.player.cellX, ow.player.cellY
  if not landingCellValid(ow, x, y) then
    if not forced then
      notifyHud("CAN'T LAND HERE")
      feedback("blocked")
    end
    return false
  end
  flight.landingX, flight.landingY = x, y
  flight.phase = "landing"
  flight.verticalInput = 0
  return true
end

local function forceImmediateLand(game)
  local ow = game and game.overworld
  if not (flight.active and ow and ow.player) then return false end
  local x, y = findLandingCell(ow)
  if not x and flight.originMap and ow.setMap then
    -- Emergency fallback used only when the engine must save or enter a
    -- battle while the rider is over a large invalid area. Returning to the
    -- known-safe takeoff cell is preferable to serializing a blocked cell.
    local guarded = transitionGuard
    transitionGuard = true
