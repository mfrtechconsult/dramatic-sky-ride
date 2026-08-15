;(function()
local openSkyApi = mod.exports.openSky or {}
local playable = mod.exports.openSkyPlayable or {}
local patchedStates = setmetatable({}, { __mode = "k" })
local lastRuntimeError = nil
local SAFE_REENTRY_ALTITUDE = 78

local function rememberError(kind, err)
  lastRuntimeError = { kind = tostring(kind or "unknown"), message = tostring(err or "unknown error") }
  pcall(function() log("Open Sky runtime guard caught %s error: %s", lastRuntimeError.kind, lastRuntimeError.message) end)
end

local function safeNotice(text, seconds) pcall(function() notifyHud(text, seconds or 2.0) end) end
local function currentState()
  if type(playable.state) ~= "function" then return nil end
  local ok, state = pcall(playable.state)
  return ok and state or nil
end
local function popIfCurrent(state)
  local game = state and state.game
  local stack = game and game.stack
  if not stack then return end
  local ok, top = pcall(stack.top, stack)
  if ok and top == state then pcall(stack.pop, stack) end
end
local function recoverToLocal(state, reason)
  flight.active = true
  flight.phase = "cruise"
  flight.altitude = SAFE_REENTRY_ALTITUDE
  flight.requestedAltitude = SAFE_REENTRY_ALTITUDE
  flight.targetAltitude = SAFE_REENTRY_ALTITUDE
  flight.verticalInput = 0
  if type(openSkyApi.leave) == "function" then pcall(openSkyApi.leave, reason or "runtime_guard") end
  popIfCurrent(state)
  safeNotice("OPEN SKY ERROR - LOCAL FLIGHT RESTORED", 2.5)
end
local function stableVisitedPoints(region)
  if type(playable.visitedPoints) ~= "function" then return {} end
  local ok, rows = pcall(playable.visitedPoints, region)
  return ok and type(rows) == "table" and rows or {}
end
local function stableAtlas(region)
  if type(openSkyApi.atlas) ~= "function" then return {} end
  local ok, atlas = pcall(openSkyApi.atlas)
  if not ok or type(atlas) ~= "table" then return {} end
  return type(atlas[region]) == "table" and atlas[region] or {}
end
local function safeDraw(state)
  if not (love and love.graphics) then return end
  local G = love.graphics
  local pushed = false
  local ok, err = pcall(function()
    if type(G.push) == "function" then G.push(); pushed = true end
    G.setColor(0.58, 0.80, 0.96, 1); G.rectangle("fill", 0, 0, 160, 144)
    G.setColor(0.22, 0.46, 0.29, 0.75)
    for _, anchor in ipairs(stableAtlas(state.region)) do local x,y=tonumber(anchor.x),tonumber(anchor.y); if x and y then G.circle("fill",x,y,1.5) end end
    local nearestSpawn = state.nearest and state.nearest.row and state.nearest.row.spawn or nil
    for _, point in ipairs(stableVisitedPoints(state.region)) do
      local a=point and point.anchor; local x,y=tonumber(a and a.x),tonumber(a and a.y)
      if x and y then
        local selected=nearestSpawn~=nil and point.row and point.row.spawn==nearestSpawn
        if selected then G.setColor(1,1,1,0.95); G.circle("line",x,y,11) end
        G.setColor(1,1,1,0.90); G.circle("fill",x,y,2)
      end
    end
    local x=tonumber(state.x) or 80; local y=tonumber(state.y) or 72
    G.setColor(1,1,1,1); G.polygon("fill",x,y-5,x+5,y+5,x,y+2,x-5,y+5); G.circle("line",x,y,7)
    G.setColor(0,0,0,0.72); G.rectangle("fill",0,0,160,18); G.rectangle("fill",0,124,160,20); G.setColor(1,1,1,1)
    if type(G.print)=="function" then
      local region=state.region=="kanto" and "KANTO" or "JOHTO"; local altitude=math.floor((tonumber(state.virtualAltitude) or 88)+0.5)
      G.print("OPEN SKY - "..region.."  ALT "..tostring(altitude),4,4)
      local bottom=state.notice
      if not bottom then local name=state.nearest and state.nearest.row and (state.nearest.row.name or state.nearest.row.landmark); bottom=name and ("A: DESCEND  "..tostring(name)) or "FLY TO A VISITED LANDING POINT" end
      G.print(tostring(bottom),4,128)
    end
  end)
  if pushed then pcall(G.pop) end
  if not ok then rememberError("draw",err) end
end
local function patchState(state)
  if type(state)~="table" or patchedStates[state] then return end
  patchedStates[state]=true
  local rawUpdate=state.update
  if type(rawUpdate)=="function" then
    state.update=function(self,dt)
      local ok,result=pcall(rawUpdate,self,dt)
      if ok then return result end
      rememberError("update",result); recoverToLocal(self,"runtime_update_error"); return nil
    end
  end
  state.draw=function(self) safeDraw(self) end
end
local function patchCurrentState() local state=currentState(); if state then patchState(state) end end
local previousGuardedOpenSkyUpdate=OverworldState.update
function OverworldState:update(dt,...)
  local extras={...}; local unpackArgs=table.unpack or unpack
  local ok,result=pcall(function() return previousGuardedOpenSkyUpdate(self,dt,unpackArgs(extras)) end)
  if not ok then rememberError("entry",result); recoverToLocal(currentState(),"runtime_entry_error"); return nil end
  patchCurrentState(); return result
end
playable.runtimeGuard=true
playable.safeRenderer=function() return true end
playable.lastRuntimeError=function() return lastRuntimeError end
log("Gen2 Open Sky runtime guard loaded (safe regional renderer enabled)")
end)();
