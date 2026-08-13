;(function()
-- -------------------------------------------------------------------------
-- Gen2-3D-Sprites 0.2.22+ compatibility.
--
-- Randy's modern Gold voxel path owns Player:pose(), exact per-frame ground
-- height and its own SpriteBillboards module. Keep DSR on one visual contract:
--   * Randy keeps the native Gold player sprite; DSR's separate proxy is the
--     only mount actor in the voxel cast.
--   * spriteYOffset is not used for DSR Flight while Randy owns the voxel;
--     the mounted rider pose is anchored after VoxelScene has captured its
--     exact frame-local ground height.
--   * HGSS/PokeMMO 4x4 atlases get native UV/crop geometry inside Randy's own
--     SpriteBillboards module instead of being sampled as 16x96 sheets.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local generation = mod.exports.runtimeGeneration or {}
local Assets = require("src.render.Assets")

local state = {
  playerNormalizations = 0,
  riderAltitudeFrames = 0,
  billboardInstalls = 0,
  nativeCards = 0,
  lastProviderVersion = nil,
  lastAbsoluteRiderY = nil,
  lastError = nil,
}

local nativeMeshes = {}

local function isGold()
  return type(generation.isGen2) == "function"
    and generation.isGen2(Game) == true
end

local function provider()
  if type(mod.find) ~= "function" then return nil, nil, nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then return nil, nil, nil end
  local ex = handle.exports
  local bridge = ex and ex.voxelPipelineState or nil
  if ex then state.lastProviderVersion = ex.version or state.lastProviderVersion end
  return handle, ex, type(bridge) == "table" and bridge or nil
end

local function voxelActive()
  local _, ex, bridge = provider()
  if not (ex and bridge) then return false end
  if type(bridge.status) == "function" then
    local ok, status = pcall(bridge.status)
    if ok and type(status) == "table" and status.active ~= nil then
      return status.active == true
    end
  end
  if bridge.active ~= nil then return bridge.active == true end
  if ex.voxelComposeHook ~= nil then return ex.voxelComposeHook == true end
  return ex.rendererInstalled == true
end

local function mountState()
  if flight and flight.active and flight.sprite then
    return "flight", flight.species or (flight.mon and flight.mon.species), flight.sprite
  end
  if ground and ground.active and ground.sprite then
    return "ground", ground.species or (ground.mon and ground.mon.species), ground.sprite
  end
  local ex = mod.exports or {}
  if type(ex.isWaterRiding) == "function" and type(ex.waterMountSpecies) == "function"
      and type(ex._waterRideVisual) == "function" then
    local okActive, active = pcall(ex.isWaterRiding)
    if okActive and active == true then
      local okSpecies, species = pcall(ex.waterMountSpecies)
      local okSprite, sprite = pcall(ex._waterRideVisual)
      if okSpecies and okSprite and species and sprite then
        return "water", species, sprite
      end
    end
  end
  return nil
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
  local _, ex = provider()
  local billboards = providerModule(ex, "SpriteBillboards")
  local voxel3D = providerModule(ex, "Voxel3D")
  if not (billboards and voxel3D and type(billboards.mesh) == "function"
      and type(billboards.shadowQuad) == "function") then return false end

  local marker = billboards._dramaticSkyRideNativePokeMMO022
  if type(marker) == "table" and marker.owner == mod.id
      and billboards.mesh == marker.meshWrapper then
    return true
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
  if Assets.register then Assets.register(clearNativeMeshes) end
  return true
end

local RIDER_FOOT = {
  LUGIA = 8.0, HOOH = 7.5, GYARADOS = 7.0, LAPRAS = 7.0,
  MANTINE = 6.5, SUICUNE = 7.0, RAIKOU = 7.0, ENTEI = 7.2,
  TYRANITAR = 8.0,
}

local function cleanSpecies(value)
  if value == nil then return nil end
  return tostring(value):upper():gsub("[^A-Z0-9]", "")
end

local function riderSeat(species)
  return RIDER_FOOT[cleanSpecies(species)] or 7.0
end

local function stabilizeCapturedRider(posed)
  if not (isGold() and voxelActive() and flight and flight.active == true) then return end
  local ow = mod.exports._mountWorld and mod.exports._mountWorld(Game) or nil
  local player = ow and ow.player or nil
  if not player then return end
  local _, species = mountState()
  local absolute = tonumber(flight.altitude)
  if not absolute then return end
  local targetY = absolute + riderSeat(species)

  for _, p in ipairs(posed or {}) do
    if p and p.isPlayer and p.entity == player then
      -- VoxelScene has already captured the exact ground height used for THIS
      -- frame. Overwrite only its vertical lift so the final y = gh + lift is
      -- identical to DSR's absolute mount altitude, even when Randy changes
      -- groundAt() semantics or a roof/ledge lies below the rider.
      local gh = tonumber(p.gh) or 0
      p.lift = targetY - gh
      p.dramaticSkyRideAbsoluteRiderY = targetY
      state.lastAbsoluteRiderY = targetY
      state.riderAltitudeFrames = state.riderAltitudeFrames + 1
      return
    end
  end
end

local function installRiderPoseHook()
  local _, ex = provider()
  local stadium = ex and ex.overworld or nil
  if not (type(stadium) == "table" and type(stadium.prepare) == "function") then
    return false
  end

  local marker = stadium._dramaticSkyRideCapturedRider022
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.wrapper then return true end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    local result = raw(posed, ...)
    stabilizeCapturedRider(posed)
    return result
  end
  stadium.prepare = wrapper
  stadium._dramaticSkyRideCapturedRider022 = {
    owner = mod.id, raw = raw, wrapper = wrapper,
  }
  return true
end

local function normalizePlayerForProvider(ow)
  if not (isGold() and voxelActive() and ow and ow.player and mountState()) then return end
  local bridge = mod.exports and mod.exports.gen2PlayerBridge or nil
  if not (bridge and type(bridge.nativePlayerSprite) == "function") then return end

  local ok, sprite, def = pcall(bridge.nativePlayerSprite, ow.player)
  if not (ok and sprite) then return end

  -- main_56 predates the separate Gen2 voxel proxy and still installs the
  -- Pokemon itself as player.sprite plus a terrain-derived spriteYOffset.
  -- Randy 0.2.22 owns Player:pose() and can observe those fields directly.
  -- Keep the real Gold player visually native; main_58's instance pose remains
  -- the sole rider presentation while the proxy remains the sole mount.
  ow.player.sprite = sprite
  ow.player.spriteDef = def or sprite.def or ow.player.spriteDef
  ow.player.spriteYOffset = 0
  state.playerNormalizations = state.playerNormalizations + 1
end

local function installAll()
  if not isGold() then return end
  installProviderBillboardHook()
  installRiderPoseHook()
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  if isGold() and Game.overworld == self then
    installAll()
    normalizePlayerForProvider(self)
  end
  return result
end

mod.events:on("game.ready", installAll)
mod.events:on("mods.loaded", installAll)
mod.events:on("mod.options_changed", function(payload)
  if payload then
    local key = tostring(payload.key or "")
    if payload.mod == PROVIDER_ID and key == "sprite_style" then
      clearNativeMeshes()
    elseif payload.mod == mod.id and (key == "pokedex_mount_sizes"
        or key:match("^mount_size_") or key == "flight_mount_renderer") then
      clearNativeMeshes()
    end
  end
  installAll()
end)

mod.exports.gen2Stadium2022Compat = {
  api = 1,
  providerId = PROVIDER_ID,
  status = function()
    return {
      providerVersion = state.lastProviderVersion,
      voxelActive = voxelActive(),
      playerNormalizations = state.playerNormalizations,
      riderAltitudeFrames = state.riderAltitudeFrames,
      billboardInstalls = state.billboardInstalls,
      nativeCards = state.nativeCards,
      lastAbsoluteRiderY = state.lastAbsoluteRiderY,
      lastError = state.lastError,
    }
  end,
}

installAll()
log("Gen2-3D-Sprites 0.2.22+ compat loaded (native rider ownership, exact captured altitude, native HGSS/PokeMMO billboards)")
end)();
