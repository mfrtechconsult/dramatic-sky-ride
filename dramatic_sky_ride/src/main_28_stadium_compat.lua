(function()
-- -------------------------------------------------------------------------
-- Pokemon Stadium Overworld Models compatibility API.
--
-- Keep this surface deliberately small and state-only. Stadium's integration
-- only needs to observe Sky Ride; it must not own DSR's movement or rendering
-- lifecycle. These aliases preserve DSR's existing public altitude()/mount()
-- API while supporting the names consumed by STADIUM_OVERWORLD_MODELS.
-- -------------------------------------------------------------------------

mod.exports.isFlying = function()
  return flight.active == true
end

mod.exports.currentAltitude = function()
  local altitude = mod.exports.altitude
  if type(altitude) == "function" then
    local ok, value = pcall(altitude)
    if ok then return tonumber(value) or 0 end
  end
  return flight.active and (tonumber(flight.altitude) or 0) or 0
end

mod.exports.mountSpecies = function()
  local mount = mod.exports.mount
  if type(mount) == "function" then
    local ok, value = pcall(mount)
    if ok and type(value) == "table" and value.species ~= nil then
      return value.species
    end
  end
  if flight.active then
    return flight.species or (flight.mon and flight.mon.species) or nil
  end
  return nil
end

mod.exports.stadiumCompatibility = {
  api = 1,
  installed = function()
    return mod.find and mod.find("STADIUM_OVERWORLD_MODELS") ~= nil or false
  end,
}

log("Pokemon Stadium overworld compatibility API loaded")
end)();
