"lefttrigger" or button == "righttrigger"
      or button == "triggerleft" or button == "triggerright") then
    return
  end
  local selectHeld = Game.input and Game.input:isDown("select")
  if not selectHeld and joystick and joystick.isGamepadDown then
    local ok, down = pcall(joystick.isGamepadDown, joystick, "back")
    selectHeld = ok and down == true
  end
  if button == "rightshoulder" and selectHeld and useMountShortcut(self) then
    return
  end
  if flight.active and (button == "y" or button == "x") then
    if not blockExternalActionUntilManualLanding(self) then return end
  end
  return gameGamepadpressed(self, joystick, button, ...)
end

mod.hooks:wrap("movement.speed", function(next, frames, ctx)
  local value = next(frames, ctx)
  if flight.active and not isFreeCamera() and flightBoostEnabled() then
    local multiplier = 1 + (BOOST_MAX_MULTIPLIER - 1) * (flight.boost or 0)
    return math.max(4, (tonumber(value) or tonumber(frames) or 16) / multiplier)
  end
  return value
end, 80)

local flightBattleResume = nil

local function partyIndexFor(mon)
  for i, candidate in ipairs(Game.save and Game.save.party or {}) do
    if candidate == mon then return i end
  end
  return nil
end

local function resolveFlightBattleMount(snapshot)
  if not snapshot then return nil end
  local party = Game.save and Game.save.party or {}
  for _, mon in ipairs(party) do
    if mon == snapshot.mon then return mon end
  end
  local slotted = snapshot.index and party[snapshot.index]
  if slotted and mountSpecies(Game, slotted) then return slotted end
  if snapshot.nickname and snapshot.nickname ~= "" then
    for _, mon in ipairs(party) do
      if mon.nickname == snapshot.nickname and mountSpecies(Game, mon) then
        return mon
      end
    end
  end
  return nil
end

mod.events:on("battle.started", function()
  if not flight.active then return end
  -- The overworld is not updated while the battle is on top of the stack, so
  -- keeping the flight state alive freezes the mount naturally. The previous
  -- forceImmediateLand() call destroyed altitude and left a stale rider card.
  flightBattleResume = {
    mon = flight.mon,
    index = partyIndexFor(flight.mon),
    nickname = flight.mon and flight.mon.nickname,
    phase = flight.phase,
    altitude = flight.altitude,
    requestedAltitude = flight.requestedAltitude,
    targetAltitude = flight.targetAltitude,
    safetyAltitude = flight.safetyAltitude,
    boost = flight.boost,
  }
end)

mod.events:on("battle.ended", function(ev)
  local snapshot = flightBattleResume
  flightBattleResume = nil
  if not snapshot then return end

  local mon = resolveFlightBattleMount(snapshot)
  local species = mon and mountSpecies(Game, mon) or nil
  if (ev and ev.result == "lose") or not healthy(mon) or not species then
    -- A defeated, removed or no-longer-eligible mount cannot stay airborne.
    forceImmediateLand(Game)
    return
  end

  local sprite = flight.sprite
  if species ~= flight.species then
    local rebuilt = buildMountSprite(species)
    if not rebuilt then
      forceImmediateLand(Game)
      return
    end
    sprite = rebuilt
  end

  -- Restore the exact pre-battle airborne state. This also protects against
  -- another battle callback touching one of these values while the battle UI
  -- is being assembled or dismissed.
  flight.active = true
  flight.mon = mon
  flight.species = species
  flight.sprite = sprite
  flight.phase = snapshot.phase == "idle" and "cruise" or snapshot.phase
  flight.altitude = snapshot.altitude
  flight.requestedAltitude = snapshot.requestedAltitude
  flight.targetAltitude = snapshot.targetAltitude
  flight.safetyAltitude = snapshot.safetyAltitude
  flight.boost = snapshot.boost
  flight.boostWasHeld = false

  local ow = Game.overworld
  if ow then
    purgeFollowersDuringFlight(ow)
    if showRiderEnabled() then ensureRiderEntity(ow) else removeRiderEntity(ow) end
    ensureGroundFxEntity(ow)
  end
end)

mod.events:on("save.writing", function()
  -- The vanilla SAVE row is blocked above and asks for a manual landing. This
  -- remains as an emergency compatibility guard for another mod that calls
  -- writeSave directly without going through the START menu hook.
  if flight.active then forceImmediateLand(Game) end
end)

mod.exports.isFlying = function() return flight.active end
mod.exports.isCameraSupported = function(level) return isSupportedVoxelMode(level) end
mod.exports.mountSpecies = function() return flight.species end
mod.exports.eligibleMounts = function()
  local out = {}
  for species, cfg in pairs(ELIGIBLE) do
    out[#out + 1] = { species = species, dex = cfg.dex }
  end
  table.sort(out, function(a, b) return a.dex < b.dex end)
  return out
end
mod.exports.riderVisible = function()
  return flight.active and flight.riderEntity ~= nil and showRiderEnabled()
end
mod.exports.firstPersonFlying = function()
  return flight.active and isFirstPerson()
end
mod.exports.currentAltitude = function() return flight.altitude end
mod.exports.requestedAltitude = function() return flight.requestedAltitude end
mod.exports.boostAmount = function() return flight.boost or 0 end
mod.exports.cameraFollowEnabled = cameraFollowEnabled
mod.exports.landingValid = function()
  local ow = Game.overworld
  return ow and landingCellValid(ow, ow.player.cellX, ow.player.cellY) or false
end
mod.exports.requestLanding = function()
  return beginLanding(Game, false)
end

