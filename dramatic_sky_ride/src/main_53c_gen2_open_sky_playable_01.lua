;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky playable regional layer.
--
-- The local overworld remains the authoritative world underneath this opaque
-- state. Entering Open Sky freezes that map in place and moves a virtual mount
-- over a collision-free screen-space navigation plane. Native Gold/Stadium
-- coordinates are used only for city markers/landing data, never as movement
-- geometry. Re-entry keeps DSR
-- airborne so the final descent/landing still happens through Dramatic Sky
-- Ride rather than through the vanilla Fly animation.
-- -------------------------------------------------------------------------
local OPEN_SKY_REENTRY_ALTITUDE = 78
-- Open Sky is a regional map, not a first/third-person flight simulator.
-- The D-pad still chooses the desired screen direction, but the cursor/mount
-- accelerates quickly, glides and turns into that direction instead of snapping a
-- full movement vector on the first frame. Default travel is intentionally brisk,
-- close to later-gen regional Fly menus, while keeping DSR's manual,
-- no-auto-forward contract.
local OPEN_SKY_MOVE_SPEED = 56.0
local OPEN_SKY_BOOST_SPEED = 96.0
local OPEN_SKY_LAND_RADIUS = 11
local OPEN_SKY_MOVE_RESPONSE = 13.5
local OPEN_SKY_COAST_RESPONSE = 10.0
local OPEN_SKY_HEADING_RESPONSE = 15.0
local REGION_PREVIEW_MARGIN = 22 -- native-map calibration/editor only
local MAP_MIN_X, MAP_MAX_X = 6, 154
local MAP_MIN_Y, MAP_MAX_Y = 22, 138
-- Stadium 2's official regional viewport. Normal Open Sky movement is
-- authoritative in this flat screen space, so the exact same commanded speed
-- produces the exact same visible displacement over land, sea, mountains or
-- any sparse/degenerate section of the Stadium warp table.
local NAV_W, NAV_H = 312, 232
local NAV_MIN_X, NAV_MAX_X = 0, NAV_W
local NAV_MIN_Y, NAV_MAX_Y = 0, NAV_H
local REGION_PREVIEW_MARGIN_SCREEN = 46

local generation = mod.exports.runtimeGeneration or {}
local openSkyApi = mod.exports.openSky or {}
local projectOpenSkyPoint
local FieldMoves2 = nil
local Pokegear2 = nil
local Chrome2 = nil

local CALIBRATION_DIR = "dramatic_sky_ride"
local CALIBRATION_FILE = CALIBRATION_DIR .. "/open_sky_points.csv"
local calibration = {
  loaded = false,
  points = { johto = {}, kanto = {} },
  lastError = nil,
  lastSaved = nil,
  lastExport = nil,
}

local SETTLEMENT_NAMES = {
  johto = {
    ["NEW BARK TOWN"] = true, ["CHERRYGROVE CITY"] = true,
    ["VIOLET CITY"] = true, ["AZALEA TOWN"] = true,
    ["GOLDENROD CITY"] = true, ["ECRUTEAK CITY"] = true,
    ["OLIVINE CITY"] = true, ["CIANWOOD CITY"] = true,
    ["MAHOGANY TOWN"] = true, ["BLACKTHORN CITY"] = true,
  },
  kanto = {
    ["PALLET TOWN"] = true, ["VIRIDIAN CITY"] = true,
    ["PEWTER CITY"] = true, ["CERULEAN CITY"] = true,
    ["VERMILION CITY"] = true, ["LAVENDER TOWN"] = true,
    ["CELADON CITY"] = true, ["SAFFRON CITY"] = true,
    ["FUCHSIA CITY"] = true, ["CINNABAR ISLAND"] = true,
  },
}

local function calibrationAnchorName(anchor)
  local value = tostring(anchor and (anchor.name or anchor.id) or "")
  value = value:gsub("^LANDMARK_", ""):gsub("_", " ")
    :gsub("[%c]", " "):gsub("%s+", " ")
  return value:upper():gsub("^%s+", ""):gsub("%s+$", "")
end

local function isCalibrationSettlement(anchor, region)
  local set = SETTLEMENT_NAMES[region or (anchor and anchor.region)]
  return set and set[calibrationAnchorName(anchor)] == true or false
end

local function calibrationLoad(force)
  if calibration.loaded and not force then return true end
  if force then calibration.points = { johto = {}, kanto = {} } end
  calibration.loaded = true
  calibration.lastError = nil
  return true
end

local function calibrationSave()
  calibrationLoad()
  calibration.lastError = nil
  calibration.lastSaved = os and os.time and os.time() or true
  return true, "session_only"
end

local function calibrationPoint(region, id)
  calibrationLoad()
  local points = calibration.points[region]
  return points and points[id] or nil
end

local function cloneAnchorWithCalibration(anchor, region)
  if type(anchor) ~= "table" then return nil end
  local point = calibrationPoint(region or anchor.region, anchor.id)
  if not point then return anchor end
  local out = {}
  for k, v in pairs(anchor) do out[k] = v end
  out.x, out.y = point.x, point.y
  out.calibrated = true
  return out
end

local function calibrationKeyPressed(state, key)
  if not (love and love.keyboard and type(love.keyboard.isDown) == "function") then
    return false
  end
  state._calibrationKeys = state._calibrationKeys or {}
  local down = love.keyboard.isDown(key) == true
  local previous = state._calibrationKeys[key] == true
  state._calibrationKeys[key] = down
  return down and not previous
end

local function calibrationKeyDown(key)
  return love and love.keyboard and type(love.keyboard.isDown) == "function"
    and love.keyboard.isDown(key) == true
end

local function calibrationAnchors(region)
  local ok, atlas = pcall(function()
    return type(openSkyApi.atlas) == "function" and openSkyApi.atlas() or nil
  end)
  if not ok or type(atlas) ~= "table" then return {} end
  local out = {}
  for _, anchor in ipairs(atlas[region] or {}) do
    if isCalibrationSettlement(anchor, region) then
      out[#out + 1] = anchor
    end
  end
  return out
end

local function calibrationSelection(state)
  local list = calibrationAnchors(state.region)
  if #list == 0 then return nil, list end
  state.calibrationIndex = math.max(1,
    math.min(#list, tonumber(state.calibrationIndex) or 1))
  return list[state.calibrationIndex], list
end

local function calibrationFocusSelection(state)
  local anchor = calibrationSelection(state)
  if not anchor then return false end
  local point = calibrationPoint(state.region, anchor.id) or anchor
  state.x = tonumber(point.x) or tonumber(anchor.x) or 80
  state.y = tonumber(point.y) or tonumber(anchor.y) or 78
  if type(projectOpenSkyPoint) == "function" then
    state.screenX, state.screenY = projectOpenSkyPoint(state.region, state.x, state.y)
  end
  state.speed, state.targetSpeed = 0, 0
  state.screenVelocityX, state.screenVelocityY = 0, 0
  state:refreshNearest()
  return true
end

local function calibrationSelectDelta(state, delta, focus)
  local _, list = calibrationSelection(state)
  if #list == 0 then return end
  local index = (tonumber(state.calibrationIndex) or 1) + delta
  while index < 1 do index = index + #list end
  while index > #list do index = index - #list end
  state.calibrationIndex = index
  if focus ~= false then calibrationFocusSelection(state) end
end

local function calibrationValidatedCount(region)
  local count = 0
  for _, anchor in ipairs(calibrationAnchors(region)) do
    if calibrationPoint(region, anchor.id) then count = count + 1 end
  end
  return count
end

local function calibrationExportText()
  calibrationLoad()
  local rows, missing = {}, {}
  local validated, total = 0, 0
  for _, region in ipairs({ "johto", "kanto" }) do
    for _, anchor in ipairs(calibrationAnchors(region)) do
      total = total + 1
      local point = calibrationPoint(region, anchor.id)
      if point then
        validated = validated + 1
        rows[#rows + 1] = string.format("%s|%s|%.2f|%.2f",
          region, tostring(anchor.id), tonumber(point.x) or 0,
          tonumber(point.y) or 0)
      else
        missing[#missing + 1] = string.format("%s|%s", region, tostring(anchor.id))
      end
    end
  end
  local lines = {
    "# DRAMATIC SKY RIDE - OPEN SKY CITY CALIBRATION",
    "# format: region|landmark_id|x|y",
    string.format("# status: %d/%d validated", validated, total),
  }
  for _, row in ipairs(rows) do lines[#lines + 1] = row end
  if #missing > 0 then
    lines[#lines + 1] = "# MISSING - validate these cities before final integration:"
    for _, row in ipairs(missing) do lines[#lines + 1] = "# " .. row end
  end
  return table.concat(lines, "\n"), validated, total
end

local function calibrationExport(state)
