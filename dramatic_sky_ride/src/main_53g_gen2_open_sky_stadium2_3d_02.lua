    return nil, "graphics texture API unavailable"
  end
  local ok, image = pcall(love.graphics.newImage, imageData)
  if not ok or not image then return nil, "albedo texture upload failed" end
  pcall(image.setFilter, image, "linear", "linear")
  pcall(image.setWrap, image, "clamp", "clamp")
  return image
end

local function buildTerrain(Voxel3D)
  local image, err = readImageData(HEIGHT_ASSET_PARTS, "open_sky_glb_height.png")
  if not image then return nil, err end
  local w, h = image:getDimensions()
  if w < 2 or h < 2 then return nil, "invalid GLB heightfield" end

  local verts, indices, heights = {}, {}, {}
  for z = 0, h - 1 do
    local tz = z / (h - 1)
    for x = 0, w - 1 do
      local tx = x / (w - 1)
      local r = image:getPixel(x, z)
      local i = z * w + x + 1
      local y = clamp(r, 0, 1) * WORLD_RELIEF
      verts[i] = {
        WORLD_X0 + (WORLD_X1 - WORLD_X0) * tx,
        y,
        WORLD_Z0 + (WORLD_Z1 - WORLD_Z0) * tz,
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
  if not mesh then return nil, "GLB terrain mesh creation failed" end
  return { mesh = mesh, heights = heights, w = w, h = h }
end

local function ensureRenderer()
  if cache.disabled then return nil end
  if cache.ready then return cache end
  local ex = provider()
  if not ex then return nil end

  local okVoxel, Voxel3D = pcall(ex.lib.require, "Voxel3D")
  if not okVoxel or type(Voxel3D) ~= "table" then
    disableThreeD("NOVOX", "Voxel3D unavailable")
    return nil
  end
  if type(Voxel3D.available) == "function" then
    local okAvailable, available = pcall(Voxel3D.available)
    if not okAvailable or available ~= true then
      disableThreeD("GPU", "Voxel3D.available() is false")
      return nil
    end
  end

  local terrain, terrainErr = buildTerrain(Voxel3D)
  if not terrain then
    disableThreeD("MESH", terrainErr)
    return nil
  end
  local texture, textureErr = readTexture()
  if not texture then
    disableThreeD("TEX", textureErr)
    return nil
  end

  cache.Voxel3D = Voxel3D
  cache.mesh = terrain.mesh
  cache.heights = terrain.heights
  cache.w, cache.h = terrain.w, terrain.h
  cache.texture = texture
  cache.ready = true
  setStage("GLB")
  return cache
end

local function worldPoint(region, x, y)
  local rect = REGION_RECT[region] or REGION_RECT.johto
  local nx = (clamp(x, SOURCE_X0, SOURCE_X1) - SOURCE_X0) / (SOURCE_X1 - SOURCE_X0)
  local ny = (clamp(y, SOURCE_Y0, SOURCE_Y1) - SOURCE_Y0) / (SOURCE_Y1 - SOURCE_Y0)
  return rect[1] + nx * (rect[2] - rect[1]),
    rect[3] + ny * (rect[4] - rect[3])
end

local function heightAt(wx, wz)
  if not (cache.ready and cache.heights and cache.w > 1 and cache.h > 1) then return 0 end
  local gx = clamp((wx - WORLD_X0) / (WORLD_X1 - WORLD_X0) * (cache.w - 1), 0, cache.w - 1)
  local gz = clamp((wz - WORLD_Z0) / (WORLD_Z1 - WORLD_Z0) * (cache.h - 1), 0, cache.h - 1)
  local x0, z0 = math.floor(gx), math.floor(gz)
  local x1, z1 = math.min(cache.w - 1, x0 + 1), math.min(cache.h - 1, z0 + 1)
  local tx, tz = gx - x0, gz - z0
  local function at(x, z) return cache.heights[z * cache.w + x + 1] or 0 end
  local a = at(x0, z0) * (1 - tx) + at(x1, z0) * tx
  local b = at(x0, z1) * (1 - tx) + at(x1, z1) * tx
  return a * (1 - tz) + b * tz
end

local function headingForState(state)
  if tonumber(state and state.heading) then return tonumber(state.heading) end
  local facing = state and state.facing or "right"
  if facing == "down" then return math.pi * 0.5 end
  if facing == "left" then return math.pi end
  if facing == "up" then return -math.pi * 0.5 end
  return 0
end

local function mountWorldPose(state)
  local wx, wz = worldPoint(state.region, state.x, state.y)
  local altitudeDelta = clamp((tonumber(state.virtualAltitude) or 88) - 88, -16, 90)
  -- Deliberately independent from heightAt(wx, wz): terrain moves below the
  -- rider, the rider does not ride the heightfield. This is the stable ORAS-like
  -- flight level the regional view needs.
  local wy = CRUISE_FLIGHT_Y + altitudeDelta * ALTITUDE_INPUT_SCALE
  return wx, wy, wz
end

local function visitedPoints(region)
  if type(playable.visitedPoints) ~= "function" then return {} end
  local ok, rows = pcall(playable.visitedPoints, region)
  return ok and type(rows) == "table" and rows or {}
end

local function drawMountOverlay(G, state, Voxel3D, pixelScale)
  -- Never call Player:pose() here: that is what caused the giant trainer sprite
  -- in the previous build. Open Sky only draws the selected flight mount.
  local wx, wy, wz = mountWorldPose(state)
  local x, y, scale = Voxel3D.project(wx, wy, wz)
  if not (x and y) then return end

  local sprite = flight and flight.sprite or nil
  if sprite and type(sprite.draw) == "function" then
    G.push()
    G.translate(math.floor(x), math.floor(y))
    G.rotate(math.rad(clamp(tonumber(state.bank) or 0, -20, 20)) * 0.45)
    local s = 0.22 * math.max(1, tonumber(pixelScale) or 1)
      * clamp(scale or 1, 0.68, 1.35)
    G.scale(s, s)
    G.setColor(1, 1, 1, 1)
    local phase = (tonumber(state.anim) or 0) >= 16 and 1 or 0
