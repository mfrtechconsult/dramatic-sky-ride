-- Optional Flying Music override.
--
-- Gen1Recomp 0.1.86+ forbids reading another mod's folder. DSR therefore
-- registers only assets shipped inside DSR (the catalog is empty by default).
-- External music packs can be re-enabled later through an explicit mod.exports
-- audio-provider contract without ever scanning the filesystem.
(function()
  local Music = require("src.core.Music")
  local FLYING_MUSIC_NONE = "none"
  local FLYING_MUSIC_OPTION = "flying_music"
  local FLYING_MUSIC_PREFIX = "Music_DSR_Flying_"

  local function loadFlyingMusicCatalog()
    local source = mod:read("audio/flying/tracks.lua")
    if not source then
      mod.log:warn("Flying Music catalog is missing; external pack tracks only")
      return {}
    end
    local chunk, compileErr = load(source, "@audio/flying/tracks.lua")
    if not chunk then
      mod.log:error("Flying Music catalog did not compile: %s", tostring(compileErr))
      return {}
    end
    local ok, catalog = pcall(chunk)
    if not ok then
      mod.log:error("Flying Music catalog failed to load: %s", tostring(catalog))
      return {}
    end
    if type(catalog) ~= "table" then
      mod.log:error("Flying Music catalog must return a table")
      return {}
    end
    return catalog
  end

  local function ownAssetPath(relative)
    relative = tostring(relative or "")
    if relative == "" then return nil end
    if mod.assets and mod.assets.path then return mod.assets:path(relative) end
    return nil
  end

  local function trackFiles(track)
    if type(track) ~= "table" then return nil, nil end
    local intro = track.intro or track.file
    local loop = track.loop or track.loopFile or track.loop_file
    if intro == nil or tostring(intro) == "" then return nil, nil end
    return tostring(intro), loop and tostring(loop) or nil
  end

  local function ownFileAvailable(relative)
    local ok, raw = pcall(mod.read, mod, tostring(relative or ""))
    return ok and type(raw) == "string" and raw ~= ""
  end

  local tracksByKey = {}
  local optionChoices = { { "None", FLYING_MUSIC_NONE } }

  local function registerTrack(track, resolvePath, provider)
    local key = type(track) == "table" and tostring(track.key or "") or ""
    local label = type(track) == "table" and tostring(track.label or "") or ""
    local intro, loop = trackFiles(track)
    if key == "" or key == FLYING_MUSIC_NONE or label == "" or not intro then
      mod.log:warn("Ignoring invalid Flying Music catalog row")
      return false
    end
    if tracksByKey[key] then
      mod.log:warn("Ignoring duplicate Flying Music key %s", key)
      return false
    end
    if not ownFileAvailable(intro) then
      mod.log:warn("Flying Music asset missing for %s: %s", label, tostring(intro))
      return false
    end
    if loop and not ownFileAvailable(loop) then
      mod.log:warn("Flying Music loop asset missing for %s: %s", label, tostring(loop))
      return false
    end
    local introPath = resolvePath(intro)
    local loopPath = loop and resolvePath(loop) or nil
    if not introPath then return false end
    local safeKey = key:gsub("[^%w_]", "_")
    local songId = FLYING_MUSIC_PREFIX .. safeKey
    local def = { file = introPath }
    if loopPath then def.loopFile = loopPath end
    mod.content.music:register(songId, def)
    tracksByKey[key] = {
      key = key, label = label, intro = introPath, loop = loopPath,
      songId = songId, provider = provider or "Dramatic Sky Ride",
    }
    optionChoices[#optionChoices + 1] = { label, key }
    return true
  end

  for _, track in ipairs(loadFlyingMusicCatalog()) do
    registerTrack(track, ownAssetPath, "Dramatic Sky Ride")
  end

  local externalCount = 0
  -- External pack discovery was intentionally retired with the sandbox. A
  -- future pack may expose tracks through mod.exports; DSR will consume that
  -- public API rather than opening the provider's folder.

  OPTION_SCHEMA[#OPTION_SCHEMA + 1] = {
    key = FLYING_MUSIC_OPTION,
    type = "choice",
    label = "FLYING MUSIC",
    default = FLYING_MUSIC_NONE,
    choices = optionChoices,
    help = "Choose a flight theme from DSR-local tracks. External packs need a sandbox-safe export API.",
  }
  if mod.options and mod.options.define then mod.options:define(OPTION_SCHEMA) end

  local activeFlyingSong = nil
  local function selectedFlyingTrack()
    local key = tostring(optionValue(FLYING_MUSIC_OPTION, FLYING_MUSIC_NONE)
      or FLYING_MUSIC_NONE)
    return tracksByKey[key]
  end
  local function playSelectedFlyingMusic()
    if not flight.active then return false end
    local track = selectedFlyingTrack()
    if not track then
      if activeFlyingSong then
        activeFlyingSong = nil
        Music.restoreMap(Game.data)
      end
      return false
    end
    activeFlyingSong = track.songId
    Music.play(Game.data, track.songId, true, { reason = "direct" })
    return true
  end
  local function restoreNormalMapMusic()
    if not activeFlyingSong then return end
    activeFlyingSong = nil
    Music.restoreMap(Game.data)
  end

  if mod.hooks and mod.hooks.wrap then
    mod.hooks:wrap("music.select", function(next, chosen, ctx)
      local track = flight.active and selectedFlyingTrack() or nil
      if track and ctx and ctx.reason == "map" then
        activeFlyingSong = track.songId
        return next(track.songId, ctx)
      end
      return next(chosen, ctx)
    end)
  end

  local rawStartFlightForMusic = startFlight
  startFlight = function(game, mon)
    local started = rawStartFlightForMusic(game, mon)
    if started and flight.active then playSelectedFlyingMusic() end
    return started
  end
  local rawClearFlightForMusic = clearFlight
  clearFlight = function(ow, landingFeedback, surfMon)
    local hadFlyingMusic = activeFlyingSong ~= nil
    local result = rawClearFlightForMusic(ow, landingFeedback, surfMon)
    if hadFlyingMusic then restoreNormalMapMusic() end
    return result
  end

  mod.events:on("mod.options_changed", function(payload)
    if not (payload and payload.mod == mod.id
        and payload.key == FLYING_MUSIC_OPTION) then return end
    if flight.active then playSelectedFlyingMusic() end
  end)

  mod.exports.flyingMusicTracks = function()
    local out = {}
    for _, pair in ipairs(optionChoices) do
      if pair[2] ~= FLYING_MUSIC_NONE then
        local track = tracksByKey[pair[2]]
        out[#out + 1] = {
          label = pair[1], key = pair[2], provider = track and track.provider or nil,
        }
      end
    end
    return out
  end
  mod.exports.flyingMusic = {
    selected = function()
      local track = selectedFlyingTrack()
      return track and track.key or FLYING_MUSIC_NONE
    end,
    activeSong = function() return activeFlyingSong end,
  }
  log("Flying Music compatibility loaded with %d local track(s), %d external tracks",
    #optionChoices - 1, externalCount)
end)()
