  restoreTarget(G, target)
  if not (canvas and Voxel3D) then return false end

  local pushed = false
  local ok, err = pcall(function()
    G.push("all")
    pushed = true
    G.origin()
    G.setColor(0.04, 0.07, 0.10, 1)
    G.rectangle("fill", 0, 0, winW, winH)

    -- The 3D pass is now rendered at the actual presentation resolution
    -- (capped at 1080p), instead of 160x144 and magnified afterwards.
    local sx, sy = winW / renderW, winH / renderH
    G.setColor(1, 1, 1, 1)
    G.push()
    G.scale(sx, sy)
    G.draw(canvas, 0, 0)
    local pixelScale = renderH / SCREEN_H
    drawLandingBeacons(G, state, Voxel3D, pixelScale)
    drawMountOverlay(G, state, Voxel3D, pixelScale)
    drawMinimalHud(G, state, renderW, renderH, pixelScale)
    G.pop()
  end)
  if pushed then pcall(G.pop) end
  restoreTarget(G, target)

  if not ok then
    disableThreeD("COMPOSE", err)
    return false
  end
  return true
end

local function patchState(state)
  if type(state) ~= "table" or patched[state] then return end
  if state._dsrOpenSky2DWidescreen ~= true or type(state.drawWidescreen) ~= "function" then return end
  patched[state] = true

  local fallback = state.drawWidescreen
  state.drawWidescreen = function(self, winW, winH)
    if draw3dWidescreen(self, winW, winH) then return end
    pcall(fallback, self, winW, winH)
  end
  state._dsrOpenSkyGen2ThreeD = true
  state._dsrOpenSkyUsesSuppliedGLB = true
end

local function patchCurrentState()
  if type(playable.state) ~= "function" then return end
  local ok, state = pcall(playable.state)
  if ok and state then patchState(state) end
end

local previousOpenSky3DUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousOpenSky3DUpdate(self, dt, ...)
  patchCurrentState()
  return result
end

mod.events:on("game.ready", resetCache)

playable.gen2ThreeD = {
  providerId = PROVIDER_ID,
  sourceModel = "Meshy_AI_map_monde_de_la_regio_0812201706_texture.glb",
  sourceSha256 = "5b772bd2d6af23bdea8459680fc7e6dcb2a23be6753882d891f10f278a89736a",
  baked = true,
  detected = function() return provider() ~= nil end,
  ready = function() return ensureRenderer() ~= nil end,
  disabled = function() return cache.disabled == true end,
  stage = function() return cache.stage end,
  error = function() return cache.error end,
  projectWorld = worldPoint,
  sampleHeight = heightAt,
  worldSize = function() return WORLD_X1 - WORLD_X0, WORLD_Z1 - WORLD_Z0 end,
  cruiseFlightY = function() return CRUISE_FLIGHT_Y end,
  nativeResolution = true,
  maxRenderSize = { MAX_RENDER_W, MAX_RENDER_H },
}

log("Gen2 Open Sky GLB regional terrain loaded (world=%dx%d relief=%d cruiseY=%d HD<=%dx%d provider=%s)",
  WORLD_X1 - WORLD_X0, WORLD_Z1 - WORLD_Z0, WORLD_RELIEF, CRUISE_FLIGHT_Y,
  MAX_RENDER_W, MAX_RENDER_H, PROVIDER_ID)
end)();
