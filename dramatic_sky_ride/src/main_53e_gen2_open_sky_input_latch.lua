;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky altitude-input latch.
--
-- The normal way to reach Open Sky is to KEEP holding R2/Page Up while local
-- flight climbs through the entry altitude. That same held control must not be
-- interpreted as a fresh Open Sky altitude command on the very first regional
-- frame. Wait for a neutral altitude frame before arming regional altitude
-- controls. This makes the local -> regional transition stable even when the
-- player never releases the climb control during the hand-off.
--
-- The runtime guard can also deliberately restore local flight to altitude 78
-- after a protected callback error. If that happens while climb is still held,
-- keep local altitude below the entry threshold until the control is released;
-- otherwise it would immediately climb back to 88 and reopen Open Sky in a
-- tight loop.
-- -------------------------------------------------------------------------
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

local function runtimeExit(reason)
  return type(reason) == "string" and reason:match("^runtime_") ~= nil
end

local function blockLocalReentryWhileHeld()
  if not blockedUntilAltitudeNeutral then return end
  if altitudeDir() == 0 then
    blockedUntilAltitudeNeutral = false
    return
  end

  -- Reset on every local frame while the inherited trigger remains held. The
  -- underlying flight update may add a fraction of altitude afterwards, but
  -- the next frame starts back here, safely below Open Sky's altitude 88 gate.
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
  -- Arm immediately only when Open Sky was entered with no altitude control
  -- held. In the common climb-through-88 case this starts false.
  state._dsrOpenSkyAltitudeArmed = altitudeDir() == 0

  state.update = function(self, dt)
    local dir = altitudeDir()
    if not self._dsrOpenSkyAltitudeArmed then
      if dir == 0 then
        self._dsrOpenSkyAltitudeArmed = true
      else
        -- Deliberately do NOT call main_53c's updater yet. Its regional state
        -- remains on the stack and visible, but the inherited climb press is
        -- consumed by the transition rather than becoming a new command.
        return nil
      end
    end

    local wasActive = type(openSkyInputApi.active) == "function"
      and openSkyInputApi.active() == true
    local result = rawUpdate(self, dt)
    if wasActive then
      local status = openSkyStatus()
      if runtimeExit(status.lastExitReason) and dir ~= 0 then
        blockedUntilAltitudeNeutral = true
      end
    end
    return result
  end
end

local function patchCurrentState()
  if type(openSkyPlayableInput.state) ~= "function" then return end
  local ok, state = pcall(openSkyPlayableInput.state)
  if ok and state then patchState(state) end
end

-- main_53d already protects this transition. This final wrapper adds only the
-- input hand-off rule and anti-reopen latch; it does not change Open Sky's map,
-- navigation, landing rules or renderer.
local previousOpenSkyInputUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  blockLocalReentryWhileHeld()

  local before = openSkyStatus()
  local result = previousOpenSkyInputUpdate(self, dt, ...)
  patchCurrentState()

  -- Entry itself can fail inside main_53d before a state survives long enough
  -- for patchState() to wrap it. Detect that same-frame protected exit here.
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
openSkyPlayableInput.reentryBlockedByHeldAltitude = function()
  return blockedUntilAltitudeNeutral
end

log("Gen2 Open Sky held-altitude input latch loaded")
end)();
