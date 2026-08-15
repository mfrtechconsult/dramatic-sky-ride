-- ROM-free regression tests for the sandbox-era Wilds compatibility bridge.
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
  local compiler = loadstring or load
  local chunk, err = compiler("do end" .. source, "@" .. path)
  assert(chunk, err)
  setfenv(chunk, setmetatable(env, { __index = _G }))
  return chunk()
end

local function newHarness(opts)
  opts = opts or {}
  local spriteCalls, syncCalls, legacySyncCalls = {}, 0, 0
  local liveGame = { version = "gold", generation = 2 }
  local ow = { id = "gold-world" }

  local wilds = {
    version = "2.1.5",
    resolveFollowerSprite = function(call)
      spriteCalls[#spriteCalls + 1] = call
      if opts.staticFirst and call.style ~= "followers" then
        return {
          image = "wilds/front.png", frames = 1, walker = false,
          providerId = "overworld_wild_spawns",
        }
      end
      return {
        image = "wilds/follower.png", frames = 6, walker = true,
        trueColor = true, providerId = "overworld_wild_spawns",
      }
    end,
    syncAll = function(game, world)
      syncCalls = syncCalls + 1
      check(game == liveGame, "Wilds sync receives the live sandbox game object")
      check(world == ow, "Wilds sync receives the live overworld object")
      if opts.syncReject then return false, "not_ready" end
      return true
    end,
  }

  local pokepc = {
    resolveFollowerSprite = function(call)
      return {
        image = "pokepc/follower.png", frames = 6, walker = true,
        providerId = "PokePCFollowers_VoxelMerge",
      }
    end,
  }

  local callbacks = {}
  local mod = {
    id = "DRAMATIC_SKY_RIDE",
    exports = {},
    world = { game = liveGame },
    events = {},
  }
  function mod.events:on(name, fn) callbacks[name] = fn end
  function mod.find(_, id)
    if opts.noWilds ~= true and id == "overworld_wild_spawns" then
      return { id = id, version = "2.1.5", exports = wilds }
    end
    if id == "PokePCFollowers_VoxelMerge" then
      return { id = id, version = "0.8.3", exports = pokepc }
    end
  end

  local image = {}
  function image:getDimensions() return 16, 96 end
  local OverworldState = { update = function() return "engine-update" end }
  local originalUpdate = OverworldState.update

  local env = {
    mod = mod,
    Game = { version = "compat-facade" },
    OverworldState = OverworldState,
    Assets = { image = function(path)
      if path == "wilds/front.png" then
        local front = {}
        function front:getDimensions() return 56, 56 end
        return front
      end
      return image
    end },
    followerPath = function() return "legacy-flight.png" end,
    groundFollowerPath = function() return "legacy-ground.png" end,
    syncFollowerMods = function()
      legacySyncCalls = legacySyncCalls + 1
      return true
    end,
    log = function() end,
    -- Explicitly hide debug to model the Gen1Recomp 0.1.90 sandbox.
    debug = false,
  }

  loadInEnv("../sky/dramatic_sky_ride/src/main_27_wilds_compat.lua", env)

  return {
    env = env,
    mod = mod,
    wilds = wilds,
    ow = ow,
    callbacks = callbacks,
    originalUpdate = originalUpdate,
    spriteCalls = spriteCalls,
    syncCalls = function() return syncCalls end,
    legacySyncCalls = function() return legacySyncCalls end,
  }
end

-- Wilds 2.1.5 public provider + follower lifecycle ownership.
do
  local h = newHarness({ staticFirst = true })
  local compat = assert(h.mod.exports.wildsCompatibility)

  check(compat.mode == "sandbox_public_exports",
    "Sky Ride advertises the sandbox public-export bridge")
  check(compat.sandboxBaseline == "2.1.5",
    "Wilds 2.1.5 is recorded as the sandbox compatibility baseline")
  check(compat.available() == true and compat.version() == "2.1.5",
    "Wilds public API and version are detected through mod.find exports")
  check(compat.updateGuardRequired == false and compat.hookGuardReady() == false,
    "no debug/upvalue update guard is required in sandbox mode")
  check(h.env.OverworldState.update == h.originalUpdate,
    "loading Wilds compatibility does not rewrite OverworldState.update")
  check(compat.composeAround(h.originalUpdate) == h.originalUpdate,
    "legacy composeAround shim is non-invasive")
  check(compat.ensureUpdateHook() == true and compat.protectedWrappers() == 0,
    "legacy update-guard shims remain callable without function surgery")

  check(h.env.followerPath("CHARIZARD") == "wilds/follower.png",
    "flight mount resolves the Wilds walking sheet")
  check(h.env.groundFollowerPath("TAUROS") == "wilds/follower.png",
    "ground mount resolves the Wilds walking sheet")
  check(#h.spriteCalls >= 4,
    "static Wilds art is retried through its follower-style walking provider")
  check(h.spriteCalls[1].game == h.mod.world.game,
    "sprite resolver receives mod.world.game instead of a Gen1 facade")

  check(h.env.syncFollowerMods(h.ow) == true,
    "Wilds is authoritative for follower restore sync")
  check(h.syncCalls() == 1 and h.legacySyncCalls() == 0,
    "Wilds sync does not double-run PokéPC/Followers EX lifecycle")

  local cb = h.callbacks["mods.loaded"]
  check(type(cb) == "function", "mods.loaded status callback is registered")
  cb()
end

-- A transient Wilds sync rejection must not fall through into a second
-- follower runtime owner.
do
  local h = newHarness({ syncReject = true })
  check(h.env.syncFollowerMods(h.ow) == false,
    "transient Wilds sync rejection is surfaced")
  check(h.syncCalls() == 1 and h.legacySyncCalls() == 0,
    "transient Wilds state never activates a competing legacy lifecycle")
end

-- Without Wilds, existing provider/sync fallbacks stay available.
do
  local h = newHarness({ noWilds = true })
  check(h.mod.exports.wildsCompatibility.available() == false,
    "Wilds absence is reported cleanly")
  check(h.env.followerPath("CHARIZARD") == "pokepc/follower.png",
    "PokéPC public sprite provider remains the next fallback")
  check(h.env.syncFollowerMods(h.ow) == true and h.legacySyncCalls() == 1,
    "legacy follower sync path is retained when Wilds is absent")
end

print("wilds sandbox compatibility smoke: PASS")
