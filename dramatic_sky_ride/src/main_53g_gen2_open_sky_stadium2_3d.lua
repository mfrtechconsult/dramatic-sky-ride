;(function()
-- -------------------------------------------------------------------------
-- Gen2 Open Sky 3D overlay for randyadr/Gen2-3D-Sprites.
--
-- The proven 2D widescreen page always draws first. The 3D pass renders into
-- its own Voxel3D canvas, then explicitly restores Gold's presentation target
-- before compositing. This matters because Voxel3D.endScene() deliberately
-- unbinds its canvas; without restoring the caller target the 3D image can be
-- drawn to the window while Game2 later presents its still-2D frame over it.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local HEIGHT_ASSET = "assets/open_sky_region_height.png"
local SCREEN_W, SCREEN_H = 160, 144
local MAP_TOP, MAP_BOTTOM = 18, 124
local MAP_H = MAP_BOTTOM - MAP_TOP
local SX0, SX1, SY0, SY1 = 6, 154, 22, 138
local MX0, MX1, MZ0, MZ1 = 8, 152, 24, 112
local RECT = {
  johto = { 6, 85, 27, 104 },
  kanto = { 90, 154, 25, 104 },
}

local patched = setmetatable({}, { __mode = "k" })
local cache = {}

local function resetCache()
  cache = {
    provider = nil,
    Voxel3D = nil,
    mesh = nil,
    texture = nil,
    heights = nil,
    w = 0,
    h = 0,
    ready = false,
    flatFallback = false,
    disabled = false,
    stage = "INIT",
    error = nil,
  }
end
resetCache()

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function setStage(stage, err)
  cache.stage = tostring(stage or "?")
  cache.error = err and tostring(err) or nil
end

local function disableThreeD(stage, err)
  cache.disabled = true
  cache.ready = false
  setStage(stage or "ERR", err or "unknown Open Sky 3D error")
  pcall(function()
    log("Open Sky 3D disabled for session [%s]: %s", cache.stage, cache.error)
  end)
end

local function provider()
  if cache.provider and type(cache.provider.lib) == "table"
      and type(cache.provider.lib.require) == "function" then
    return cache.provider
  end

  -- Do NOT gate on exports.active, rendererInstalled, voxelStatus().active or
  -- voxelComposeHook. Open Sky is an opaque state, so Randy's normal overworld
  -- compose frame is expected to be inactive while this screen owns the frame.
  -- The only capability required here is the provider's public renderer loader.
  if type(mod.find) ~= "function" then
    setStage("NOAPI", "mod.find unavailable")
    return nil
  end

  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then
    ok, handle = pcall(function() return mod.find(PROVIDER_ID) end)
  end
  if not ok or not handle then
    setStage("NOMOD", "Gen2-3D-Sprites not found")
    return nil
  end

  local ex = handle.exports
  if type(ex) ~= "table" then
    setStage("NOEXP", "provider exports unavailable")
    return nil
  end
  if type(ex.lib) ~= "table" or type(ex.lib.require) ~= "function" then
    setStage("NOLIB", "provider lib.require unavailable")
    return nil
  end

  cache.provider = ex
  setStage("PROVIDER")
  return ex
end

local function readHeight()
  if not (mod.read and love and love.image and love.image.newImageData
      and love.filesystem and love.filesystem.newFileData) then
    return nil, "height decoder unavailable"
  end
  local okRead, raw = pcall(mod.read, mod, HEIGHT_ASSET)
  if not okRead or type(raw) ~= "string" or raw == "" then
    return nil, "height map unavailable"
  end
  local okData, data = pcall(love.filesystem.newFileData,
    raw, "open_sky_region_height.png")
  if not okData or not data then return nil, "height FileData failed" end
  local okImage, image = pcall(love.image.newImageData, data)
  if not okImage or not image then return nil, "height ImageData failed" end
  return image
end

local function buildFlatTerrain(Voxel3D)
  local verts = {
    { MX0, 0, MZ0, 0, 0, 1 },
    { MX1, 0, MZ0, 1, 0, 1 },
    { MX0, 0, MZ1, 0, 1, 1 },
    { MX1, 0, MZ1, 1, 1, 1 },
  }
  local mesh = Voxel3D.newMesh(verts, { 1, 3, 2, 2, 3, 4 })
  if not mesh then return nil, "flat mesh failed" end
  return { mesh = mesh, w = 2, h = 2, heights = { 0, 0, 0, 0 }, flat = true }
end

local function buildTerrain(Voxel3D)
  local image = readHeight()
  if not image then return buildFlatTerrain(Voxel3D) end

  local w, h = image:getDimensions()
  if w < 2 or h < 2 then return buildFlatTerrain(Voxel3D) end
  local verts, indices, heights = {}, {}, {}

  for z = 0, h - 1 do
    local tz = z / (h - 1)
    for x = 0, w - 1 do
      local tx = x / (w - 1)
      local r = image:getPixel(x, z)
      local i = z * w + x + 1
      local y = clamp(r, 0, 1) * 24
      verts[i] = {
        MX0 + (MX1 - MX0) * tx,
        y,
        MZ0 + (MZ1 - MZ0) * tz,
        tx, tz, 1,
      }
      heights[i] = y
    end
  end

  for z = 0, h - 2 do
    for x = 0, w - 2 do
      local a = z * w + x + 1
      local b, c, d = a + 1, a + w, a + w + 1
      indices[#indices + 1] = a
      indices[#indices + 1] = c
      indices[#indices + 1] = b
      indices[#indices + 1] = b
      indices[#indices + 1] = c
      indices[#indices + 1] = d
    end
  end

  local mesh = Voxel3D.newMesh(verts, indices)
  if not mesh then return buildFlatTerrain(Voxel3D) end
  return { mesh = mesh, w = w, h = h, heights = heights, flat = false }
end

local function ensureRenderer()
  if cache.disabled then return nil end
  if cache.ready then return cache end

  local ex = provider()
  if not ex then return nil end

  local okVoxel, Voxel3D = pcall(ex.lib.require, "Voxel3D")
  if not okVoxel or type(Voxel3D) ~= "table" then
    disableThreeD("NOVOX", "Voxel3D export unavailable")
    return nil
  end
  if type(Voxel3D.available) == "function" then
    local okAvailable, available = pcall(Voxel3D.available)
    if not okAvailable or available ~= true then
      disableThreeD("GPU", "Voxel3D.available() is false")
      return nil
    end
  end

  local built, buildErr = buildTerrain(Voxel3D)
  if not built then
    disableThreeD("MESH", buildErr or "terrain build failed")
    return nil
  end

  local texture = nil
  if type(playable.openSkyMapImage) == "function" then
    local okTexture, image = pcall(playable.openSkyMapImage)
    if okTexture then texture = image end
  end
  if not texture then
    disableThreeD("TEX", "Open Sky map texture unavailable")
    return nil
  end

  cache.Voxel3D = Voxel3D
  cache.mesh = built.mesh
  cache.w, cache.h = built.w, built.h
  cache.heights = built.heights
  cache.flatFallback = built.flat == true
  cache.texture = texture
  cache.ready = true
  setStage(cache.flatFallback and "FLAT" or "READY")
  return cache
end

local function worldPoint(region, x, y)
  local r = RECT[region] or RECT.johto
  local nx = (clamp(x, SX0, SX1) - SX0) / (SX1 - SX0)
  local ny = (clamp(y, SY0, SY1) - SY0) / (SY1 - SY0)
  return r[1] + nx * (r[2] - r[1]),
    r[3] + ny * (r[4] - r[3])
end

local function heightAt(wx, wz)
  if not (cache.ready and cache.heights and cache.w > 0 and cache.h > 0) then
    return 0
  end
  local gx = clamp((wx - MX0) / (MX1 - MX0) * (cache.w - 1), 0, cache.w - 1)
  local gz = clamp((wz - MZ0) / (MZ1 - MZ0) * (cache.h - 1), 0, cache.h - 1)
  local x0, z0 = math.floor(gx), math.floor(gz)
  local x1, z1 = math.min(cache.w - 1, x0 + 1), math.min(cache.h - 1, z0 + 1)
  local tx, tz = gx - x0, gz - z0
  local function at(x, z) return cache.heights[z * cache.w + x + 1] or 0 end
  local a = at(x0, z0) * (1 - tx) + at(x1, z0) * tx
  local b = at(x0, z1) * (1 - tx) + at(x1, z1) * tx
  return a * (1 - tz) + b * tz
end

local function visitedPoints(region)
  if type(playable.visitedPoints) ~= "function" then return {} end
  local ok, rows = pcall(playable.visitedPoints, region)
  return ok and type(rows) == "table" and rows or {}
end

local function fitScale(winW, winH)
  local raw = math.min((tonumber(winW) or SCREEN_W) / SCREEN_W,
    (tonumber(winH) or SCREEN_H) / SCREEN_H)
  if raw >= 1 then return math.max(1, math.floor(raw)) end
  return math.max(0.01, raw)
end

local function drawMount(G, state, x, y, scale)
  local sprite = flight.sprite
  local drawn = false
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(x), math.floor(y))
    G.scale(0.34 * clamp(scale or 1, 0.7, 1.4))
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    drawn = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    G.pop()
  end
  if not drawn then
    G.setColor(1, 1, 1, 1)
    G.circle("fill", x, y, 3)
  end
end

local function drawProjectedOverlays(G, state, Voxel3D)
  local nearestSpawn = state.nearest and state.nearest.row
    and state.nearest.row.spawn or nil
  for _, point in ipairs(visitedPoints(state.region)) do
    if point.anchor then
      local wx, wz = worldPoint(state.region, point.anchor.x, point.anchor.y)
      local x, y = Voxel3D.project(wx, heightAt(wx, wz) + 1.2, wz)
      if x and y then
        local selected = nearestSpawn ~= nil and point.row
          and point.row.spawn == nearestSpawn
        G.setColor(1, 1, 1, 0.94)
        G.circle("fill", x, y + MAP_TOP, selected and 2 or 1.25)
        if selected then G.circle("line", x, y + MAP_TOP, 4.5) end
      end
    end
  end

  local wx, wz = worldPoint(state.region, state.x, state.y)
  local x, y, scale = Voxel3D.project(wx, heightAt(wx, wz) + 8, wz)
  if x and y then drawMount(G, state, x, y + MAP_TOP, scale) end
end

local function renderTerrainCanvas()
  local r = ensureRenderer()
  if not r then return nil end
  local Voxel3D = r.Voxel3D
  local oldCamera, oldTint = Voxel3D.camera, Voxel3D.tint
  local canvas, begun = nil, false

  local ok, err = pcall(function()
    Voxel3D.camera = {
      eye = { 80, 98, 168 },
      focus = { 80, 4, 68 },
      fov = math.rad(40),
      curve = 0,
      up = { 0, 1, 0 },
    }
    Voxel3D.tint = { 1, 1, 1 }
    begun = Voxel3D.beginScene(SCREEN_W, MAP_H, 80, 68,
      SCREEN_W, MAP_H, { 0.58, 0.80, 0.96, 1 }, "dsr_open_sky_region")
    if not begun then error("Voxel3D.beginScene failed") end
    Voxel3D.seams(false)
    Voxel3D.glass(false)
    Voxel3D.draw(r.mesh, r.texture, nil, 0)
    canvas = Voxel3D.endScene()
    begun = false
    if not canvas then error("Voxel3D.endScene returned no canvas") end
  end)

  if begun then pcall(Voxel3D.endScene) end
  Voxel3D.camera, Voxel3D.tint = oldCamera, oldTint
  if not ok then
    disableThreeD("SCENE", err)
    return nil
  end
  return canvas, Voxel3D
end

local function restoreTarget(G, target)
  if target then
    local ok = pcall(G.setCanvas, target)
    if ok then return end
  end
  pcall(G.setCanvas)
end

local function drawStatus(G, winW, winH)
  if type(G.print) ~= "function" then return end
  local scale = fitScale(winW, winH)
  local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
  local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
  G.origin()
  G.translate(ox, oy)
  G.scale(scale, scale)
  G.setColor(1, 1, 1, 1)
  pcall(G.print, "3D:" .. tostring(cache.stage or "?"), 112, 4)
end

local function draw3dWidescreen(state, winW, winH)
  if not (love and love.graphics) then return false end
  local G = love.graphics
  winW = tonumber(winW) or select(1, G.getDimensions()) or SCREEN_W
  winH = tonumber(winH) or select(2, G.getDimensions()) or SCREEN_H

  -- Game2 may already be drawing into a presentation target. Voxel3D owns an
  -- off-screen canvas and endScene() unbinds it, so remember the caller target
  -- and restore it BEFORE drawing the 3D result or diagnostics.
  local target = nil
  if type(G.getCanvas) == "function" then
    local okTarget, current = pcall(G.getCanvas)
    if okTarget then target = current end
  end

  local canvas, Voxel3D = renderTerrainCanvas()
  restoreTarget(G, target)

  local pushed = false
  local ok, err = pcall(function()
    G.push("all")
    pushed = true
    if canvas and Voxel3D then
      G.origin()
      local scale = fitScale(winW, winH)
      local ox = math.floor((winW - SCREEN_W * scale) * 0.5)
      local oy = math.floor((winH - SCREEN_H * scale) * 0.5)
      G.translate(ox, oy)
      G.scale(scale, scale)
      G.setColor(1, 1, 1, 1)
      G.draw(canvas, 0, MAP_TOP)
      drawProjectedOverlays(G, state, Voxel3D)
      G.setColor(1, 1, 1, 1)
      pcall(G.print, cache.flatFallback and "3D:FLAT" or "3D:LIVE", 108, 4)
    else
      drawStatus(G, winW, winH)
    end
  end)
  if pushed then pcall(G.pop) end
  restoreTarget(G, target)

  if not ok then
    disableThreeD("COMPOSE", err)
    return false
  end
  return canvas ~= nil
end

local function patchState(state)
  if type(state) ~= "table" or patched[state] then return end
  if state._dsrOpenSky2DWidescreen ~= true then return end
  if type(state.drawWidescreen) ~= "function" then return end
  patched[state] = true

  local fallback = state.drawWidescreen
  state.drawWidescreen = function(self, winW, winH)
    local fallbackOk, fallbackErr = pcall(fallback, self, winW, winH)
    if not fallbackOk then
      setStage("2DERR", fallbackErr)
      return
    end
    draw3dWidescreen(self, winW, winH)
  end
  state._dsrOpenSkyGen2ThreeD = true
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

mod.events:on("game.ready", function()
  resetCache()
end)

playable.gen2ThreeD = {
  providerId = PROVIDER_ID,
  detected = function() return provider() ~= nil end,
  ready = function() return ensureRenderer() ~= nil end,
  disabled = function() return cache.disabled == true end,
  stage = function() return cache.stage end,
  error = function() return cache.error end,
  projectWorld = worldPoint,
  sampleHeight = heightAt,
}

log("Gen2 Open Sky 3D overlay loaded with target restore (provider=%s)", PROVIDER_ID)
end)();