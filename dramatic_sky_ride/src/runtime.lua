local mod = ...

local Runtime = { public = {} }
local C, Compat, Sprites

local state = {
  mode = nil, species = nil, dex = nil, mon = nil, provider = nil,
  originalSprite = nil, originalSurfSprite = nil, originalSurfPikaSprite = nil,
  appliedPlayer = nil, altitude = 34, lastShortcut = { flight=false, ground=false },
  surfAuto = false,
}

local OPTIONS = {
  { key="flight_speed", type="number", label="FLIGHT SPEED", default=125, min=50, max=200, step=10 },
  { key="ground_speed", type="number", label="GROUND SPEED", default=130, min=50, max=200, step=10 },
  { key="manual_altitude", type="toggle", label="MANUAL ALTITUDE", default=true },
  { key="story_safe", type="toggle", label="STORY SAFE", default=true },
  { key="auto_visible_surf", type="toggle", label="VISIBLE SURF", default=true },
}

local function option(key, default)
  if not (mod.options and mod.options.get) then return default end
  local ok, value = pcall(mod.options.get, mod.options, key)
  return ok and value ~= nil and value or default
end

local function clearPlayerVisual()
  local p = state.appliedPlayer
  if p then
    if state.originalSprite ~= nil then p.sprite = state.originalSprite end
    if state.originalSurfSprite ~= nil then p.surfSprite = state.originalSurfSprite end
    if state.originalSurfPikaSprite ~= nil then p.surfPikachuSprite = state.originalSurfPikaSprite end
    p.dramaticSkyRide = nil
    p.dramaticSkyRideMode = nil
    p.dramaticSkyRideSpecies = nil
    p.dramaticSkyRideDex = nil
    p.dramaticSkyRideAltitude = nil
    if p.freeFlying and p.dramaticSkyRideFreeFlying then p.freeFlying = nil end
    p.dramaticSkyRideFreeFlying = nil
  end
  state.appliedPlayer = nil
  state.originalSprite = nil
  state.originalSurfSprite = nil
  state.originalSurfPikaSprite = nil
end

local function setPlayerVisual(game, kind, row)
  local p = Compat.player(game)
  if not p then return false, "no player" end
  local sprite, defOrErr = Sprites.build(game, row.species, row.dex, kind)
  if not sprite then return false, defOrErr end
  clearPlayerVisual()
  state.appliedPlayer = p
  state.originalSprite = p.sprite
  state.originalSurfSprite = p.surfSprite
  state.originalSurfPikaSprite = p.surfPikachuSprite
  if kind == "surf" then
    if p.surfSprite ~= nil then p.surfSprite = sprite else p.sprite = sprite end
    if p.surfPikachuSprite ~= nil then p.surfPikachuSprite = sprite end
  else
    p.sprite = sprite
  end
  state.provider = defOrErr.providerId
  p.dramaticSkyRide = { mode=kind, species=row.species, dex=row.dex, provider=state.provider }
  p.dramaticSkyRideMode = kind
  p.dramaticSkyRideSpecies = row.species
  p.dramaticSkyRideDex = row.dex
  p.dramaticSkyRideAltitude = kind == "flight" and state.altitude or 0
  if kind == "flight" then
    p.freeFlying = true
    p.dramaticSkyRideFreeFlying = true
  end
  return true
end

local function stop(reason)
  if not state.mode then return false end
  clearPlayerVisual()
  mod.log:info("mount ended mode=%s species=%s reason=%s", tostring(state.mode), tostring(state.species), tostring(reason or "manual"))
  state.mode, state.species, state.dex, state.mon, state.provider = nil, nil, nil, nil, nil
  state.surfAuto = false
  return true
end

local function start(game, kind, mon, opts)
  opts = opts or {}
  if not Compat.freeRoam(game) and not opts.allowDuringSurf then return false, "not in overworld" end
  if not Compat.healthy(mon) then return false, "mount is unavailable" end
  local row = C.match(kind, game, mon)
  if not row then return false, "not a supported " .. tostring(kind) .. " mount" end
  if kind ~= "surf" then
    local p = Compat.player(game)
    if p and p.surfing then return false, "leave the water first" end
  end
  stop("switch")
  local ok, err = setPlayerVisual(game, kind, row)
  if not ok then return false, err end
  state.mode, state.species, state.dex, state.mon = kind, row.species, row.dex, mon
  state.surfAuto = opts.auto == true
  mod.log:info("mount started mode=%s species=%s provider=%s", kind, row.species, tostring(state.provider))
  return true
end

local function preferred(game, kind)
  for _, mon in ipairs(Compat.party(game)) do
    if Compat.healthy(mon) and C.match(kind, game, mon) then return mon end
  end
end

local function toggle(game, kind)
  if state.mode == kind then stop("toggle"); return true end
  if state.mode then stop("mode change") end
  local mon = preferred(game, kind)
  if not mon then Compat.say(game, "No healthy " .. string.upper(kind) .. " mount is available."); return false end
  local ok, err = start(game, kind, mon)
  if not ok then Compat.say(game, "Cannot mount: " .. tostring(err)); return false end
  return true
end

local function syncSurf(game)
  local p = Compat.player(game)
  if not p then return end
  local surfing = p.surfing == true
  if surfing and option("auto_visible_surf", true) then
    if state.mode == nil then
      local mon = preferred(game, "surf")
      if mon then start(game, "surf", mon, { auto=true, allowDuringSurf=true }) end
    end
  elseif state.mode == "surf" and state.surfAuto then
    stop("surf ended")
  end
end

local function syncPlayerReplacement(game)
  if not state.mode then return end
  local p = Compat.player(game)
  if p == state.appliedPlayer then
    p.dramaticSkyRideAltitude = state.mode == "flight" and state.altitude or 0
    return
  end
  local row = C[state.mode] and C[state.mode][state.species]
  if row and p then setPlayerVisual(game, state.mode, row) end
end

local function keyboardEdge(key, slot)
  local down = love and love.keyboard and love.keyboard.isDown and love.keyboard.isDown(key) or false
  local pressed = down and not state.lastShortcut[slot]
  state.lastShortcut[slot] = down
  return pressed
end

local function updateShortcuts(game)
  if keyboardEdge("h", "flight") then toggle(game, "flight") end
  if keyboardEdge("g", "ground") then toggle(game, "ground") end
  if state.mode == "flight" and option("manual_altitude", true) and love and love.keyboard and love.keyboard.isDown then
    if love.keyboard.isDown("pageup") then state.altitude = math.min(96, state.altitude + 1) end
    if love.keyboard.isDown("pagedown") then state.altitude = math.max(20, state.altitude - 1) end
  end
end

local function installHooks()
  mod.hooks:wrap("movement.collision", function(nextFn, allowed, ctx)
    local base = nextFn(allowed, ctx)
    if state.mode ~= "flight" or not ctx then return base end
    if ctx.reason == "bounds" then return base end
    if ctx.reason == "entity" and option("story_safe", true) then return base end
    return true
  end, 900)

  mod.hooks:wrap("movement.speed", function(nextFn, frames, ctx)
    local base = tonumber(nextFn(frames, ctx)) or tonumber(frames) or 16
    local percent = 100
    if state.mode == "flight" then percent = tonumber(option("flight_speed", 125)) or 125 end
    if state.mode == "ground" then
      percent = tonumber(option("ground_speed", 130)) or 130
      local row = C.ground[state.species]
      percent = percent * ((row and row.speed) or 1.0)
    end
    if state.mode == "flight" or state.mode == "ground" then
      return math.max(1, math.floor(base * 100 / math.max(1, percent) + 0.5))
    end
    return base
  end, 900)

  mod.hooks:wrap("core.update", function(nextFn, game, dt)
    nextFn(game, dt)
    syncSurf(game)
    syncPlayerReplacement(game)
    updateShortcuts(game)
  end, 900)

  mod.hooks:wrap("ui.party.submenu", function(nextFn, game, items, mon, ctx)
    local out = nextFn(game, items, mon, ctx)
    if type(out) ~= "table" then out = items or {} end
    if ctx and ctx.battle then return out end
    local function add(kind, label)
      if C.match(kind, game, mon) then
        table.insert(out, 1, { label=label, onSelect=function(selected, liveGame)
          Compat.closeMenus(liveGame)
          local ok, err = start(liveGame, kind, selected)
          if not ok then Compat.say(liveGame, "Cannot mount: " .. tostring(err)) end
        end })
      end
    end
    add("flight", "RIDE & FLY")
    add("ground", "RIDE")
    return out
  end, 900)
end

function Runtime.install(deps)
  C, Compat, Sprites = deps.catalog, deps.compat, deps.sprites
  if mod.options and mod.options.define then mod.options:define(OPTIONS) end
  installHooks()
  mod.events:on("battle.started", function() if state.mode and state.mode ~= "surf" then stop("battle") end end)
  mod.events:on("map.exited", function() syncPlayerReplacement(Compat.game()) end)
end

Runtime.public = {
  start = start,
  stop = stop,
  toggle = toggle,
  state = function()
    return { mode=state.mode, species=state.species, dex=state.dex, provider=state.provider,
      altitude=state.altitude, surfAuto=state.surfAuto }
  end,
  isFlying = function() return state.mode == "flight" end,
  isGroundRiding = function() return state.mode == "ground" end,
  isSurfing = function() return state.mode == "surf" end,
  altitude = function() return state.altitude end,
}

return Runtime
