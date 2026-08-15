;(function()
-- -------------------------------------------------------------------------
-- Immersive mount presentation for 1ST and legacy Dramaless VR.
--
-- Stadium 3D: keep the authoritative player/mount model visible so the
-- camera sees the genuine animated geometry from the saddle.
-- 2D/HGSS/PokeMMO: keep the ordinary player card hidden and add one view-only
-- mount card physically ahead of the saddle. Because it lives in world space,
-- the legacy VR path renders it once per eye and gets stereo depth/parallax
-- without a HUD overlay.
--
-- The saddle bearing follows actual travel intent and is deliberately not
-- derived from head/camera yaw while standing still, so looking around in VR
-- does not rotate the Pokemon with the headset.
-- -------------------------------------------------------------------------

local IMMERSIVE_OPTION = "immersive_mount"
local proxy = nil
local lastSpecies = nil
local bearing = nil
local vrModule = nil
local vrRig = nil

local PROFILE = {
  CHARIZARD={ ahead=17.5, seatBack=3.0 }, PIDGEOT={ ahead=16.0, seatBack=2.4 },
  FEAROW={ ahead=17.0, seatBack=2.5 }, GOLBAT={ ahead=14.5, seatBack=2.0 },
  AERODACTYL={ ahead=19.0, seatBack=3.2 }, ARTICUNO={ ahead=19.0, seatBack=3.0 },
  ZAPDOS={ ahead=18.5, seatBack=3.0 }, MOLTRES={ ahead=19.0, seatBack=3.0 },
  DRAGONAIR={ ahead=20.0, seatBack=3.4 }, DRAGONITE={ ahead=18.0, seatBack=3.0 },
  NOCTOWL={ ahead=16.5, seatBack=2.4 }, CROBAT={ ahead=15.0, seatBack=2.0 },
  XATU={ ahead=15.0, seatBack=2.2 }, SKARMORY={ ahead=18.0, seatBack=2.8 },
  LUGIA={ ahead=21.0, seatBack=4.0 }, HO_OH={ ahead=21.0, seatBack=4.0 },
}
local DEFAULT_PROFILE = { ahead=17.0, seatBack=2.8 }

local FACE_YAW = { down=0, right=math.pi/2, up=math.pi, left=-math.pi/2 }
local function wrapPi(a) return (a + math.pi) % (2 * math.pi) - math.pi end
local function profileFor(species) return PROFILE[species] or DEFAULT_PROFILE end

local function enabled()
  return optionValue(IMMERSIVE_OPTION, true) == true
end

local function providerVR()
  if vrModule == nil then vrModule = dramaticModule("VR") or false end
  return vrModule ~= false and vrModule or nil
end

local function providerVRRig()
  if vrRig == nil then vrRig = dramaticModule("VRRig") or false end
  return vrRig ~= false and vrRig or nil
end

local function vrActive()
  local VR = providerVR()
  if not (VR and type(VR.active) == "function") then return false end
  local ok, active = pcall(VR.active)
  return ok and active == true
end

local function immersiveView()
  if not (enabled() and flight and flight.active and isFreeCamera()) then return false end
  return isFirstPerson() or vrActive()
end

local function stadiumOperational()
  local rendering = mod.exports and mod.exports.flightRendering
  if rendering and type(rendering.usesStadium) == "function" then
    local ok, active = pcall(rendering.usesStadium)
    if ok then return active == true end
  end
  local compat = mod.exports and mod.exports.stadiumCompatibility
  if compat and type(compat.enabled) == "function" then
    local ok, active = pcall(compat.enabled)
    if ok then return active == true end
  end
  return false
end

local function facingFromBearing(a)
  local s, c = math.sin(a or 0), math.cos(a or 0)
  if math.abs(s) > math.abs(c) then return s > 0 and "right" or "left" end
  return c > 0 and "down" or "up"
end

local function initialBearing(player)
  return FACE_YAW[player and player.facing or "down"] or 0
end

local function updateBearing(player)
  if not player then return end
  if lastSpecies ~= flight.species then
    lastSpecies = flight.species
    bearing = initialBearing(player)
  end

  dramaticFirstPerson = dramaticFirstPerson or dramaticModule("FirstPerson")
  local fp = dramaticFirstPerson
  if fp and type(fp.moveVector) == "function" and type(fp.moveWorld) == "function" then
    local okMove, mx, mz = pcall(fp.moveVector)
    if okMove then
      mx, mz = tonumber(mx) or 0, tonumber(mz) or 0
      local mag = math.sqrt(mx * mx + mz * mz)
      if mag > 0.08 then
        local okWorld, wx, wz = pcall(fp.moveWorld, mx, mz)
        wx, wz = okWorld and tonumber(wx) or 0, okWorld and tonumber(wz) or 0
        if math.abs(wx) + math.abs(wz) > 0.001 then bearing = math.atan2(wx, wz) end
      end
    end
  end
  if bearing == nil then bearing = initialBearing(player) end
  bearing = wrapPi(bearing)
end

local function removeProxy(ow)
  if not proxy then return end
  local function purge(list)
    for i = #(list or {}), 1, -1 do
      if list[i] == proxy or (type(list[i]) == "table" and list[i].immersiveMountView) then
        table.remove(list, i)
      end
    end
  end
  if ow then purge(ow.entities); purge(ow.npcs) end
  proxy = nil
end

local function syncProxyTransform(entity, ow)
  local p = ow and ow.player
  if not (entity and p) then return end
  updateBearing(p)
  local cfg = profileFor(flight.species)
  local sx, sz = math.sin(bearing), math.cos(bearing)
  entity.px = p.px + sx * cfg.ahead
  entity.py = p.py + sz * cfg.ahead
  entity.cellX = math.floor(((entity.px or 0) + 8) / 16)
  entity.cellY = math.floor(((entity.py or 0) + 8) / 16)
  entity.facing = facingFromBearing(bearing)
  entity.sprite = flight.sprite
end

local function proxyPose(entity)
  local ow = Game.overworld
  local p = ow and ow.player
  if not (immersiveView() and p and flight.sprite and not stadiumOperational()) then
    return entity.sprite or flight.sprite, entity.px or 0, entity.py or 0,
      entity.facing or "down", 0, false, false
  end
  syncProxyTransform(entity, ow)
  local ground = terrainGroundHeight(ow.map, entity.cellX, entity.cellY)
  local lift = math.max(0, (tonumber(flight.altitude) or 0) - ground)
  local phase = math.floor((tonumber(p.animClock) or 0) / 16) % 2
  local flip = phase == 1
  return flight.sprite, entity.px, entity.py - lift,
    entity.facing, phase, flip, false
end

local function syncProxy()
  local ow = Game.overworld
  if not (ow and ow.player) then removeProxy(ow); return end
  if not immersiveView() or stadiumOperational() or not flight.sprite then
    removeProxy(ow)
    return
  end
  if not proxy then
    proxy = {
      id = "sky_ride_immersive_mount_view",
      immersiveMountView = true,
      passable = true,
      sprite = flight.sprite,
      pose = proxyPose,
    }
  end
  syncProxyTransform(proxy, ow)
  if not contains(ow.entities, proxy) then table.insert(ow.entities, proxy) end
end

-- Run after all existing movement/runtime wrappers. Update owns no gameplay;
-- it only keeps the view-only proxy synchronized for the following draw.
if OverworldState and type(OverworldState.update) == "function"
   and not OverworldState.dramaticSkyRideImmersiveHook then
  local rawUpdate = OverworldState.update
  function OverworldState.update(self, dt)
    local a, b, c = rawUpdate(self, dt)
    syncProxy()
    return a, b, c
  end
  OverworldState.dramaticSkyRideImmersiveHook = true
end

-- Flat 1ST saddle position. The older DSR hook already owns vertical eye
-- height; this late wrapper adds only a small backwards seat displacement.
dramaticFirstPerson = dramaticFirstPerson or dramaticModule("FirstPerson")
if dramaticFirstPerson and type(dramaticFirstPerson.frame) == "function"
   and not dramaticFirstPerson.dramaticSkyRideImmersiveSeatHook then
  local rawFrame = dramaticFirstPerson.frame
  dramaticFirstPerson.frame = function(me, cx, cy, vw, vh)
    if immersiveView() and me then
      local p = Game.overworld and Game.overworld.player
      if p then updateBearing(p) end
      local cfg = profileFor(flight.species)
      local copy = {}
      for k, v in pairs(me) do copy[k] = v end
      copy.px = (copy.px or 0) - math.sin(bearing or 0) * cfg.seatBack
      copy.py = (copy.py or 0) - math.cos(bearing or 0) * cfg.seatBack
      me = copy
    end
    return rawFrame(me, cx, cy, vw, vh)
  end
  dramaticFirstPerson.dramaticSkyRideImmersiveSeatHook = true
end

-- In 1ST/VR the ordinary player card must remain hidden for 2D sources, but
-- Stadium geometry is exactly what we want to see from the saddle. This also
-- overrides the 3RD boom exception while VR is active: legacy Dramaless VR
-- deliberately keeps the headset in the player's head on both freecam rungs.
if dramaticFirstPerson and type(dramaticFirstPerson.hidePlayer) == "function"
   and not dramaticFirstPerson.dramaticSkyRideImmersiveHideHook then
  local rawHidePlayer = dramaticFirstPerson.hidePlayer
  dramaticFirstPerson.hidePlayer = function(...)
    if immersiveView() then return not stadiumOperational() end
    return rawHidePlayer(...)
  end
  dramaticFirstPerson.dramaticSkyRideImmersiveHideHook = true
end

-- Legacy Dramaless 1.6.4 computes VR first-person height from VRRig.fpPivot
-- rather than FirstPerson.frame. Mirror DSR's actual airborne altitude and the
-- same saddle-back offset there, so flat 1ST and both headset eyes share one
-- seat instead of drifting vertically apart.
do
  local Rig = providerVRRig()
  if Rig and type(Rig.fpPivot) == "function" and not Rig.dramaticSkyRideImmersiveHook then
    local rawPivot = Rig.fpPivot
    Rig.fpPivot = function(px, py, gh, eyeH)
      local out = rawPivot(px, py, gh, eyeH)
      if immersiveView() and type(out) == "table" then
        local p = Game.overworld and Game.overworld.player
        if p then updateBearing(p) end
        local cfg = RIDER_OFFSETS[flight.species] or DEFAULT_RIDER_OFFSET
        local seat = profileFor(flight.species)
        out[1] = (out[1] or ((px or 0) + 8)) - math.sin(bearing or 0) * seat.seatBack
        out[3] = (out[3] or ((py or 0) + 8)) - math.cos(bearing or 0) * seat.seatBack
        out[2] = (tonumber(flight.altitude) or tonumber(gh) or 0)
          + (tonumber(cfg.eye) or tonumber(eyeH) or 13)
      end
      return out
    end
    Rig.dramaticSkyRideImmersiveHook = true
  end
end

-- Rider sprites are useful in orbit/3RD, but never around a headset camera.
-- Preserve the existing first-person behavior and extend it to VR-on-3RD.
if type(ensureRiderEntity) == "function" then
  local rawEnsureRiderEntity = ensureRiderEntity
  ensureRiderEntity = function(ow)
    if immersiveView() and vrActive() then
      removeRiderEntity(ow)
      return nil
    end
    return rawEnsureRiderEntity(ow)
  end
end

mod.events:on("mod.options_changed", function(payload)
  if payload and payload.mod == mod.id and payload.key == IMMERSIVE_OPTION then
    if payload.value ~= true then removeProxy(Game.overworld) else syncProxy() end
  end
end)

mod.exports.immersiveMountView = {
  api = 1,
  active = immersiveView,
  vrActive = vrActive,
  stadium = stadiumOperational,
  bearing = function() return bearing end,
  profile = function(species) return profileFor(species) end,
}

log("immersive mount view loaded (1ST + legacy VR; Stadium geometry + 2D world proxy)")
end)();
