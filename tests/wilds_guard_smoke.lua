-- Focused ROM-free regression tests for the Wilds compatibility guards.
-- Run from a Gen1Recomp checkout with LuaJIT 2.1.

package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
  print("ok - " .. message)
end

local function loadInEnv(path, env)
  local file = assert(io.open(path, "rb"))
  local source = file:read("*a")
  file:close()
  -- DSR source parts are concatenation fragments. Some deliberately begin
  -- with `;` so they are safe after the previous part but are not standalone
  -- Lua chunks. Prefix one harmless statement to reproduce the real loader.
  local compiler = loadstring or load
  local chunk, err = compiler("do end" .. source, "@" .. path)
  assert(chunk, err)
  setfenv(chunk, setmetatable(env, { __index = _G }))
  return chunk()
end

local function fileExists(path)
  local file = io.open(path, "rb")
  if not file then return false end
  file:close()
  return true
end

local function dsrChain(external)
  local update = external
  local function flight(self, dt, ...) return update(self, dt, ...) end
  local groundUpdate = flight
  local function ground(self, dt, ...) return groundUpdate(self, dt, ...) end
  local polishUpdate = ground
  local function polish(self, dt, ...) return polishUpdate(self, dt, ...) end
  local waterUpdate = polish
  local function water(self, dt, ...) return waterUpdate(self, dt, ...) end
  local seamUpdate = water
  local function seam(self, dt, ...) return seamUpdate(self, dt, ...) end
  local lot1Update = seam
  local function lot1(self, dt, ...) return lot1Update(self, dt, ...) end
  local storyRuleUpdate = lot1
  local function story(self, dt, ...) return storyRuleUpdate(self, dt, ...) end
  local wildSkiesUpdate = story
  local function wild(self, dt, ...) return wildSkiesUpdate(self, dt, ...) end
  local previousGen1SurfUpdate = wild
  local function gen1Surf(self, dt, ...)
    return previousGen1SurfUpdate(self, dt, ...)
  end
  local gen2Update = gen1Surf
  local function gen2(self, dt, ...) return gen2Update(self, dt, ...) end
  local previousGoldSuicuneUpdate = gen2
  local function goldSuicune(self, dt, ...)
    return previousGoldSuicuneUpdate(self, dt, ...)
  end
  return goldSuicune
end

local function dddLayer(nextUpdate, counter)
  local update = nextUpdate
  return function(self, dt, ...)
    counter.count = counter.count + 1
    return update(self, dt, ...)
  end
end

local function newSkyHarness()
  local externalCount, displacedCount, syncCount = 0, 0, 0
  local ow = {}
  local stack = {}
  function stack:top() return ow end

  local OverworldState = {}
  local function external(self, dt, ...)
    externalCount = externalCount + 1
    return "external"
  end
  local root = dsrChain(external)
  OverworldState.update = root

  local Game = { overworld = ow, stack = stack }
  function Game:step(dt) return OverworldState.update(ow, dt) end

  local wilds = {
    resolveFollowerSprite = function(opts)
      return {
        image = "wilds/follower.png", frames = 6, walker = true,
        trueColor = true, providerId = "overworld_wild_spawns",
        species = opts and opts.species,
      }
    end,
    syncAll = function() syncCount = syncCount + 1 return true end,
  }
  local mod = { exports = {} }
  function mod.find(_, id)
    if id == "overworld_wild_spawns" then
      return { id = id, version = "1.12.1", exports = wilds }
    end
  end

  local image = {}
  function image:getDimensions() return 16, 96 end
  local env = {
    mod = mod, Game = Game, OverworldState = OverworldState,
    Assets = { image = function() return image end },
    setNearest = function() end,
    followerPath = function() return "legacy-flight.png" end,
    groundFollowerPath = function() return "legacy-ground.png" end,
    syncFollowerMods = function() return false end,
    flight = { active = true }, ground = { active = false },
    log = function() end,
  }
  loadInEnv("../sky/dramatic_sky_ride/src/main_27_wilds_compat.lua", env)

  local function displace()
    local function displaced(self, dt, ...)
      displacedCount = displacedCount + 1
      return external(self, dt, ...)
    end
    OverworldState.update = displaced
    return displaced
  end

  return {
    env = env, mod = mod, Game = Game, OverworldState = OverworldState,
    ow = ow, root = root, displace = displace,
    externalCount = function() return externalCount end,
    displacedCount = function() return displacedCount end,
    syncCount = function() return syncCount end,
  }
end

-- Sky Ride provider contract and standalone recovery.
do
  local h = newSkyHarness()
  local compat = assert(h.mod.exports.wildsCompatibility)
  check(compat.hookGuardReady(), "Sky Ride guard is armed")
  check(compat.protectedWrappers() == 11, "Sky Ride protects all synthetic DSR wrappers")
  check(h.env.followerPath("CHARIZARD") == "wilds/follower.png",
    "flight mount uses Wilds sprite provider")
  check(h.env.groundFollowerPath("TAUROS") == "wilds/follower.png",
    "ground mount uses Wilds sprite provider")
  check(h.env.syncFollowerMods(h.ow) == true and h.syncCount() == 1,
    "Wilds is authoritative for follower sync")

  h.Game:step(1 / 60)
  check(compat.updateHeartbeat() > 0, "Sky Ride heartbeat reaches external boundary")
  local composedRoot = h.root
  local runComposedRoot = false
  local function watchdogOuter(self, dt, ...)
    if runComposedRoot then return composedRoot(self, dt, ...) end
  end
  h.OverworldState.update = watchdogOuter
  h.Game:step(1 / 60)
  check(h.OverworldState.update == watchdogOuter,
    "missed heartbeat preserves an outer wrapper that still owns the DSR root")
  check(compat.hookRecoveries() == 0,
    "composed watchdog wrapper does not trigger a false recovery")
  h.displace()
  h.Game:step(1 / 60)
  check(h.OverworldState.update == h.root, "Sky Ride restores complete DSR root")
  check(compat.hookRecoveries() == 1, "Sky Ride records one recovery")
  local before = h.displacedCount()
  h.Game:step(1 / 60)
  check(h.displacedCount() == before + 1,
    "recovered DSR delegates once to displaced handler")
end

-- Cooperative full-stack recovery: DDD -> DSR -> external.
-- Deep Dive's current compatibility branch can intentionally run in
-- diagnostic travel-only mode, where no production UpdateHookGuard module is
-- installed. Keep exercising the synthetic cooperative guard whenever that
-- module exists, but do not make a deliberately guardless DDD mode fail DSR's
-- compatibility suite just because its old source file was removed.
do
  local guardPath = "../deep/dramatic_deep_dive/src/UpdateHookGuard.lua"
  if not fileExists(guardPath) then
    check(true, "Deep Dive travel-only mode has no production update guard to exercise")
  else
    local h = newSkyHarness()
    h.env.flight.active = false
    local dsrCompat = assert(h.mod.exports.wildsCompatibility)

    local counter = { count = 0 }
    local dddRoot = h.OverworldState.update
    for _ = 1, 4 do dddRoot = dddLayer(dddRoot, counter) end
    h.OverworldState.update = dddRoot

    local savedGame = package.loaded["src.core.Game"]
    local savedOw = package.loaded["src.world.OverworldController"]
    package.loaded["src.core.Game"] = h.Game
    package.loaded["src.world.OverworldController"] = h.OverworldState
    local Guard = assert(loadfile(guardPath))()
    package.loaded["src.core.Game"] = savedGame
    package.loaded["src.world.OverworldController"] = savedOw

    local deepMod = { log = {} }
    function deepMod.log:info() end
    function deepMod.log:warn() end
    function deepMod.find(_, id)
      if id == "DRAMATIC_SKY_RIDE" then
        return { id = id, version = "0.1.6-rc.4", exports = h.mod.exports }
      end
    end
    local controller = { active = true }
    function controller:isActive() return self.active end

    local deepGuard = Guard.install(deepMod, controller)
    check(deepGuard.ready, "Deep Dive guard is armed")
    check(deepGuard.protectedWrappers() == 4, "Deep Dive protects all synthetic DDD wrappers")
    h.Game:step(1 / 60)
    check(deepGuard.heartbeat() > 0 and dsrCompat.updateHeartbeat() > 0,
      "healthy DDD -> DSR stack crosses both guard boundaries")

    h.displace()
    h.Game:step(1 / 60)
    check(h.OverworldState.update == dddRoot, "Deep Dive restores complete DDD root")
    check(deepGuard.recoveries() == 1, "Deep Dive records one recovery")
    check(dsrCompat.hookRecoveries() == 1,
      "Deep Dive recovery recomposes Sky Ride cooperatively")
    local beforeDdd, beforeExternal = counter.count, h.displacedCount()
    h.Game:step(1 / 60)
    check(counter.count > beforeDdd, "recovered stack executes DDD wrappers")
    check(h.displacedCount() == beforeExternal + 1,
      "recovered DDD -> DSR chain delegates exactly once to external handler")
  end
end

-- PokéPC provider-only compatibility layer.
do
  local mod = {
    id = "PokePCFollowers_VoxelMerge", path = "../pokepc",
    exports = {}, options = {}, events = {},
  }
  function mod:read(path)
    if path ~= "main.lua" then return nil, "unexpected path" end
    return [[
return function(mod)
  mod.exports.assetPath = function(species) return "pokepc/" .. species .. ".png" end
  mod.exports.followerVisualScale = function() return 1.5 end
  mod.exports.restore = function() mod._restores = (mod._restores or 0) + 1 end
end
]]
  end
  function mod.options:get() return nil end
  function mod.events:on() return true end
  function mod.find(_, id)
    if id == "overworld_wild_spawns" then return { id = id, exports = {} } end
  end

  local init = assert(loadfile("../pokepc/compat_entry.lua"))()
  init(mod)
  local def = mod.exports.resolveFollowerSprite({ species = "charizard", role = "mount" })
  check(mod.exports.providerOnly == true and mod._restores == 1,
    "PokéPC yields runtime ownership to Wilds exactly once")
  check(def and def.species == "CHARIZARD" and def.frames == 6,
    "PokéPC exposes a six-frame public sprite definition")
  check(def.visualScale == 1.5 and def.providerId == mod.id,
    "PokéPC provider preserves scale and identity")
end

print("wilds cooperative guard smoke: PASS")

-- Keep one explicit no-provider load in the same CI entry point. This catches
-- accidental reintroduction of a voxel hard requirement while the matrix below
-- continues to exercise Battle Art and Dramaless stacks.
dofile("../sky/tests/flat_2d_loader.lua")
