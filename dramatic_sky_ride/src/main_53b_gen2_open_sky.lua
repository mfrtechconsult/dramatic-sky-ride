;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky / regional-soaring prototype.
--
-- Stage 1 deliberately does NOT replace Gold's overworld renderer or move the
-- player between maps. It establishes the safe contract the later regional
-- renderer can consume: an opt-in setting, altitude hysteresis, Gen 2/outdoor
-- eligibility, a Johto/Kanto landmark atlas, progression-aware Kanto access,
-- and one public state/API shared by future navigation and rendering layers.
-- -------------------------------------------------------------------------
local OPEN_SKY_ENTRY_ALTITUDE = 88
local OPEN_SKY_EXIT_ALTITUDE = 76
local OPEN_SKY_OPTION = "regional_soaring"

local function appendOptionOnce(row)
  for _, existing in ipairs(OPTION_SCHEMA or {}) do
    if existing.key == row.key then return existing end
  end
  OPTION_SCHEMA[#OPTION_SCHEMA + 1] = row
  return row
end

appendOptionOnce({
  key = OPEN_SKY_OPTION,
  type = "toggle",
  label = "REGIONAL SOARING",
  default = false,
  help = "Experimental Gen 2 Open Sky. Climb above altitude 88 to enter the regional-soaring layer.",
})

local generation = mod.exports.runtimeGeneration or {}
local Map2 = nil
local Nests = nil
local FieldMoves2 = nil

local openSky = {
  active = false,
  mode = "local",
  region = nil,
  anchor = nil,
  atlas = nil,
  atlasSource = nil,
  kantoUnlocked = false,
  enteredAtAltitude = nil,
  enteredFrom = nil,
  lastExitReason = nil,
  enterCount = 0,
}
flight.openSky = openSky

local function isGen2()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function enabled()
  return optionValue(OPEN_SKY_OPTION, false) == true
end

local function liveWorld()
  return mod.exports._mountWorld(Game)
end

local function gen2MapModule()
  if Map2 ~= nil then return Map2 or nil end
  local ok, value = pcall(require, "src.world.gen2.Map")
  Map2 = ok and value or false
  return Map2 or nil
end

local function nestsModule()
  if Nests ~= nil then return Nests or nil end
  local ok, value = pcall(require, "src.core.gen2.Nests")
  Nests = ok and value or false
  return Nests or nil
end

local function fieldMovesModule()
  if FieldMoves2 ~= nil then return FieldMoves2 or nil end
  local ok, value = pcall(require, "src.world.gen2.FieldMoves")
  FieldMoves2 = ok and value or false
  return FieldMoves2 or nil
end

local function regionOfIndex(index)
  index = tonumber(index)
  if not index then return nil end
  local nests = nestsModule()
  if nests and type(nests.regionOf) == "function" then
    local ok, region = pcall(nests.regionOf, index)
    if ok and (region == "johto" or region == "kanto") then return region end
  end
  -- Gold constants: PALLET_TOWN = $2e and FAST_SHIP = $5e. The ship is a
  -- special location rather than a region, matching Nests.regionOf().
  if index > 0 and index < 0x2e then return "johto" end
  if index >= 0x2e and index < 0x5e then return "kanto" end
  return nil
end

local function outdoorWorld(world)
  if not (world and world.map and world.map.def) then return false end
  local mapClass = gen2MapModule()
  if mapClass and type(mapClass.isOutdoor) == "function" then
    local ok, outside = pcall(mapClass.isOutdoor, world.map.def)
    if ok then return outside == true end
  end
  local env = world.map.def.environment
  return env == "TOWN" or env == "ROUTE"
end

local function buildAtlas()
  local registry = Game.data and Game.data.gen2Landmarks or nil
  local source = registry and registry.landmarks or nil
  if type(source) ~= "table" then
    openSky.atlas = { anchors = {}, johto = {}, kanto = {}, byIndex = {} }
    openSky.atlasSource = source
    return openSky.atlas
  end
  if openSky.atlas and openSky.atlasSource == source then return openSky.atlas end

  local atlas = { anchors = {}, johto = {}, kanto = {}, byIndex = {} }
  for id, record in pairs(source) do
    if type(record) == "table" then
      local index = tonumber(record.index)
      local x, y = tonumber(record.x), tonumber(record.y)
      local region = regionOfIndex(index)
      if index and x and y and region then
        local anchor = {
          id = id,
          name = record.name or id,
          index = index,
          x = x,
          y = y,
          region = region,
        }
        atlas.anchors[#atlas.anchors + 1] = anchor
        atlas[region][#atlas[region] + 1] = anchor
        -- Vanilla data owns its index. If a mod intentionally introduces a
        -- duplicate index, keep the first deterministic id after sorting.
        atlas.byIndex[index] = atlas.byIndex[index] or anchor
      end
    end
  end

  local function sortAnchors(a, b)
    if a.index ~= b.index then return a.index < b.index end
    return tostring(a.id) < tostring(b.id)
  end
  table.sort(atlas.anchors, sortAnchors)
  table.sort(atlas.johto, sortAnchors)
  table.sort(atlas.kanto, sortAnchors)

  -- Rebuild duplicate-index ownership deterministically after sorting.
  atlas.byIndex = {}
  for _, anchor in ipairs(atlas.anchors) do
    atlas.byIndex[anchor.index] = atlas.byIndex[anchor.index] or anchor
  end

  openSky.atlas = atlas
  openSky.atlasSource = source
  return atlas
end

local function currentAnchor(world)
  world = world or liveWorld()
  local index = world and world.map and world.map.def
    and tonumber(world.map.def.landmark) or nil
  if not index then return nil end
  return buildAtlas().byIndex[index]
end

local function kantoUnlocked(world)
  world = world or liveWorld()
  local anchor = currentAnchor(world)
  -- Once the player is legitimately standing in Kanto, never hide it because
  -- an older/partial Gen1Recomp++ build lacks the helper below.
  if anchor and anchor.region == "kanto" then return true end

  local fieldMoves = fieldMovesModule()
  if fieldMoves and type(fieldMoves.hasVisitedSpawn) == "function" then
    local ok, visited = pcall(fieldMoves.hasVisitedSpawn,
      Game.save, "SPAWN_INDIGO")
    if ok then return visited == true end
  end
  return false
end

local function canEnter(world)
  if not enabled() then return false, "disabled" end
  if not isGen2() then return false, "gen1" end
  if not (flight.active and flight.phase == "cruise") then
    return false, "not_cruising"
  end
  if (tonumber(flight.altitude) or 0) < OPEN_SKY_ENTRY_ALTITUDE then
    return false, "below_entry_altitude"
  end
  world = world or liveWorld()
  if not outdoorWorld(world) then return false, "not_outdoors" end
  local anchor = currentAnchor(world)
  if not anchor then return false, "no_regional_anchor" end
  return true, nil, anchor
end

local function leave(reason)
  if not openSky.active then return false end
  openSky.active = false
  openSky.mode = "local"
  openSky.region = nil
  openSky.anchor = nil
  openSky.lastExitReason = reason or "descend"
  openSky.enteredAtAltitude = nil
  openSky.enteredFrom = nil
  return true
end

local function enter(world, anchor)
  if openSky.active then return true end
  local ok, reason, resolved = canEnter(world)
  if not ok then return false, reason end
  anchor = anchor or resolved
  world = world or liveWorld()

  openSky.active = true
  openSky.mode = "open_sky"
  openSky.anchor = anchor
  openSky.region = anchor and anchor.region or nil
  openSky.kantoUnlocked = kantoUnlocked(world)
  openSky.enteredAtAltitude = tonumber(flight.altitude) or 0
  openSky.enterCount = (openSky.enterCount or 0) + 1
  openSky.enteredFrom = {
    map = world and world.map and world.map.id or nil,
    x = world and world.player and world.player.cellX or nil,
    y = world and world.player and world.player.cellY or nil,
    landmark = anchor and anchor.id or nil,
  }

  notifyHud("OPEN SKY READY", 2.0)
  log("Open Sky prototype entered region=%s landmark=%s altitude=%.1f kanto=%s",
    tostring(openSky.region), tostring(anchor and anchor.id),
    openSky.enteredAtAltitude, tostring(openSky.kantoUnlocked))
  return true
end

local function updateOpenSky()
  local world = liveWorld()

  if openSky.active then
    local altitude = tonumber(flight.altitude) or 0
    if not enabled() then
      leave("disabled")
    elseif not isGen2() then
      leave("runtime_changed")
    elseif not (flight.active and flight.phase == "cruise") then
      leave("flight_ended")
    elseif not outdoorWorld(world) then
      leave("left_outdoors")
    elseif altitude <= OPEN_SKY_EXIT_ALTITUDE then
      leave("descended")
    else
      local anchor = currentAnchor(world)
      if anchor then
        openSky.anchor = anchor
        openSky.region = anchor.region
      end
      openSky.kantoUnlocked = kantoUnlocked(world)
    end
    return
  end

  local ok, _, anchor = canEnter(world)
  if ok then enter(world, anchor) end
end

-- Observe the mature flight state after its normal tick. Stage 1 is read-only:
-- no setMap(), collision, player position, requested altitude or renderer is
-- changed here. Later Open Sky layers can therefore be developed independently
-- without destabilising normal Gen 2 flight.
local previousOpenSkyUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousOpenSkyUpdate(self, dt, ...)
  updateOpenSky()
  return result
end

mod.events:on("game.ready", function()
  leave("game_ready")
  openSky.atlas = nil
  openSky.atlasSource = nil
  buildAtlas()
end)

mod.exports.openSky = {
  api = 1,
  enabled = enabled,
  active = function() return openSky.active == true end,
  mode = function() return openSky.mode end,
  entryAltitude = function() return OPEN_SKY_ENTRY_ALTITUDE end,
  exitAltitude = function() return OPEN_SKY_EXIT_ALTITUDE end,
  atlas = buildAtlas,
  currentAnchor = currentAnchor,
  kantoUnlocked = kantoUnlocked,
  canEnter = canEnter,
  enter = enter,
  leave = leave,
  status = function()
    return {
      active = openSky.active == true,
      mode = openSky.mode,
      region = openSky.region,
      anchor = openSky.anchor,
      kantoUnlocked = openSky.kantoUnlocked == true,
      enteredAtAltitude = openSky.enteredAtAltitude,
      enteredFrom = openSky.enteredFrom,
      lastExitReason = openSky.lastExitReason,
      enterCount = openSky.enterCount or 0,
    }
  end,
}

log("Gen2 Open Sky prototype loaded (entry=%d exit=%d enabled=%s)",
  OPEN_SKY_ENTRY_ALTITUDE, OPEN_SKY_EXIT_ALTITUDE, tostring(enabled()))
end)();
