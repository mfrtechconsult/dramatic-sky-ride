local mod = ...

local Safety = {}
local runtime, compat, settings, progression
local reachedCache = nil
local overrides = {}
local lastNoticeAt = -100

local VANILLA = {
  PALLET_TOWN=true,VIRIDIAN_CITY=true,PEWTER_CITY=true,CERULEAN_CITY=true,
  VERMILION_CITY=true,LAVENDER_TOWN=true,CELADON_CITY=true,FUCHSIA_CITY=true,
  SAFFRON_CITY=true,CINNABAR_ISLAND=true,INDIGO_PLATEAU=true,VIRIDIAN_FOREST=true,
}
for i=1,25 do VANILLA["ROUTE_"..i]=true end

local function now()
  if love and love.timer and love.timer.getTime then return love.timer.getTime() end
  return os.clock()
end

local function gated(mapId)
  if type(mapId) ~= "string" or mapId == "" then return false end
  if overrides[mapId] ~= nil then return overrides[mapId] end
  return VANILLA[mapId] == true
end

local function reached()
  if type(reachedCache) == "table" then return reachedCache end
  local value={}
  if mod.save and type(mod.save.get)=="function" then
    local ok,saved=pcall(mod.save.get,mod.save,"legitimately_reached_maps",{})
    if ok and type(saved)=="table" then value=saved end
  end
  reachedCache=value
  return value
end

local function persist()
  if mod.save and type(mod.save.set)=="function" then
    pcall(mod.save.set,mod.save,"legitimately_reached_maps",reached())
  end
end

local function mark(mapId)
  if type(mapId) ~= "string" or mapId == "" then return false end
  local r=reached()
  if r[mapId] then return false end
  r[mapId]=true
  persist()
  return true
end

local function isReached(mapId)
  if not gated(mapId) then return true end
  return reached()[mapId] == true
end

local function notice(game,text)
  local t=now()
  if t-lastNoticeAt < 1.0 then return end
  lastNoticeAt=t
  compat.say(game,text)
  compat.rumble(0.18,0.35,0.12)
end

local function blocks(game,target)
  if not runtime.public.isFlying() then return false end
  if settings.bool("discovery_gates",true) and gated(target) and not isReached(target) then
    return true,"AREA NOT VISITED"
  end
  if settings.bool("story_gates",true) and progression.storyGateBlocks(game,target) then
    return true,"STORY PROGRESSION BLOCKS THIS AREA"
  end
  return false
end

local function installGen1ConnectionGuard()
  local ok,OW=pcall(require,"src.world.OverworldController")
  if not (ok and OW and type(OW.crossConnection)=="function") then return false end
  if OW.dramaticSkyRideCleanSafetyGate then return true end
  local native=OW.crossConnection
  function OW:crossConnection(dir,conn,...)
    local game=compat.game(nil)
    local target=conn and (conn.mapId or conn.map)
    local blocked,reason=blocks(game,target)
    if blocked then
      notice(game,reason)
      return false
    end
    return native(self,dir,conn,...)
  end
  OW.dramaticSkyRideCleanSafetyGate=true
  return true
end

function Safety.install(deps)
  runtime,compat,settings,progression=deps.runtime,deps.compat,deps.settings,deps.progression
  installGen1ConnectionGuard()

  mod.events:on("save.loaded",function() reachedCache=nil end)
  mod.events:on("save.created",function() reachedCache=nil end)
  mod.events:on("game.ready",function(ev)
    reachedCache=nil
    if not runtime.public.isFlying() then
      mark(compat.mapId(ev and ev.game or nil))
    end
  end)
  mod.events:on("map.entered",function(ev)
    if runtime.public.isFlying() then return end
    mark(ev and ev.mapId or compat.mapId(nil))
  end)

  mod.exports.flightRules=mod.exports.flightRules or {}
  mod.exports.flightRules.discoveryGates=function() return settings.bool("discovery_gates",true) end
  mod.exports.flightRules.isMapReached=isReached
  mod.exports.flightRules.markMapReached=mark
  mod.exports.flightRules.registerDiscoveryGate=function(mapId,enabled)
    if type(mapId)~="string" or mapId=="" then return false end
    overrides[mapId]=enabled ~= false
    return true
  end
  mod.exports.flightRules.clearDiscoveryGateOverride=function(mapId)
    if type(mapId)~="string" or mapId=="" then return false end
    overrides[mapId]=nil
    return true
  end
end

return Safety
