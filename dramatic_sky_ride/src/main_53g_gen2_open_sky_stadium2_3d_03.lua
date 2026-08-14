    pcall(sprite.draw, sprite, -8, -8, 0, 0, state.facing or "right", phase, false)
    G.pop()
  else
    G.setColor(1, 1, 1, 0.9)
    G.circle("fill", x, y, 2 * math.max(1, tonumber(pixelScale) or 1))
  end
end

local function drawLandingBeacons(G, state, Voxel3D, pixelScale)
  local nearestSpawn = state.nearest and state.nearest.row and state.nearest.row.spawn or nil
  for _, point in ipairs(visitedPoints(state.region)) do
    local a = point.anchor
    if a then
      local wx, wz = worldPoint(state.region, a.x, a.y)
      local x, y = Voxel3D.project(wx, heightAt(wx, wz) + 2.5, wz)
      if x and y then
        local selected = nearestSpawn ~= nil and point.row and point.row.spawn == nearestSpawn
        G.setColor(1, 1, 1, selected and 0.95 or 0.72)
        local ps = math.max(1, tonumber(pixelScale) or 1)
        G.circle("fill", x, y, (selected and 1.7 or 1.0) * ps)
        if selected then G.circle("line", x, y, 4.5 * ps) end
      end
    end
  end
end

local function renderScene(state, renderW, renderH)
  local r = ensureRenderer()
  if not r then return nil end
  local Voxel3D = r.Voxel3D
  local oldCamera, oldTint = Voxel3D.camera, Voxel3D.tint
  local canvas, begun = nil, false

  local ok, err = pcall(function()
    local wx, wy, wz = mountWorldPose(state)
    local heading = headingForState(state)
    local fx, fz = math.cos(heading), math.sin(heading)
    local speed = clamp(tonumber(state.speed) or 0, 0, 20)
    local bank = clamp(tonumber(state.bank) or 0, -20, 20)
    local pitch = clamp(tonumber(state.pitch) or 0, -14, 14)
    local boost = clamp(tonumber(state.boost) or 0, 0, 1)

    -- Stable high-altitude chase camera. Its Y coordinates are tied only to
    -- the rider's absolute flight level; terrain height never changes the rig.
    -- A very small roll remains for steering feedback, but there is no terrain
    -- induced pitch/height turbulence.
    local cameraDistance = 128 + speed * 1.2
    local cameraHeight = 44 + boost * 2
    local lookAhead = 112 + speed * 1.8
    local rightX, rightZ = -fz, fx
    local roll = math.tan(math.rad(bank * 0.07))
    local pitchLift = math.sin(math.rad(pitch)) * 16

    Voxel3D.camera = {
      eye = { wx - fx * cameraDistance, wy + cameraHeight, wz - fz * cameraDistance },
      focus = { wx + fx * lookAhead, wy - 72 + pitchLift, wz + fz * lookAhead },
      fov = math.rad(46 + boost * 1.5),
      curve = 0,
      up = { rightX * roll, 1, rightZ * roll },
    }
    Voxel3D.tint = { 1, 1, 1 }

    renderW = math.max(320, math.floor(tonumber(renderW) or SCREEN_W))
    renderH = math.max(288, math.floor(tonumber(renderH) or SCREEN_H))
    begun = Voxel3D.beginScene(renderW, renderH, wx, wz,
      renderW, renderH, { 0.36, 0.62, 0.78, 1 }, "dsr_open_sky_glb_region_hd")
    if not begun then error("Voxel3D.beginScene failed") end
    if Voxel3D.seams then Voxel3D.seams(false) end
    if Voxel3D.glass then Voxel3D.glass(false) end
    Voxel3D.draw(r.mesh, r.texture, nil, 0)
    canvas = Voxel3D.endScene()
    begun = false
    if not canvas then error("Voxel3D.endScene returned no canvas") end
    -- Native-size draw is normally 1:1; linear is only used if the resolution
    -- cap forces a small final resize on unusually large windows.
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "linear", "linear") end
  end)

  if begun then pcall(Voxel3D.endScene) end
  Voxel3D.camera, Voxel3D.tint = oldCamera, oldTint
  if not ok then
    disableThreeD("SCENE", err)
    return nil
  end
  return canvas, Voxel3D
end

local function sceneResolution(winW, winH)
  local w = math.max(320, math.floor(tonumber(winW) or SCREEN_W))
  local h = math.max(288, math.floor(tonumber(winH) or SCREEN_H))
  local scale = math.min(1, MAX_RENDER_W / w, MAX_RENDER_H / h)
  if scale < 1 then
    w = math.max(320, math.floor(w * scale + 0.5))
    h = math.max(288, math.floor(h * scale + 0.5))
  end
  return w, h
end

local function restoreTarget(G, target)
  if target and pcall(G.setCanvas, target) then return end
  pcall(G.setCanvas)
end

local function drawMinimalHud(G, state, sceneW, sceneH, pixelScale)
  if type(G.print) ~= "function" then return end
  local ready = (tonumber(state.nearestDistance) or math.huge) <= 11
  local ui = math.max(1, math.min(3, tonumber(pixelScale) or 1))
  G.push()
  G.scale(ui, ui)
  local w, h = sceneW / ui, sceneH / ui
  G.setColor(0, 0, 0, 0.42)
  G.rectangle("fill", 4, 4, 60, 13)
  G.setColor(1, 1, 1, 0.94)
  pcall(G.print, string.format("SPD %.1f", tonumber(state.speed) or 0), 7, 6)
  if state.notice then
    G.setColor(0, 0, 0, 0.48)
    G.rectangle("fill", 4, h - 18, math.min(w - 8, 180), 14)
    G.setColor(1, 1, 1, 0.95)
    pcall(G.print, tostring(state.notice):sub(1, 30), 7, h - 16)
  elseif ready then
    G.setColor(0, 0, 0, 0.48)
    G.rectangle("fill", 4, h - 18, 72, 14)
    G.setColor(1, 1, 1, 0.95)
    pcall(G.print, "A LAND", 7, h - 16)
  end
  G.pop()
end

local function draw3dWidescreen(state, winW, winH)
  if not (love and love.graphics) then return false end
  local G = love.graphics
  winW = tonumber(winW) or select(1, G.getDimensions()) or SCREEN_W
  winH = tonumber(winH) or select(2, G.getDimensions()) or SCREEN_H

  local target = nil
  if type(G.getCanvas) == "function" then
    local okTarget, current = pcall(G.getCanvas)
    if okTarget then target = current end
  end

  local renderW, renderH = sceneResolution(winW, winH)
  local canvas, Voxel3D = renderScene(state, renderW, renderH)
