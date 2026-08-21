local mod = ...

local MusicCompat = {}
local runtime, compat
local active = false
local tracks = {}

local function registerFlightTrack(id, songId, label)
  if type(id) ~= "string" or type(songId) ~= "string" then return false end
  tracks[id] = { songId=songId, label=label or id }
  return true
end

function MusicCompat.install(deps)
  runtime, compat = deps.runtime, deps.compat
  mod.exports.registerFlightTrack = registerFlightTrack
  mod.events:on("mods.loaded", function()
    active = compat.find("Music_FRLG") ~= nil or compat.find("Music_HGSS") ~= nil or compat.find("Music_LGPE") ~= nil
  end)
end

function MusicCompat.status()
  local names = {}
  for id in pairs(tracks) do names[#names+1] = id end
  table.sort(names)
  return { compatible=true, knownPackActive=active, registeredTracks=names }
end

return MusicCompat
