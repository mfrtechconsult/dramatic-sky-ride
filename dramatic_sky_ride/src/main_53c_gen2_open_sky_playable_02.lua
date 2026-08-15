  local text, validated, total = calibrationExportText()
  calibration.lastExport = text

  if type(print) == "function" then
    print("[DSR OPEN SKY CALIBRATION BEGIN]")
    print(text)
    print("[DSR OPEN SKY CALIBRATION END]")
  end

  local copied = false
  if love and love.system and type(love.system.setClipboardText) == "function" then
    local ok = pcall(love.system.setClipboardText, text)
    copied = ok == true
  end

  state.calibrationExportText = text
  state.calibrationExportValidated = validated
  state.calibrationExportTotal = total
  state.calibrationExportTimer = 6.0
  local missing = math.max(0, total - validated)
  if copied and missing == 0 then
    state:setNotice(string.format("COMPLETE %d/%d - REPORT COPIED", validated, total), 2.8)
  elseif copied then
    state:setNotice(string.format("COPIED %d/%d - %d MISSING", validated, total, missing), 2.8)
  elseif missing == 0 then
    state:setNotice(string.format("COMPLETE %d/%d - REPORT IN LOG", validated, total), 2.8)
  else
    state:setNotice(string.format("REPORT %d/%d - %d MISSING (LOG)", validated, total, missing), 2.8)
  end
  return copied
end

local function calibrationSetCurrent(state)
  local anchor = calibrationSelection(state)
  if not anchor then return false end
  calibrationLoad()
  calibration.points[state.region][anchor.id] = {
    x = tonumber(state.x) or 80,
    y = tonumber(state.y) or 78,
  }
  calibrationSave()
  state:setNotice(string.format("VALIDATED: %s  %.2f, %.2f",
    tostring(anchor.name or anchor.id), tonumber(state.x) or 0,
    tonumber(state.y) or 0), 2.0)
  state:refreshNearest()
  calibrationSelectDelta(state, 1, true)
  return true
end

local function calibrationDeleteCurrent(state)
  local anchor = calibrationSelection(state)
  if not anchor then return false end
  calibrationLoad()
  calibration.points[state.region][anchor.id] = nil
  calibrationSave()
  state:setNotice("RESET TO BUNDLED: " .. tostring(anchor.name or anchor.id), 2.0)
  calibrationFocusSelection(state)
  return true
end

local function calibrationCycleRegion(state)
  state.region = state.region == "kanto" and "johto" or "kanto"
  state.speed, state.targetSpeed = 0, 0
  state.calibrationIndex = 1
  state.gear, state.gearRegion = nil, nil
  calibrationFocusSelection(state)
  state:setNotice("CALIBRATION: " .. string.upper(state.region), 1.5)
end

local function isGen2()
  return type(generation.isGen2) == "function" and generation.isGen2(Game) == true
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

projectOpenSkyPoint = function(region, x, y)
  local playable = mod.exports and mod.exports.openSkyPlayable or nil
  local project = playable and playable.projectMapPoint or nil
  if type(project) == "function" then
    local ok, sx, sy = pcall(project, region, x, y)
    sx, sy = tonumber(sx), tonumber(sy)
    if ok and sx and sy then
      return clampSky(sx, NAV_MIN_X, NAV_MAX_X), clampSky(sy, NAV_MIN_Y, NAV_MAX_Y)
    end
  end
  local nx = (clampSky(tonumber(x) or 80, MAP_MIN_X, MAP_MAX_X) - MAP_MIN_X) / (MAP_MAX_X - MAP_MIN_X)
  local ny = (clampSky(tonumber(y) or 78, MAP_MIN_Y, MAP_MAX_Y) - MAP_MIN_Y) / (MAP_MAX_Y - MAP_MIN_Y)
  return 10 + nx * (NAV_W - 20), 10 + ny * (NAV_H - 20)
end

local function syncNativeCursorFromScreen(state)
  if not state then return end
  local sx = clampSky(tonumber(state.screenX) or NAV_W * 0.5, NAV_MIN_X, NAV_MAX_X)
  local sy = clampSky(tonumber(state.screenY) or NAV_H * 0.5, NAV_MIN_Y, NAV_MAX_Y)
  state.x = MAP_MIN_X + (sx / NAV_W) * (MAP_MAX_X - MAP_MIN_X)
  state.y = MAP_MIN_Y + (sy / NAV_H) * (MAP_MAX_Y - MAP_MIN_Y)
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
  local a = 1 - math.exp(-math.max(0, tonumber(sharpness) or 0) * math.max(0, tonumber(dt) or 0))
  return current + (target - current) * a
end

local function wrapAngleSky(value)
  local tau = math.pi * 2
  value = tonumber(value) or 0
  value = value % tau
  if value > math.pi then value = value - tau end
  return value
end

local function smoothAngleSky(current, target, sharpness, dt)
  current, target = tonumber(current) or 0, tonumber(target) or 0
  local delta = wrapAngleSky(target - current)
  local a = 1 - math.exp(-math.max(0, tonumber(sharpness) or 0) * math.max(0, tonumber(dt) or 0))
  return wrapAngleSky(current + delta * a)
end

local function headingFromVector(x, y)
  x, y = tonumber(x) or 0, tonumber(y) or 0
  if math.atan2 then return math.atan2(y, x) end
  if x > 0 then return math.atan(y / x) end
  if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
  if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
  if y > 0 then return math.pi * 0.5 end
  if y < 0 then return -math.pi * 0.5 end
  return 0
end

local function facingFromHeading(heading)
  local cx, sy = math.cos(heading or 0), math.sin(heading or 0)
  if math.abs(cx) >= math.abs(sy) then return cx >= 0 and "right" or "left" end
  return sy >= 0 and "down" or "up"
end

local function cleanName(value)
  return tostring(value or ""):gsub("\n", " "):gsub("^LANDMARK_", ""):gsub("_", " ")
end

local LANDING_SETTLEMENTS = SETTLEMENT_NAMES

local function normalizedAnchorName(anchor)
  local value = tostring(anchor and (anchor.name or anchor.id) or "")
  value = value:gsub("^LANDMARK_", ""):gsub("_", " "):gsub("[%c]", " "):gsub("%s+", " ")
  return value:upper():gsub("^%s+", ""):gsub("%s+$", "")
end

local function isLandingSettlement(anchor, region)
  local set = LANDING_SETTLEMENTS[region or (anchor and anchor.region)]
  return set and set[normalizedAnchorName(anchor)] == true or false
end

local function atlasAnchor(id, region)
  if type(openSkyApi.atlas) ~= "function" then return nil end
  local ok, atlas = pcall(openSkyApi.atlas)
  if not ok or type(atlas) ~= "table" then return nil end
  for _, anchor in ipairs(atlas[region] or {}) do
    if anchor.id == id then return cloneAnchorWithCalibration(anchor, region) end
  end
  return nil
end

local function visitedPoints(game, region)
  local fieldMoves = fieldMovesModule()
  local landmarks = game and game.data and game.data.gen2Landmarks
  if not (fieldMoves and landmarks) then return {} end
  if type(fieldMoves.FLYPOINTS) == "table" and type(fieldMoves.hasVisitedSpawn) == "function" then
    local out = {}
    for _, sourceRow in ipairs(fieldMoves.FLYPOINTS) do
      local anchor = atlasAnchor(sourceRow.landmark, region)
      if anchor and isLandingSettlement(anchor, region) then
        local okVisited, visited = pcall(fieldMoves.hasVisitedSpawn, game and game.save, sourceRow.spawn)
        if okVisited and visited == true then
          local row = {}
          for k, v in pairs(sourceRow) do row[k] = v end
