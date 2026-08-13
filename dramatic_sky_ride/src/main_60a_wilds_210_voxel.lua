;(function()
-- Preserve Wilds of Kanto 2.1 variable-size SpriteDefs in the Gen2 voxel
-- compositor. main_60 intentionally owns DSR's ordinary 16x16/native-atlas
-- cards; this late adapter handles only the public Wilds 2.1 vertical sheets.

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports and mod.exports.runtimeGeneration or {}
local Assets = require("src.render.Assets")
local meshes = {}
local state = { installed = false, meshes = 0, lastError = nil }

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function providerExports()
  if type(mod.find) ~= "function" then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  return ok and handle and handle.exports or nil
end

local function providerModule(ex, name)
  local lib = ex and ex.lib or nil
  if not (lib and type(lib.require) == "function") then return nil end
  local ok, value = pcall(lib.require, name)
  return ok and type(value) == "table" and value or nil
end

local function currentMountDef()
  if flight and flight.active and flight.sprite then
    return flight.species or (flight.mon and flight.mon.species), flight.sprite.def
  end
  if ground and ground.active and ground.sprite then
    return ground.species or (ground.mon and ground.mon.species), ground.sprite.def
  end
  local ex = mod.exports or {}
  if type(ex.isWaterRiding) == "function" and type(ex.waterMountSpecies) == "function"
      and type(ex._waterRideVisual) == "function" then
    local okA, active = pcall(ex.isWaterRiding)
    if okA and active == true then
      local okS, species = pcall(ex.waterMountSpecies)
      local okV, sprite = pcall(ex._waterRideVisual)
      if okS and okV and species and sprite then return species, sprite.def end
    end
  end
  return nil
end

local function renderer2D()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.effective) == "function" then
    local ok, value = pcall(rendering.effective)
    if ok then return tostring(value):lower() == "2d" end
  end
  return true
end

local function mountScale(species)
  local fn = mod.exports and mod.exports.mountVisualScale or nil
  if type(fn) == "function" then
    local ok, value = pcall(fn, species)
    value = ok and tonumber(value) or nil
    if value and value > 0 then return value end
  end
  return 1
end

local function geometry(def)
  local fw = math.max(1, tonumber(def and def.frameWidth) or 16)
  local fh = math.max(1, tonumber(def and def.frameHeight) or 16)
  local ax = tonumber(def and def.anchorX)
  local ay = tonumber(def and def.anchorY)
  if ax == nil then ax = fw / 2 end
  if ay == nil then ay = fh end
  return fw, fh, ax, ay
end

local function clearMeshes()
  for _, mesh in pairs(meshes) do
    if mesh and mesh ~= false and mesh.release then pcall(mesh.release, mesh) end
  end
  meshes = {}
end

local function wilds21Def(def)
  return type(def) == "table" and def.dramaticSkyRideWilds21 == true
end

local function buildCard(Voxel3D, def, frame, species)
  if not (Voxel3D and type(Voxel3D.newMesh) == "function"
      and type(Voxel3D.pushQuad) == "function"
      and def and type(def.image) == "string") then return nil end

  local okImage, image = pcall(Assets.image, def.image)
  if not (okImage and image and image.getDimensions) then return nil end
  local iw, ih = image:getDimensions()
  if not (iw and ih and iw > 0 and ih > 0) then return nil end

  local fw, fh, ax, ay = geometry(def)
  frame = math.max(0, math.floor(tonumber(frame) or 0))
  local fy = frame * fh
  if fw > iw or fy + fh > ih then return nil end

  local fit = math.min(16 / fw, 16 / fh, 1)
  local scale = fit * mountScale(species)
  local key = table.concat({ tostring(def.image), tostring(frame), tostring(species),
    tostring(fw), tostring(fh), tostring(ax), tostring(ay),
    string.format("%.5f", scale) }, "#")
  if meshes[key] ~= nil then return meshes[key] or nil end

  local epsU, epsV = 0.02, 0.05
  local u0 = epsU / iw
  local u1 = (fw - epsU) / iw
  local v0 = (fy + epsV) / ih
  local v1 = (fy + fh - epsV) / ih
  local x0 = 8 - ax * scale
  local x1 = x0 + fw * scale
  local y0 = (ay - fh) * scale
  local y1 = ay * scale
  local verts = {
    { x0, y0, 0, u0, v1, 1 }, { x1, y0, 0, u1, v1, 1 },
    { x1, y1, 0, u1, v0, 1 }, { x0, y1, 0, u0, v0, 1 },
  }
  local indices = {}
  Voxel3D.pushQuad(indices, 0)
  local ok, mesh = pcall(Voxel3D.newMesh, verts, indices)
  meshes[key] = ok and mesh or false
  if ok and mesh then state.meshes = state.meshes + 1 end
  return ok and mesh or nil
end

local function install()
  if not isGold() then return false end
  local ex = providerExports()
  local billboards = providerModule(ex, "SpriteBillboards")
  local voxel3D = providerModule(ex, "Voxel3D")
  if not (billboards and voxel3D and type(billboards.mesh) == "function"
      and type(billboards.shadowQuad) == "function") then return false end

  local own = billboards._dramaticSkyRideWilds21Voxel
  if type(own) == "table" and own.owner == mod.id
      and billboards.mesh == own.meshWrapper then
    state.installed = true
    return true
  end

  local rawMesh = billboards.mesh
  local rawShadow = billboards.shadowQuad
  local meshWrapper = function(def, frame)
    if isGold() and renderer2D() and wilds21Def(def) then
      local species, activeDef = currentMountDef()
      if species and activeDef == def then
        return buildCard(voxel3D, def, frame, species) or rawMesh(def, frame)
      end
    end
    return rawMesh(def, frame)
  end
  local shadowWrapper = function(def, frame)
    if isGold() and renderer2D() and wilds21Def(def) then
      local species, activeDef = currentMountDef()
      if species and activeDef == def then
        return buildCard(voxel3D, def, frame, species) or rawShadow(def, frame)
      end
    end
    return rawShadow(def, frame)
  end

  billboards.mesh = meshWrapper
  billboards.shadowQuad = shadowWrapper
  billboards._dramaticSkyRideWilds21Voxel = {
    owner = mod.id,
    rawMesh = rawMesh,
    rawShadow = rawShadow,
    meshWrapper = meshWrapper,
    shadowWrapper = shadowWrapper,
  }

  -- main_60 owns the normal DSR size wrapper and checks these marker fields
  -- before re-arming. Point its live marker at this outer wrapper so it does
  -- not wrap us again on the next overworld tick.
  local sizeMarker = billboards._dramaticSkyRide2DSizeHook
  if type(sizeMarker) == "table" and sizeMarker.owner == mod.id then
    sizeMarker.meshWrapper = meshWrapper
    sizeMarker.shadowWrapper = shadowWrapper
  end

  state.installed = true
  state.lastError = nil
  if Assets and Assets.register then Assets.register(clearMeshes) end
  return true
end

mod.events:on("mods.loaded", install)
mod.events:on("game.ready", install)
mod.events:on("mod.options_changed", function(payload)
  if not payload then return end
  if payload.mod == mod.id or payload.mod == "overworld_wild_spawns"
      or payload.mod == PROVIDER_ID then
    clearMeshes()
    install()
  end
end)

mod.exports.wilds210VoxelCompatibility = {
  api = 1,
  installed = function() return state.installed end,
  meshCount = function() return state.meshes end,
  status = function()
    return { installed = state.installed, meshes = state.meshes, lastError = state.lastError }
  end,
}

install()
log("Wilds of Kanto 2.1 Gen2 voxel geometry bridge loaded")
end)();
