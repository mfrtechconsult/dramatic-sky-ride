;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites 0.2.22+ HGSS/PokeMMO billboard compatibility.
--
-- IMPORTANT: this layer deliberately owns NO Player pose, NO Stadium prepare
-- hook and NO OverworldState update hook.  main_58 is the sole mounted-rider
-- pose owner and already compensates Randy's groundAt() against DSR's absolute
-- flight altitude.  Keeping this file billboard-only prevents compatibility
-- layers from wrapping one another every frame and growing an unbounded call
-- chain.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local Assets = require("src.render.Assets")

local state = {
  billboardInstalls = 0,
  nativeCards = 0,
  lastProviderVersion = nil,
  lastError = nil,
}

local nativeMeshes = {}
local assetsCleanupRegistered = false

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function provider()
  if type(mod.find) ~= "function" then return nil, nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then return nil, nil end
  local ex = handle.exports
  if ex then state.lastProviderVersion = ex.version or state.lastProviderVersion end
  return handle, ex
end

local function providerModule(ex, name)
  local lib = ex and ex.lib or nil
  if not (lib and type(lib.require) == "function") then return nil end
  local ok, value = pcall(lib.require, name)
  return ok and type(value) == "table" and value or nil
end

local function nativePokeMMODef(def)
  return type(def) == "table" and def.dramaticSkyRideNativePokeMMO == true
end

local function clearNativeMeshes()
  for _, mesh in pairs(nativeMeshes) do
    if mesh and mesh ~= false and mesh.release then pcall(mesh.release, mesh) end
  end
  nativeMeshes = {}
end

local function rowForEngineFrame(frame)
  frame = tonumber(frame) or 0
  if frame == 1 or frame == 4 then return 3 end -- up
  if frame == 2 or frame == 5 then return 1 end -- left; right mirrors
  return 0 -- down
end

local function nativeWalkColumn(frame)
  if (tonumber(frame) or 0) < 3 then return 0 end
  local ow = mod.exports._mountWorld and mod.exports._mountWorld(Game) or nil
  local player = ow and ow.player or nil
  local clock = tonumber(player and player.animClock) or 0
  return math.floor(clock / 8) % 4
end

local function nativeCardScale(def, species)
  local correction = mod.exports and mod.exports.nativePokeMMOSizeCorrection or nil
  local crop = correction and type(correction.cropForDef) == "function"
    and correction.cropForDef(def) or nil
  if not crop then return nil end

  local mountScale = 1
  if correction and type(correction.scale) == "function" then
    local ok, value = pcall(correction.scale, species)
    value = ok and tonumber(value) or nil
    if value and value > 0 then mountScale = value end
  elseif mod.exports and type(mod.exports.mountVisualScale) == "function" then
    local ok, value = pcall(mod.exports.mountVisualScale, species)
    value = ok and tonumber(value) or nil
    if value and value > 0 then mountScale = value end
  end
  return crop, (tonumber(crop.fit) or 1) * mountScale
end

local function buildNativeCard(voxel3D, def, frame)
  if not (voxel3D and type(voxel3D.newMesh) == "function"
      and type(voxel3D.pushQuad) == "function" and nativePokeMMODef(def)) then
    return nil
  end

  local species = def.dramaticSkyRideMountSpecies
  local crop, scale = nativeCardScale(def, species)
  if not (crop and scale and scale > 0) then return nil end

  local row = rowForEngineFrame(frame)
  local col = nativeWalkColumn(frame)
  local key = table.concat({
    tostring(def.image), tostring(frame), tostring(row), tostring(col),
    tostring(species), string.format("%.5f", scale),
    tostring(crop.left), tostring(crop.top),
    tostring(crop.width), tostring(crop.height),
  }, "#")
  if nativeMeshes[key] ~= nil then return nativeMeshes[key] or nil end

  local atlasW = tonumber(crop.atlasW)
  local atlasH = tonumber(crop.atlasH)
  local tileW = tonumber(crop.tileW)
  local tileH = tonumber(crop.tileH)
  if not (atlasW and atlasH and tileW and tileH
      and atlasW > 0 and atlasH > 0 and tileW > 0 and tileH > 0) then
    return nil
  end

  local left = tonumber(crop.left) or 0
  local top = tonumber(crop.top) or 0
  local right = tonumber(crop.right) or (left + (tonumber(crop.width) or tileW))
  local bottom = tonumber(crop.bottom) or (top + (tonumber(crop.height) or tileH))
  local width = math.max(1, right - left)
  local height = math.max(1, bottom - top)
  local eps = 0.05

  local u0 = (col * tileW + left + eps) / atlasW
  local u1 = (col * tileW + right - eps) / atlasW
  local v0 = (row * tileH + top + eps) / atlasH
  local v1 = (row * tileH + bottom - eps) / atlasH

  local drawnW = width * scale
  local drawnH = height * scale
  local x0, x1 = 8 - drawnW / 2, 8 + drawnW / 2
  local verts = {
    { x0, 0,      0, u0, v1, 1 }, { x1, 0,      0, u1, v1, 1 },
    { x1, drawnH, 0, u1, v0, 1 }, { x0, drawnH, 0, u0, v0, 1 },
  }
  local indices = {}
  voxel3D.pushQuad(indices, 0)
  local ok, mesh = pcall(voxel3D.newMesh, verts, indices)
  nativeMeshes[key] = ok and mesh or false
  if ok and mesh then state.nativeCards = state.nativeCards + 1 end
  return ok and mesh or nil
end

local function installProviderBillboardHook()
  if not isGold() then return false end
  local _, ex = provider()
  local billboards = providerModule(ex, "SpriteBillboards")
  local voxel3D = providerModule(ex, "Voxel3D")
  if not (billboards and voxel3D and type(billboards.mesh) == "function"
      and type(billboards.shadowQuad) == "function") then return false end

  local marker = billboards._dramaticSkyRideNativePokeMMO022
  if type(marker) == "table" and marker.owner == mod.id
      and billboards.mesh == marker.meshWrapper
      and billboards.shadowQuad == marker.shadowWrapper then
    return true
  end

  -- If a previous hot-loaded copy of this exact adapter exists, unwrap it
  -- before installing the new one.  Never wrap our own stale wrapper.
  if type(marker) == "table" and marker.owner == mod.id then
    if billboards.mesh == marker.meshWrapper and type(marker.rawMesh) == "function" then
      billboards.mesh = marker.rawMesh
    end
    if billboards.shadowQuad == marker.shadowWrapper
        and type(marker.rawShadow) == "function" then
      billboards.shadowQuad = marker.rawShadow
    end
  end

  local rawMesh = billboards.mesh
  local rawShadow = billboards.shadowQuad
  local meshWrapper = function(def, frame)
    if nativePokeMMODef(def) then
      return buildNativeCard(voxel3D, def, frame) or rawMesh(def, frame)
    end
    return rawMesh(def, frame)
  end
  local shadowWrapper = function(def, frame)
    if nativePokeMMODef(def) then
      return buildNativeCard(voxel3D, def, frame) or rawShadow(def, frame)
    end
    return rawShadow(def, frame)
  end

  billboards.mesh = meshWrapper
  billboards.shadowQuad = shadowWrapper
  billboards._dramaticSkyRideNativePokeMMO022 = {
    owner = mod.id,
    rawMesh = rawMesh,
    rawShadow = rawShadow,
    meshWrapper = meshWrapper,
    shadowWrapper = shadowWrapper,
  }
  state.billboardInstalls = state.billboardInstalls + 1
  if not assetsCleanupRegistered and Assets.register then
    Assets.register(clearNativeMeshes)
    assetsCleanupRegistered = true
  end
  return true
end

local function refresh(payload)
  if payload then
    local key = tostring(payload.key or "")
    if payload.mod == PROVIDER_ID and key == "sprite_style" then
      clearNativeMeshes()
    elseif payload.mod == mod.id and (key == "pokedex_mount_sizes"
        or key:match("^mount_size_") or key == "flight_mount_renderer") then
      clearNativeMeshes()
    end
  end
  installProviderBillboardHook()
end

mod.events:on("game.ready", refresh)
mod.events:on("mods.loaded", refresh)
mod.events:on("mod.options_changed", refresh)

mod.exports.gen2Stadium2022Compat = {
  api = 2,
  providerId = PROVIDER_ID,
  status = function()
    return {
      providerVersion = state.lastProviderVersion,
      billboardInstalls = state.billboardInstalls,
      nativeCards = state.nativeCards,
      cachedCards = (function()
        local n = 0
        for _ in pairs(nativeMeshes) do n = n + 1 end
        return n
      end)(),
      lastError = state.lastError,
    }
  end,
}

installProviderBillboardHook()
log("Gen2-3D-Sprites 0.2.22+ HGSS/PokeMMO billboard compat loaded (no Player/prepare/update ownership)")
end)();