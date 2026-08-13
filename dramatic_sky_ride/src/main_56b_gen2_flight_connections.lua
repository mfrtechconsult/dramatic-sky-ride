;(function()
local generation = mod.exports.runtimeGeneration or {}
local KEYS = { up = "north", down = "south", left = "west", right = "east" }
local DELTA = { up={0,-1}, down={0,1}, left={-1,0}, right={1,0} }
local state = { world=nil, wrapper=nil, inner=nil, installs=0, fallbacks=0, blocked=0 }
local fixedStep

local function isGold()
  return type(generation.isGen2) == "function" and generation.isGen2(Game) == true
end

local function worldNow()
  local fn = mod.exports and mod.exports._mountWorld
  if type(fn) ~= "function" then return nil end
  local ok, world = pcall(fn, Game)
  return ok and world or nil
end

local function landing(dest, conn, dir, cx, cy)
  local w = tonumber(dest.widthCells) or ((tonumber(dest.width) or 0) * 2)
  local h = tonumber(dest.heightCells) or ((tonumber(dest.height) or 0) * 2)
  if w <= 0 or h <= 0 then return nil end
  local off = tonumber(conn.offset) or 0
  local x, y
  if dir == "up" then x, y = cx - off * 2, h - 1
  elseif dir == "down" then x, y = cx - off * 2, 0
  elseif dir == "left" then x, y = w - 1, cy - off * 2
  elseif dir == "right" then x, y = 0, cy - off * 2
  else return nil end
  x = math.max(0, math.min(w - 1, x))
  y = math.max(0, math.min(h - 1, y))
  return x, y
end

local function info(world, dir)
  if not (world and world.map and world.player and world.maps and KEYS[dir]
      and type(world.map.connection) == "function") then return nil end
  local conn = world.map:connection(KEYS[dir])
  local target = conn and (conn.mapId or conn.map)
  local dest = target and world.maps[target]
  if not (conn and target and dest) then return nil end
  local x, y = landing(dest, conn, dir, world.player.cellX, world.player.cellY)
  if x == nil then return nil end
  return { target=target, x=x, y=y, delta=DELTA[dir] }
end

local function notice(label)
  if (flight.storyGateNoticeCooldown or 0) <= 0 then
    notifyHud(label)
    feedback("blocked")
    flight.storyGateNoticeCooldown = 1.0
  end
end

local function allowed(target)
  local rules = mod.exports and mod.exports.flightRules
  if not rules then return true end
  if type(rules.storyGateBlocks) == "function" then
    local ok, blocked = pcall(rules.storyGateBlocks, target)
    if ok and blocked then notice("STORY BLOCKED"); state.blocked=state.blocked+1; return false end
  end
  if type(rules.discoveryGates) == "function" and type(rules.isMapReached) == "function" then
    local ok1, enabled = pcall(rules.discoveryGates)
    local ok2, reached = pcall(rules.isMapReached, target)
    if ok1 and enabled == true and ok2 and reached == false then
      notice("AREA NOT VISITED"); state.blocked=state.blocked+1; return false
    end
  end
  return true
end

local function discardCatchup()
  if fixedStep == nil then
    local ok, value = pcall(require, "src.core.FixedStep")
    fixedStep = ok and value or false
  end
  if fixedStep and type(fixedStep.discardCatchup) == "function" then
    pcall(fixedStep.discardCatchup, fixedStep)
  end
end

local function cross(world, dir, i)
  local p = world.player
  if not (p and type(world.setMap) == "function") then return false end
  if not world:setMap(i.target, i.x, i.y, dir, { seamless=true }) then return false end
  p.cellX, p.cellY = i.x - i.delta[1], i.y - i.delta[2]
  p.px, p.py = p.cellX * 16, p.cellY * 16
  p.facing = dir
  p.targetX, p.targetY = i.x, i.y
  p.moving, p.progress = true, 0
  p.inGrass, p.grassShake = false, nil
  discardCatchup()
  state.fallbacks = state.fallbacks + 1
  return true
end

local function install()
  local world = worldNow()
  if not (isGold() and flight.active and world) then
    state.world, state.wrapper, state.inner = nil, nil, nil
    return false
  end
  if state.world == world and state.wrapper and rawget(world, "tryConnection") == state.wrapper then
    return true
  end
  local inner = world.tryConnection
  if type(inner) ~= "function" then return false end
  local wrapper = function(self, dir, ...)
    if not (flight.active and isGold()) then return inner(self, dir, ...) end
    local i = info(self, dir)
    if not i then return inner(self, dir, ...) end
    if not allowed(i.target) then return false end
    local ok = inner(self, dir, ...)
    if ok then return ok end
    return cross(self, dir, i)
  end
  state.world, state.wrapper, state.inner = world, wrapper, inner
  rawset(world, "tryConnection", wrapper)
  state.installs = state.installs + 1
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  install()
  return result
end

mod.events:on("game.ready", install)
mod.events:on("mods.loaded", install)
mod.events:on("map.entered", install)

mod.exports.gen2FlightConnections = {
  api=1,
  status=function()
    return { installs=state.installs, fallbacks=state.fallbacks, blocked=state.blocked }
  end,
}

install()
log("Gen2 airborne map connection fix loaded")
end)();
