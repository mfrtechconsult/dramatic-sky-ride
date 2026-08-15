;(function()
local openSkyInputApi = mod.exports.openSky or {}
local openSkyPlayableInput = mod.exports.openSkyPlayable or {}
local patchedInputStates = setmetatable({}, { __mode = "k" })
local blockedUntilAltitudeNeutral = false
local SAFE_LOCAL_ALTITUDE = 78

local function altitudeDir()
  if type(altitudeInputDirection) ~= "function" then return 0 end
  local ok, value = pcall(altitudeInputDirection)
  return ok and tonumber(value) or 0
end
local function openSkyStatus()
  if type(openSkyInputApi.status) ~= "function" then return {} end
  local ok, status = pcall(openSkyInputApi.status)
  return ok and type(status) == "table" and status or {}
end
local function runtimeExit(reason) return type(reason) == "string" and reason:match("^runtime_") ~= nil end
local function blockLocalReentryWhileHeld()
  if not blockedUntilAltitudeNeutral then return end
  if altitudeDir() == 0 then blockedUntilAltitudeNeutral = false; return end
  flight.altitude = SAFE_LOCAL_ALTITUDE
  flight.requestedAltitude = SAFE_LOCAL_ALTITUDE
  flight.targetAltitude = SAFE_LOCAL_ALTITUDE
  flight.verticalInput = 0
end
local function patchState(state)
  if type(state) ~= "table" or patchedInputStates[state] then return end
  local rawUpdate = state.update
  if type(rawUpdate) ~= "function" then return end
  patchedInputStates[state] = true
  state._dsrOpenSkyAltitudeArmed = altitudeDir() == 0
  state.update = function(self, dt)
    local dir = altitudeDir()
    if not self._dsrOpenSkyAltitudeArmed then
      if dir == 0 then self._dsrOpenSkyAltitudeArmed = true else return nil end
    end
    local wasActive = type(openSkyInputApi.active) == "function" and openSkyInputApi.active() == true
    local result = rawUpdate(self, dt)
    if wasActive then
      local status = openSkyStatus()
      if runtimeExit(status.lastExitReason) and dir ~= 0 then blockedUntilAltitudeNeutral = true end
    end
    return result
  end
end
local function patchCurrentState()
  if type(openSkyPlayableInput.state) ~= "function" then return end
  local ok, state = pcall(openSkyPlayableInput.state)
  if ok and state then patchState(state) end
end
local previousOpenSkyInputUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  blockLocalReentryWhileHeld()
  local before = openSkyStatus()
  local result = previousOpenSkyInputUpdate(self, dt, ...)
  patchCurrentState()
  local after = openSkyStatus()
  if (tonumber(after.enterCount) or 0) > (tonumber(before.enterCount) or 0)
      and runtimeExit(after.lastExitReason) and altitudeDir() ~= 0 then
    blockedUntilAltitudeNeutral = true
  end
  return result
end
openSkyPlayableInput.altitudeInputLatch = true
openSkyPlayableInput.altitudeInputArmed = function()
  if type(openSkyPlayableInput.state) ~= "function" then return true end
  local ok, state = pcall(openSkyPlayableInput.state)
  if not ok or not state then return true end
  return state._dsrOpenSkyAltitudeArmed == true
end
openSkyPlayableInput.reentryBlockedByHeldAltitude = function() return blockedUntilAltitudeNeutral end
log("Gen2 Open Sky held-altitude input latch loaded")
end)();
