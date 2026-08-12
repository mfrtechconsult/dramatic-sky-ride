;(function()
-- -------------------------------------------------------------------------
-- Non-recursive final draw guard for the Gen2 voxel mount proxy.
--
-- main_60 used to guard 2D mode by wrapping OverworldStadium.prepare(), but
-- main_58 already owns that seam for mount sizing. Two independent wrappers
-- both trying to remain outermost can re-wrap each other every frame. Keep the
-- provider preparation chain untouched and decline only the final Stadium draw
-- when DSR has not granted Randy ownership of the mount.
-- -------------------------------------------------------------------------

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local guard = { installed = false, blockedDraws = 0, blockedCasts = 0 }

local function externalOwner()
  local api = mod.exports and mod.exports.gen2VoxelSingleOwner or nil
  if api and type(api.externalOwner) == "function" then
    local ok, value = pcall(api.externalOwner)
    return ok and value == true
  end
  return false
end

local function isMountProxy(p)
  local e = p and p.entity or p
  return type(e) == "table" and (
    e.dramaticSkyRideVoxelProxy == true
    or e.id == "DSR_GEN2_VOXEL_MOUNT"
    or e.name == "DSR_GEN2_VOXEL_MOUNT")
end

local function providerStadium()
  if not mod.find then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  local ex = ok and handle and handle.exports or nil
  return ex and ex.overworld or nil
end

local function install()
  local stadium = providerStadium()
  if type(stadium) ~= "table" then return false end
  local marker = stadium._dramaticSkyRideDrawOnlyOwnershipGuard
  if type(marker) == "table" and marker.owner == mod.id then
    guard.installed = true
    return true
  end

  local rawDraw = stadium.safeDraw
  if type(rawDraw) == "function" then
    stadium.safeDraw = function(p, ...)
      if isMountProxy(p) and not externalOwner() then
        guard.blockedDraws = guard.blockedDraws + 1
        return false
      end
      return rawDraw(p, ...)
    end
  end

  local rawCast = stadium.safeCast
  if type(rawCast) == "function" then
    stadium.safeCast = function(p, ...)
      if isMountProxy(p) and not externalOwner() then
        guard.blockedCasts = guard.blockedCasts + 1
        return false
      end
      return rawCast(p, ...)
    end
  end

  stadium._dramaticSkyRideDrawOnlyOwnershipGuard = {
    owner = mod.id,
    drawRaw = rawDraw,
    castRaw = rawCast,
  }
  guard.installed = true
  return true
end

local previousUpdate = OverworldState.update
function OverworldState:update(dt, ...)
  local result = previousUpdate(self, dt, ...)
  install()
  return result
end

mod.events:on("game.ready", install)
mod.events:on("mod.options_changed", install)

mod.exports.gen2VoxelDrawGuard = {
  api = 1,
  installed = function() return guard.installed end,
  status = function()
    return {
      installed = guard.installed,
      externalOwner = externalOwner(),
      blockedDraws = guard.blockedDraws,
      blockedCasts = guard.blockedCasts,
    }
  end,
}

install()
log("Gen2 voxel draw-only ownership guard loaded (prepare chain left untouched)")
end)();