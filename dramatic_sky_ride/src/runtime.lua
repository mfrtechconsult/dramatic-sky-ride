local mod = ...

local Runtime = { public = {} }
local C, Compat, Sprites

local state = {
  mode = nil,
  species = nil,
  dex = nil,
  mon = nil,
  provider = nil,
  appliedPlayer = nil,
  mountSprite = nil,
  visualSlots = {},
  altitude = 34,
  lastShortcut = { flight = false, ground = false },
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

local function clearMarkers(player)
  if not player then return end
  player.dramaticSkyRide = nil
  player.dramaticSkyRideMode = nil
  player.dramaticSkyRideSpecies = nil
  player.dramaticSkyRideDex = nil
  player.dramaticSkyRideAltitude = nil
  if player.dramaticSkyRideFreeFlying then
    player.freeFlying = nil
    player.dramaticSkyRideFreeFlying = nil
  end
end

local function stampMarkers(player, kind, row)
  if not player then return end
  player.dramaticSkyRide = {
    mode = kind,
    species = row.species,
    dex = row.dex,
    provider = state.provider,
  }
  player.dramaticSkyRideMode = kind
  player.dramaticSkyRideSpecies = row.species
  player.dramaticSkyRideDex = row.dex
  player.dramaticSkyRideAltitude = kind == "flight" and state.altitude or 0
  if kind == "flight" then
    player.freeFlying = true
    player.dramaticSkyRideFreeFlying = true
  elseif player.dramaticSkyRideFreeFlying then
    player.freeFlying = nil
    player.dramaticSkyRideFreeFlying = nil
  end
end

local function restoreVisual(player)
  if not player then return end
  -- Restore a slot only when DSR still owns it. If the engine (Surf exit,
  -- player skin change, map reload) or another mod already replaced the slot,
  -- that newer value wins and must never be overwritten with a stale snapshot.
  for _, slot in ipairs(state.visualSlots) do
    if player[slot.name] == state.mountSprite then
      player[slot.name] = slot.original
    end
  end
end

local function clearPlayerVisual()
  local player = state.appliedPlayer
  if player then
    restoreVisual(player)
    clearMarkers(player)
  end
  state.appliedPlayer = nil
  state.mountSprite = nil
  state.visualSlots = {}
end

local function controlledSlots(player, kind)
  if kind ~= "surf" then return { "sprite" } end
  -- Gen 1 selects surfSprite / surfPikachuSprite in Player:pose(). Gold swaps
  -- the single `sprite` through Player:setSprite when playerState changes.
  local slots = {}
  if player.surfSprite ~= nil then slots[#slots + 1] = "surfSprite" end
  if player.surfPikachuSprite ~= nil then slots[#slots + 1] = "surfPikachuSprite" end
  if #slots == 0 then slots[1] = "sprite" end
  return slots
end

local function setPlayerVisual(game, kind, row)
  local player = Compat.player(game)
  if not player then return false, "no player" end
  local sprite, defOrErr = Sprites.build(game, row.species, row.dex, kind)
  if not sprite then return false, defOrErr end

  clearPlayerVisual()
  state.appliedPlayer = player
  state.mountSprite = sprite
  state.provider = defOrErr.providerId
  state.visualSlots = {}
  for _, name in ipairs(controlledSlots(player, kind)) do
    state.visualSlots[#state.visualSlots + 1] = {
      name = name,
      original = player[name],
    }
    player[name] = sprite
  end
  stampMarkers(player, kind, row)
  return true
end

local function stop(reason)
  if not state.mode then return false end
  clearPlayerVisual()
  mod.log:info("mount ended mode=%s species=%s reason=%s",
    tostring(state.mode), tostring(state.species), tostring(reason or "manual"))
  state.mode, state.species, state.dex, state.mon, state.provider =
    nil, nil, nil, nil, nil
  state.surfAuto = false
  return true
end

local function start(game, kind, mon, opts)
  opts = opts or {}
  if not Compat.freeRoam(game) then return false, "not in overworld" end
  if not Compat.healthy(mon) then return false, "mount is unavailable" end
  local row = C.match(kind, game, mon)
  if not row then return false, "not a supported " .. tostring(kind) .. " mount" end

  local surfing = Compat.isSurfing(game)
  if kind == "surf" then
    if not surfing then return false, "start Surf through the game first" end
  elseif surfing then
    return false, "leave the water first"
  end

  stop("switch")
  local ok, err = setPlayerVisual(game, kind, row)
  if not ok then return false, err end
  state.mode, state.species, state.dex, state.mon = kind, row.species, row.dex, mon
  state.surfAuto = opts.auto == true
  mod.log:info("mount started mode=%s species=%s provider=%s",
    kind, row.species, tostring(state.provider))
  return true
end

local function preferred(game, kind)
  for _, mon in ipairs(Compat.party(game)) do
    if Compat.healthy(mon) and C.match(kind, game, mon) then return mon end
  end
end

local function toggle(game, kind)
  if state.mode == kind then
    stop("toggle")
    return true
  end
  if state.mode then stop("mode change") end
  local mon = preferred(game, kind)
  if not mon then
    Compat.say(game, "No healthy " .. string.upper(kind) .. " mount is available.")
    return false
  end
  local ok, err = start(game, kind, mon)
  if not ok then
    Compat.say(game, "Cannot mount: " .. tostring(err))
    return false
  end
  return true
end

local function syncSurf(game)
  local player = Compat.player(game)
  if not player then return end
  local surfing = Compat.isSurfing(game)

  if surfing then
    -- Native Surf always wins. If the player enters the water while another
    -- DSR mount is active, end that mode first, then dress native Surf.
    if state.mode and state.mode ~= "surf" then stop("native surf started") end
    if state.mode == nil and option("auto_visible_surf", true)
        and Compat.freeRoam(game) then
      local mon = preferred(game, "surf")
      if mon then start(game, "surf", mon, { auto = true }) end
    end
  elseif state.mode == "surf" then
    stop("surf ended")
  end
end

local function refreshVisualOwnership(game)
  if not state.mode then return end
  local player = Compat.player(game)
  if not player then return end
  local row = C[state.mode] and C[state.mode][state.species]
  if not row then
    stop("catalog entry disappeared")
    return
  end

  if player ~= state.appliedPlayer then
    setPlayerVisual(game, state.mode, row)
    return
  end

  -- Keep the mount visible across native sprite refreshes. Capture the new
  -- native value as the restoration target before putting DSR back on top.
  for _, slot in ipairs(state.visualSlots) do
    if player[slot.name] ~= state.mountSprite then
      slot.original = player[slot.name]
      player[slot.name] = state.mountSprite
    end
  end
  stampMarkers(player, state.mode, row)
end

local function keyboardEdge(key, slot)
  local down = love and love.keyboard and love.keyboard.isDown
    and love.keyboard.isDown(key) or false
  local pressed = down and not state.lastShortcut[slot]
  state.lastShortcut[slot] = down
  return pressed
end

local function updateShortcuts(game)
  if keyboardEdge("h", "flight") then toggle(game, "flight") end
  if keyboardEdge("g", "ground") then toggle(game, "ground") end
  if state.mode == "flight" and option("manual_altitude", true)
      and love and love.keyboard and love.keyboard.isDown then
    if love.keyboard.isDown("pageup") then
      state.altitude = math.min(96, state.altitude + 1)
    end
    if love.keyboard.isDown("pagedown") then
      state.altitude = math.max(20, state.altitude - 1)
    end
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
    if state.mode == "flight" then
      percent = tonumber(option("flight_speed", 125)) or 125
    elseif state.mode == "ground" then
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
    refreshVisualOwnership(game)
    updateShortcuts(game)
  end, 900)

  mod.hooks:wrap("ui.party.submenu", function(nextFn, game, items, mon, ctx)
    local out = nextFn(game, items, mon, ctx)
    if type(out) ~= "table" then out = items or {} end
    if ctx and ctx.battle then return out end

    local function add(kind, label)
      if C.match(kind, game, mon) then
        table.insert(out, 1, {
          label = label,
          onSelect = function(selected, liveGame)
            Compat.closeMenus(liveGame)
            local ok, err = start(liveGame, kind, selected)
            if not ok then Compat.say(liveGame, "Cannot mount: " .. tostring(err)) end
          end,
        })
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
  mod.events:on("battle.started", function()
    if state.mode and state.mode ~= "surf" then stop("battle") end
  end)
end

Runtime.public = {
  start = start,
  stop = stop,
  toggle = toggle,
  state = function()
    return {
      mode = state.mode,
      species = state.species,
      dex = state.dex,
      provider = state.provider,
      altitude = state.altitude,
      surfAuto = state.surfAuto,
    }
  end,
  isFlying = function() return state.mode == "flight" end,
  isGroundRiding = function() return state.mode == "ground" end,
  isSurfing = function() return state.mode == "surf" end,
  altitude = function() return state.altitude end,
}

return Runtime
