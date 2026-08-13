;(function()
-- Stadium 3D rider-seat calibration.
--
-- main_64 owns absolute Flight height. This layer runs immediately after that
-- prepare pass and only applies a small species presentation trim to the human
-- player pose before VoxelScene draws it. It never touches the mount altitude,
-- gameplay altitude or any 2D renderer.

local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"
local STADIUM_SEAT_TRIM = {
  HOOH = -2.0,
}

local state = {
  installs = 0,
  frames = 0,
  lastSpecies = nil,
  lastTrim = 0,
}

local function cleanSpecies(value)
  if type(value) == "table" then value = value.species end
  if value == nil then return nil end
  local s = tostring(value):upper():gsub("[^A-Z0-9]", "")
  return s ~= "" and s or nil
end

local function activeSpecies()
  if not (flight and flight.active == true) then return nil end
  return cleanSpecies(flight.species or (flight.mon and flight.mon.species))
end

local function stadium3D()
  local rendering = mod.exports and mod.exports.flightRendering or nil
  if rendering and type(rendering.usesGen2VoxelStadium) == "function" then
    local ok, value = pcall(rendering.usesGen2VoxelStadium)
    return ok and value == true
  end
  return false
end

local function provider()
  if type(mod.find) ~= "function" then return nil end
  local ok, handle = pcall(mod.find, mod, PROVIDER_ID)
  if not ok or not handle then return nil end
  return handle.exports
end

local function calibrate(posed)
  if not stadium3D() then return end
  local species = activeSpecies()
  local trim = species and tonumber(STADIUM_SEAT_TRIM[species]) or nil
  if not trim or trim == 0 then return end

  for _, p in ipairs(posed or {}) do
    if p and p.isPlayer == true then
      p.lift = (tonumber(p.lift) or 0) + trim
      if tonumber(p.dramaticSkyRideAbsoluteRiderY) then
        p.dramaticSkyRideAbsoluteRiderY = p.dramaticSkyRideAbsoluteRiderY + trim
      end
      p.dramaticSkyRideStadiumSeatTrim = trim
      state.frames = state.frames + 1
      state.lastSpecies = species
      state.lastTrim = trim
      return
    end
  end
end

local function install()
  local ex = provider()
  local stadium = ex and ex.overworld or nil
  if not (type(stadium) == "table" and type(stadium.prepare) == "function") then
    return false
  end

  local marker = stadium._dramaticSkyRideStadiumRiderCalibration
  if type(marker) == "table" and marker.owner == mod.id
      and stadium.prepare == marker.wrapper then
    return true
  end

  local raw = stadium.prepare
  local wrapper = function(posed, ...)
    local result = raw(posed, ...)
    if result ~= false then calibrate(posed) end
    return result
  end

  stadium.prepare = wrapper
  stadium._dramaticSkyRideStadiumRiderCalibration = {
    owner = mod.id,
    raw = raw,
    wrapper = wrapper,
  }
  state.installs = state.installs + 1
  return true
end

mod.events:on("game.ready", install)
mod.events:on("mods.loaded", install)

mod.exports.gen2StadiumRiderCalibration = {
  api = 1,
  status = function()
    return {
      installs = state.installs,
      frames = state.frames,
      species = state.lastSpecies,
      trim = state.lastTrim,
    }
  end,
}

install()
log("Gen2 Stadium rider-seat calibration loaded (Ho-Oh -2.0)")
end)();
