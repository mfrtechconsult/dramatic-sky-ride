local handleInput = OverworldState.handleInput
function OverworldState:handleInput(...)
  local args = { ... }
  if not (flight.active and Game.overworld == self) then
    return handleInput(self, unpackArgs(args))
  end

  local input = Game.input
  if flight.phase == "takeoff" or flight.phase == "landing" then return end
  if input and input:wasPressed("a") then
    beginLanding(Game, false)
    return
  end

  return runAsOpenAir(self, function()
    return handleInput(self, unpackArgs(args))
  end)
end

local update = OverworldState.update
function OverworldState:update(dt, ...)
  if flight.active and Game.overworld == self then
    if not isSupportedVoxelMode() then
      -- Switching among every voxel camera, including 1ST and 3RD, is allowed.
      -- Only VOXEL OFF has no 3D height representation and forces a safe land.
      if not forceImmediateLand(Game) then clearFlight(self) end
    end

    local frameDt = tonumber(dt) or (1 / 60)
    updateBoost(frameDt)
    flight.hudTimer = math.max(0, (flight.hudTimer or 0) - frameDt)
    flight.noticeTimer = math.max(0, (flight.noticeTimer or 0) - frameDt)
    if flight.noticeTimer <= 0 then flight.notice = nil end

