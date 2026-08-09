-- ROM-free compatibility smoke tests for the Wilds integration branches.
-- Run from a Gen1Recomp checkout with LuaJIT 2.1:
--   PROVIDER_PATH=dramaless PROVIDER_ID=DRAMALESS_SHAPE \
--     luajit ../sky/tests/wilds_compat_headless.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
  print("ok - " .. message)
end

local function loadInEnv(path, env)
  local chunk, err = loadfile(path)
  assert(chunk, err)
  setfenv(chunk, setmetatable(env, { __index = _G }))
  return chunk()
end

local function makeDsrUpdateChain(external)
  local update = external
  local function flightCore(self, dt, ...)
    return update(self, dt, ...)
  end

  local groundUpdate = flightCore
  local function groundLayer(self, dt, ...)
    return groundUpdate(self, dt, ...)
  end

  local polishUpdate = groundLayer
  local function polishLayer(self, dt, ...)
    return polishUpdate(self, dt, ...)
  end

  local waterUpdate = polishLayer
  local function waterLayer(self, dt, ...)
    return waterUpdate(self, dt, ...)
  end

  local seamUpdate = waterLayer
  local function seamLayer(self, dt, ...)
    return seamUpdate(self, dt, ...)
  end

  local lot1Update = seamLayer
  local function lot1Layer(self, dt, ...)
    return lot1Update(self, dt, ...)
  end

  local storyRuleUpdate = lot1Layer
  local function storyLayer(self, dt, ...)
    return storyRuleUpdate(self, dt, ...)
  end

  local wildSkiesUpdate = storyLayer
  local function wildLayer(self, dt, ...)
    return wildSkiesUpdate(self, dt, ...)
  end

  return wildLayer
end

local function makeDddLayer(nextUpdate, counter)
  local update = nextUpdate
  return function(self, dt, ...)
    counter.count = counter.count + 1
    return update(self, dt, ...)
  end
end

local function newSkyHarness()
  local externalCount = 0
  local displacedCount = 0
  local wildsSyncCount = 0

  local overworld = {}
  local stack = {}
  function stack:top() return overworld end

  local OverworldState = {}
  local function external(self, dt, ...)
    externalCount = externalCount + 1
    return "external"
  end
  local rootUpdate = makeDsrUpdateChain(external)
  OverworldState.update = rootUpdate

  local Game = { overworld = overworld, stack = stack }
  function Game:step(dt)
    return OverworldState.update(overworld, dt)
  end

  local wildsExports = {
    resolveFollowerSprite = function(opts)
      return {
        image = "wilds/follower.png",
        frames = 6,
        walker = true,
        trueColor = true,
        providerId = "overworld_wild_spawns",
        species = opts and opts.species,
      }
    end,
    syncAll = function()
      wildsSyncCount = wildsSyncCount + 1
      return true
    end,
  }

  local mod = { exports = {} }
  function mod.find(_, id)
    if id == "overworld_wild_spawns" then
      return { id = id, version = "1.12.1", exports = wildsExports }
    end
    return nil
  end

  local image = {}
  function image:getDimensions() return 16, 96 end

  local env = {
    mod = mod,
    Game = Game,
    OverworldState = OverworldState,
    Assets = { image = function() return image end },
    setNearest = function() end,
    followerPath = function() return "legacy-flight.png" end,
    groundFollowerPath = function() return "legacy-ground.png" end,
    syncFollowerMods = function() return false end,
    flight = { active = true },
    ground = { active = false },
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
    env = env,
    mod = mod,
    Game = Game,
    OverworldState = OverworldState,
    overworld = overworld,
    rootUpdate = rootUpdate,
    external = external,
    displace = displace,
    externalCount = function() return externalCount end,
    displacedCount = function() return displacedCount end,
    wildsSyncCount = function() return wildsSyncCount end,
  }
end

-- DSR provider API + solo displacement recovery.
do
  local h = newSkyHarness()
  local compat = assert(h.mod.exports.wildsCompatibility)
  check(compat.hookGuardReady(), "Sky Ride update guard is discoverable")
  check(compat.protectedWrappers() == 8,
    "Sky Ride protects the complete synthetic wrapper chain")
  check(h.env.followerPath("CHARIZARD") == "wilds/follower.png",
    "Sky Ride prefers Wilds' public follower sprite provider")
  check(h.env.groundFollowerPath("TAUROS") == "wilds/follower.png",
    "Ground Ride uses the same public sprite-provider contract")
  check(h.env.syncFollowerMods(h.overworld) == true and h.wildsSyncCount() == 1,
    "Wilds is authoritative for follower lifecycle sync")

  h.Game:step(1 / 60)
  local heartbeat = compat.updateHeartbeat()
  check(heartbeat > 0, "Sky Ride heartbeat crosses the protected boundary")

  h.displace()
  h.Game:step(1 / 60)
  check(h.OverworldState.update == h.rootUpdate,
    "Sky Ride restores its full root after an external displacement")
  check(compat.hookRecoveries() == 1,
    "Sky Ride records exactly one recovery for one displacement")
  h.Game:step(1 / 60)
  check(h.displacedCount() == 2,
    "Recovered Sky Ride still delegates to the displaced external handler")
end

-- Full DDD -> DSR -> external cooperative recovery.
do
  local h = newSkyHarness()
  h.env.flight.active = false
  local dsrCompat = assert(h.mod.exports.wildsCompatibility)

  local dddCounter = { count = 0 }
  local dddRoot = h.OverworldState.update
  for _ = 1, 4 do dddRoot = makeDddLayer(dddRoot, dddCounter) end
  h.OverworldState.update = dddRoot

  local savedGame = package.loaded["src.core.Game"]
  local savedOverworld = package.loaded["src.world.OverworldController"]
  package.loaded["src.core.Game"] = h.Game
  package.loaded["src.world.OverworldController"] = h.OverworldState
  local guardChunk = assert(loadfile("../deep/dramatic_deep_dive/src/UpdateHookGuard.lua"))
  local UpdateHookGuard = guardChunk()
  package.loaded["src.core.Game"] = savedGame
  package.loaded["src.world.OverworldController"] = savedOverworld

  local deepMod = { log = {} }
  function deepMod.log:info() end
  function deepMod.log:warn() end
  function deepMod.find(_, id)
    if id == "DRAMATIC_SKY_RIDE" then
      return { id = id, version = "0.1.5", exports = h.mod.exports }
    end
    return nil
  end
  local controller = { active = true }
  function controller:isActive() return self.active end

  local deepGuard = UpdateHookGuard.install(deepMod, controller)
  check(deepGuard.ready == true, "Deep Dive update guard is armed")
  check(deepGuard.protectedWrappers() == 4,
    "Deep Dive protects its complete synthetic wrapper chain")

  h.Game:step(1 / 60)
  check(deepGuard.heartbeat() > 0 and dsrCompat.updateHeartbeat() > 0,
    "Healthy full stack crosses both DDD and DSR guard boundaries")

  h.displace()
  h.Game:step(1 / 60)
  check(h.OverworldState.update == dddRoot,
    "Deep Dive restores the full DDD root after displacement")
  check(deepGuard.recoveries() == 1,
    "Deep Dive records the displacement recovery")
  check(dsrCompat.hookRecoveries() == 1,
    "Deep Dive recovery cooperatively recomposes Sky Ride")

  local beforeDdd = dddCounter.count
  local beforeDisplaced = h.displacedCount()
  h.Game:step(1 / 60)
  check(dddCounter.count > beforeDdd,
    "Recovered full stack still executes Deep Dive wrappers")
  check(h.displacedCount() == beforeDisplaced + 1,
    "Recovered full stack delegates exactly once to the external handler")
  check(dsrCompat.updateHeartbeat() > 0 and deepGuard.heartbeat() > 0,
    "Recovered DDD -> DSR -> external chain remains live")
end

-- PokéPC provider-only mode can be tested without booting its historical
-- runtime: compat_entry reads main.lua through mod:read, so supply a tiny
-- original initializer and verify the compatibility layer itself.
do
  local restoreCount = 0
  local pcMod = {
    id = "PokePCFollowers_VoxelMerge",
    path = "../pokepc",
    exports = {},
    options = {},
    events = {},
  }
  function pcMod:read(path)
    if path ~= "main.lua" then return nil, "unexpected path" end
    return [[
return function(mod)
  mod.exports.assetPath = function(species)
    return "pokepc/assets/sprites/" .. tostring(species) .. ".png"
  end
  mod.exports.followerVisualScale = function() return 1.5 end
  mod.exports.restore = function() mod._restoreCount = (mod._restoreCount or 0) + 1 end
end
]]
  end
  function pcMod.options:get() return nil end
  function pcMod.events:on() return true end
  function pcMod.find(_, id)
    if id == "overworld_wild_spawns" then
      return { id = id, version = "1.12.1", exports = {} }
    end
    return nil
  end

  local init = assert(loadfile("../pokepc/compat_entry.lua"))()
  init(pcMod)
  restoreCount = pcMod._restoreCount or 0
  local def = pcMod.exports.resolveFollowerSprite({ species = "charizard", role = "mount" })
  check(pcMod.exports.providerOnly == true and restoreCount == 1,
    "PokéPC yields runtime ownership once when Wilds is present")
  check(def and def.species == "CHARIZARD" and def.frames == 6,
    "PokéPC exposes a stable six-frame public sprite definition")
  check(def.visualScale == 1.5 and def.providerId == "PokePCFollowers_VoxelMerge",
    "PokéPC provider preserves visual scale and provider identity")
end

-- Production Loader smoke test against Gen1Recomp's committed fixture dataset.
do
  love = require("tests.love_stub")
  local Sdk = require("tests.modkit.sdk")
  local providerPath = assert(os.getenv("PROVIDER_PATH"), "PROVIDER_PATH is required")
  local providerId = assert(os.getenv("PROVIDER_ID"), "PROVIDER_ID is required")

  local paths = {
    "wilds",
    "pokepc",
    providerPath,
    "sky/dramatic_sky_ride",
    "deep/dramatic_deep_dive",
    "kanto/kanto_dive",
  }
  local run = Sdk.loadMods(paths, { root = "..", dev = true })
  if #run.errors > 0 then
    for _, err in ipairs(run.errors) do io.stderr:write("loader error: ", tostring(err), "\n") end
  end
  check(#run.errors == 0, "full compatibility stack loads with zero Loader errors")

  local expectedLoaded = {
    "overworld_wild_spawns",
    "PokePCFollowers_VoxelMerge",
    providerId,
    "DRAMATIC_SKY_RIDE",
    "DRAMATIC_DEEP_DIVE",
    "kanto_dive",
  }
  for _, id in ipairs(expectedLoaded) do
    local rec = run.loader.mods[id]
    check(rec and rec.failed ~= true and rec.state == "loaded",
      id .. " reaches Loader state=loaded")
  end

  local wilds = run.loader.exports.overworld_wild_spawns or {}
  local pokepc = run.loader.exports.PokePCFollowers_VoxelMerge or {}
  local sky = run.loader.exports.DRAMATIC_SKY_RIDE or {}
  local deep = run.loader.exports.DRAMATIC_DEEP_DIVE or {}

  check(type(wilds.resolveFollowerSprite) == "function",
    "Wilds publishes resolveFollowerSprite")
  check(pokepc.providerOnly == true and type(pokepc.resolveFollowerSprite) == "function",
    "PokéPC remains available as a provider while Wilds owns followers")
  check(sky.wildsCompatibility and sky.wildsCompatibility.hookGuardReady(),
    "Sky Ride arms its production update-chain guard")
  check(deep.wildsCompatibility and deep.wildsCompatibility.hookGuardReady == true,
    "Deep Dive arms its production update-chain guard")

  local selectedProvider = type(deep.voxelProvider) == "function"
    and select(1, deep.voxelProvider()) or nil
  check(selectedProvider == providerId,
    "Deep Dive selects the expected voxel provider: " .. providerId)

  run.release()
end

print("wilds compatibility headless smoke: PASS")
