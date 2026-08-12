;(function()
-- -------------------------------------------------------------------------
-- Gen 2 Open Sky 3D regional-map bridge.
--
-- This path intentionally detects the Gen-2 renderer by its real mod id:
--   randyadr/Gen2-3D-Sprites -> STADIUM2_OVERWORLD_MODELS
-- It does NOT use DRAMALESS_SHAPE as the Gen-2 host.
--
-- The user-supplied Meshy GLB is preprocessed offline into a compact 128x99
-- height map. At runtime we rebuild a small mesh from that image and reuse
-- Gen2-3D-Sprites' public `exports.lib`
-- Voxel3D/Mat4 surface, so the 3D map uses the same depth/camera renderer as
-- the installed Gen-2 voxel mod without patching that mod or the engine.
-- -------------------------------------------------------------------------
local playable = mod.exports.openSkyPlayable or {}
local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local HEIGHT_ASSET = "assets/open_sky_region_height.png"
local TEXTURE_ASSET = "assets/open_sky_region_map.jpg"

local SOURCE_X0, SOURCE_X1 = 6, 154
local SOURCE_Y0, SOURCE_Y1 = 22, 138
local MAP_X0, MAP_X1 = 8, 152
local MAP_Z0, MAP_Z1 = 24, 112
local REGION_WORLD_RECT = {
  johto = { x0 = 6,  x1 = 85,  z0 = 27, z1 = 104 },
  kanto = { x0 = 90, x1 = 154, z0 = 25, z1 = 104 },
}
local CAMERA_EYE = { 80, 126, 178 }
local CAMERA_FOCUS = { 80, 4, 68 }
local CAMERA_FOV = math.rad(37)
local MOUNT_CLEARANCE = 9

local providerCache = nil
local resources = {
  tried = false,
  ready = false,
  error = nil,
  Voxel3D = nil,
  Mat4 = nil,
  mesh = nil,
  texture = nil,
  gridW = 0,
  gridH = 0,
  heights = nil,
}
local patchedStates = setmetatable({}, { __mode = "k" })

local function clamp3(v, lo, hi)
  return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function cleanName(value)
  return tostring(value or ""):gsub("\n", " ")
    :gsub("^LANDMARK_", ""):gsub("_", " ")
end

local function providerExports()
  if providerCache ~= nil then return providerCache or nil end
  providerCache = false
  if not (mod and type(mod.find) == "function") then return nil end

  local handle = nil
  local ok, result = pcall(function() return mod.find(PROVIDER_ID) end)
  if ok then handle = result end
  if not handle then
    ok, result = pcall(mod.find, mod, PROVIDER_ID)
    if ok then handle = result end
  end
  local exports = handle and handle.exports
  if type(exports) ~= "table" then return nil end
  if exports.active == false or exports.rendererInstalled == false then return nil end
  if type(exports.lib) ~= "table" or type(exports.lib.require) ~= "function" then
    return nil
  end
  providerCache = exports
  return exports
end

local function loadTexture()
  if not (love and love.graphics) then return nil end
  local direct = mod.path and (tostring(mod.path) .. "/" .. TEXTURE_ASSET) or nil
  if direct then
    local ok, image = pcall(love.graphics.newImage, direct)
    if ok and image then
      pcall(image.setFilter, image, "linear", "linear")
      return image
    end
  end
  if not (mod.read and love.filesystem and love.filesystem.newFileData) then return nil end
  local okRead, raw = pcall(mod.read, mod, TEXTURE_ASSET)
  if not okRead or type(raw) ~= "string" then return nil end
  local okData, data = pcall(love.filesystem.newFileData, raw, "open_sky_region_map.jpg")
  if not okData or not data then return nil end
  local okImage, image = pcall(love.graphics.newImage, data)
  if not okImage or not image then return nil end
  pcall(image.setFilter, image, "linear", "linear")
  return image
end

local function loadHeightImageData()
  if not (mod.read and love and love.image and love.image.newImageData
      and love.filesystem and love.filesystem.newFileData) then
    return nil, "LÖVE image/file APIs unavailable"
  end
  local okRead, raw = pcall(mod.read, mod, HEIGHT_ASSET)
  if not okRead or type(raw) ~= "string" or raw == "" then
    return nil, "Open Sky 3D height map asset missing"
  end
  local okData, fileData = pcall(love.filesystem.newFileData,
    raw, "open_sky_region_height.png")
  if not okData or not fileData then
    return nil, "Open Sky 3D height map FileData failed"
  end
  local okImage, imageData = pcall(love.image.newImageData, fileData)
  if not okImage or not imageData then
    return nil, "Open Sky 3D height map decode failed"
  end
  return imageData
end

local function loadHeightfield(Voxel3D)
  local imageData, imageErr = loadHeightImageData()
  if not imageData then return nil, imageErr end
  local gridW, gridH = imageData:getDimensions()
  if gridW < 2 or gridH < 2 then return nil, "Open Sky 3D height map is too small" end

  local vertices, indices, heights = {}, {}, {}
  for iz = 0, gridH - 1 do
    local tz = iz / (gridH - 1)
    local wz = MAP_Z0 + (MAP_Z1 - MAP_Z0) * tz
    for ix = 0, gridW - 1 do
      local tx = ix / (gridW - 1)
      local wx = MAP_X0 + (MAP_X1 - MAP_X0) * tx
      local r = imageData:getPixel(ix, iz)
      local wy = clamp3(r, 0, 1) * 24
      local index = iz * gridW + ix + 1
      vertices[index] = { wx, wy, wz, tx, tz, 1.0 }
      heights[index] = wy
    end
  end

  for iz = 0, gridH - 2 do
    for ix = 0, gridW - 2 do
      local a = iz * gridW + ix + 1
      local b, c, d = a + 1, a + gridW, a + gridW + 1
      indices[#indices + 1] = a
      indices[#indices + 1] = c
      indices[#indices + 1] = b
      indices[#indices + 1] = b
      indices[#indices + 1] = c
      indices[#indices + 1] = d
    end
  end

  local mesh = Voxel3D.newMesh(vertices, indices)
  if not mesh then return nil, "Gen2-3D-Sprites could not create Open Sky mesh" end
  return mesh, nil, gridW, gridH, heights
end

local function ensureResources()
  if resources.tried then return resources.ready, resources.error end
  resources.tried = true

  local exports = providerExports()
  if not exports then
    resources.error = "STADIUM2_OVERWORLD_MODELS is not active/ready"
    return false, resources.error
  end
  local ok3D, Voxel3D = pcall(exports.lib.require, "Voxel3D")
  local okMat, Mat4 = pcall(exports.lib.require, "Mat4")
  if not (ok3D and type(Voxel3D) == "table" and okMat and type(Mat4) == "table") then
    resources.error = "Gen2-3D-Sprites Voxel3D/Mat4 API unavailable"
    return false, resources.error
  end
  if type(Voxel3D.available) == "function" then
    local okAvailable, available = pcall(Voxel3D.available)
    if not okAvailable or not available then
      resources.error = "Gen2-3D-Sprites 3D renderer unavailable on this GPU"
      return false, resources.error
    end
  end

  local texture = loadTexture()
  if not texture then
    resources.error = "Open Sky 3D texture failed to load"
    return false, resources.error
  end
  local mesh, meshErr, gridW, gridH, heights = loadHeightfield(Voxel3D)
  if not mesh then
    resources.error = meshErr
    return false, resources.error
  end

  resources.Voxel3D = Voxel3D
  resources.Mat4 = Mat4
  resources.mesh = mesh
  resources.texture = texture
  resources.gridW = gridW
  resources.gridH = gridH
  resources.heights = heights
  resources.ready = true
  resources.error = nil
  return true
end

local function projectWorld(region, x, y)
  local rect = REGION_WORLD_RECT[region] or REGION_WORLD_RECT.johto
  local nx = (clamp3(x, SOURCE_X0, SOURCE_X1) - SOURCE_X0) / (SOURCE_X1 - SOURCE_X0)
  local ny = (clamp3(y, SOURCE_Y0, SOURCE_Y1) - SOURCE_Y0) / (SOURCE_Y1 - SOURCE_Y0)
  return rect.x0 + nx * (rect.x1 - rect.x0),
    rect.z0 + ny * (rect.z1 - rect.z0)
end

local function sampleHeight(wx, wz)
  local w, h = resources.gridW, resources.gridH
  local heights = resources.heights
  if not (heights and w > 1 and h > 1) then return 0 end
  local gx = clamp3((wx - MAP_X0) / (MAP_X1 - MAP_X0) * (w - 1), 0, w - 1)
  local gz = clamp3((wz - MAP_Z0) / (MAP_Z1 - MAP_Z0) * (h - 1), 0, h - 1)
  local x0, z0 = math.floor(gx), math.floor(gz)
  local x1, z1 = math.min(w - 1, x0 + 1), math.min(h - 1, z0 + 1)
  local tx, tz = gx - x0, gz - z0
  local function at(ix, iz) return heights[iz * w + ix + 1] or 0 end
  local a = at(x0, z0) * (1 - tx) + at(x1, z0) * tx
  local b = at(x0, z1) * (1 - tx) + at(x1, z1) * tx
  return a * (1 - tz) + b * tz
end

local function visitedPoints(region)
  if type(playable.visitedPoints) ~= "function" then return {} end
  local ok, rows = pcall(playable.visitedPoints, region)
  return ok and type(rows) == "table" and rows or {}
end

local function drawHud(G, state)
  G.setColor(0, 0, 0, 0.72)
  G.rectangle("fill", 0, 0, 160, 18)
  G.rectangle("fill", 0, 124, 160, 20)
  G.setColor(1, 1, 1, 1)
  if type(G.print) ~= "function" then return end
  local region = state.region == "kanto" and "KANTO" or "JOHTO"
  local altitude = math.floor((tonumber(state.virtualAltitude) or 88) + 0.5)
  G.print("OPEN SKY 3D - " .. region .. "  ALT " .. tostring(altitude), 4, 4)
  local bottom = state.notice
  if not bottom then
    local name = state.nearest and state.nearest.row
      and (state.nearest.row.name or state.nearest.row.landmark)
    bottom = name and ("A DESCEND - " .. cleanName(name))
      or "NO VISITED LANDING POINT"
  end
  if #bottom > 28 then bottom = bottom:sub(1, 28) end
  G.print(bottom, 4, 128)
end

local function drawMountSprite(G, state, sx, sy, scale)
  local sprite = flight.sprite
  local drawn = false
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(sx), math.floor(sy))
    local s = 0.34 * clamp3(scale or 1, 0.7, 1.4)
    G.scale(s, s)
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
    drawn = pcall(sprite.draw, sprite, -8, -8, 0, 0,
      state.facing or "right", phase, false)
    G.pop()
  end
  if not drawn then
    G.setColor(1, 1, 1, 1)
    G.polygon("fill", sx, sy - 4, sx + 4, sy + 4,
      sx, sy + 2, sx - 4, sy + 4)
  end
  G.setColor(1, 1, 1, 0.95)
  G.circle("line", sx, sy, 5)
end

local function drawWorldOverlays(G, state, Voxel3D)
  local nearestSpawn = state.nearest and state.nearest.row
    and state.nearest.row.spawn or nil
  for _, point in ipairs(visitedPoints(state.region)) do
    local anchor = point and point.anchor
    if anchor then
      local wx, wz = projectWorld(state.region, anchor.x, anchor.y)
      local wy = sampleHeight(wx, wz) + 1.2
      local sx, sy = Voxel3D.project(wx, wy, wz)
      if sx and sy then
        local selected = nearestSpawn ~= nil and point.row
          and point.row.spawn == nearestSpawn
        if selected then
          G.setColor(1, 1, 1, 0.95)
          G.circle("line", sx, sy, 4.5)
        end
        G.setColor(1, 1, 1, 0.92)
        G.circle("fill", sx, sy, selected and 2.0 or 1.25)
      end
    end
  end

  local wx, wz = projectWorld(state.region, state.x, state.y)
  local wy = sampleHeight(wx, wz) + MOUNT_CLEARANCE
  local sx, sy, scale = Voxel3D.project(wx, wy, wz)
  if sx and sy then drawMountSprite(G, state, sx, sy, scale) end
end

local function drawOpenSky3D(state, fallbackDraw)
  if not (love and love.graphics) then
    if fallbackDraw then return fallbackDraw(state) end
    return
  end
  local ready, why = ensureResources()
  if not ready then
    if fallbackDraw then return fallbackDraw(state) end
    return
  end

  local G, Voxel3D, Mat4 = love.graphics, resources.Voxel3D, resources.Mat4
  local previousCanvas = nil
  if type(G.getCanvas) == "function" then
    local okCanvas, canvas = pcall(G.getCanvas)
    if okCanvas then previousCanvas = canvas end
  end
  local previousCamera, previousTint = Voxel3D.camera, Voxel3D.tint
  local sceneCanvas = nil
  local begun = false
  local ok, err = pcall(function()
    Voxel3D.camera = {
      eye = CAMERA_EYE,
      focus = CAMERA_FOCUS,
      fov = CAMERA_FOV,
      curve = 0,
      up = { 0, 1, 0 },
    }
    Voxel3D.tint = { 1, 1, 1 }
    begun = Voxel3D.beginScene(160, 144, 80, 68, 160, 144, nil,
      "dsr_open_sky_region")
    if not begun then error("Gen2-3D-Sprites beginScene failed") end
    Voxel3D.seams(false)
    Voxel3D.glass(false)
    -- Open Sky is a self-contained regional diorama. The provider may still
    -- hold a shadow map from the local route underneath this opaque state; do
    -- not let that unrelated light-space texture shade the regional model.
    if type(Voxel3D.shader) == "function" then
      for _, grid in ipairs({ false, true }) do
        local okShader, sh = pcall(Voxel3D.shader, grid)
        if okShader and sh then pcall(sh.send, sh, "sunDark", 0) end
      end
    end
    local identity = type(Mat4.identity) == "function" and Mat4.identity() or nil
    Voxel3D.draw(resources.mesh, resources.texture, identity, 0)
    sceneCanvas = Voxel3D.endScene()
    begun = false
  end)

  if begun then pcall(Voxel3D.endScene) end
  Voxel3D.camera, Voxel3D.tint = previousCamera, previousTint
  if previousCanvas then pcall(G.setCanvas, previousCanvas) else pcall(G.setCanvas) end
  pcall(G.setShader)
  pcall(G.setDepthMode)

  if not ok or not sceneCanvas then
    resources.error = tostring(err or "Open Sky 3D returned no canvas")
    resources.ready = false
    if fallbackDraw then return fallbackDraw(state) end
    return
  end

  local pushed = false
  local okDraw, drawErr = pcall(function()
    G.push("all")
    pushed = true
    G.clear(0.58, 0.80, 0.96, 1)
    G.setColor(1, 1, 1, 1)
    G.draw(sceneCanvas, 0, 0)
    drawWorldOverlays(G, state, Voxel3D)
    drawHud(G, state)
  end)
  if pushed then pcall(G.pop) end
  if not okDraw then
    resources.error = tostring(drawErr)
    resources.ready = false
    if fallbackDraw then return fallbackDraw(state) end
  end
end

local function patchState(state)
  if type(state) ~= "table" or patchedStates[state] then return end
  local exports = providerExports()
  if not exports then return end
  patchedStates[state] = true
  local fallbackDraw = state.draw
  state.draw = function(self) return drawOpenSky3D(self, fallbackDraw) end
  state._dsrOpenSkyGen2ThreeD = true
end

local function patchCurrentState()
  if type(playable.state) ~= "function" then return end
  local ok, state = pcall(playable.state)
  if ok and state then patchState(state) end
end

local previousGen2ThreeDOpenSkyUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousGen2ThreeDOpenSkyUpdate(self, dt, ...)
  patchCurrentState()
  return result
end

mod.events:on("game.ready", function()
  providerCache = nil
  resources.tried = false
  resources.ready = false
  resources.error = nil
end)

playable.gen2ThreeD = {
  providerId = PROVIDER_ID,
  detected = function() return providerExports() ~= nil end,
  ready = function() return ensureResources() end,
  error = function() return resources.error end,
  heightAsset = function() return HEIGHT_ASSET end,
  textureAsset = function() return TEXTURE_ASSET end,
  projectWorld = projectWorld,
  sampleHeight = sampleHeight,
}

log("Gen2 Open Sky 3D bridge loaded (provider=%s)", PROVIDER_ID)
end)();