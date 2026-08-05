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

mod.events:on("battle.started", function()
  if flight.active then forceImmediateLand(Game) end
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

