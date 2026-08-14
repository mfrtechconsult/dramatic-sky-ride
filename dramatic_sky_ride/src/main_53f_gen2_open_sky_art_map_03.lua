  state.drawsWidescreen = function() return true end
  state.drawWidescreen = function(self, winW, winH)
    drawWidescreen(self, winW, winH)
  end
  state._dsrOpenSkyIllustratedMap = true
  state._dsrOpenSky2DWidescreen = true
end

local function patchCurrentState()
  if type(playable.state) ~= "function" then return end
  local ok, state = pcall(playable.state)
  if ok and state then patchState(state) end
end

local previousIllustratedOpenSkyUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousIllustratedOpenSkyUpdate(self, dt, ...)
  patchCurrentState()
  return result
end

mod.events:on("game.ready", function()
  mapImage = nil
  mapImageTried = false
  lastIllustratedDrawError = nil
end)

-- Open Sky 3D is intentionally disabled while the 2D path is being stabilized.
-- Keep a diagnostic export so stale tools do not mistake absence for detection.
playable.gen2ThreeD = {
  disabled = true,
  detected = function() return false end,
  ready = function() return false end,
  error = function() return "Open Sky 3D temporarily disabled" end,
}

playable.illustratedMap = function() return true end
playable.mapAsset = function() return MAP_ASSET end
playable.openSkyMapImage = loadMapImage
playable.projectMapPoint = project
playable.drawIllustratedMap = drawPanel
playable.drawOpenSkyWidescreen = drawWidescreen
playable.lastIllustratedDrawError = function() return lastIllustratedDrawError end

log("Gen2 Open Sky 2D widescreen renderer loaded (3D temporarily disabled)")
end)();
