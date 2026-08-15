-- Production Gen1Recomp Loader smoke test for one compatibility stack.
-- Run from the engine checkout. Kanto Dive and Dramatic Deep Dive are tested
-- separately because both own DIVE content and are alternative integrations.

package.path = "./?.lua;./?/init.lua;" .. package.path
love = require("tests.love_stub")

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
  print("ok - " .. message)
end

local Sdk = require("tests.modkit.sdk")
local providerPath = assert(os.getenv("PROVIDER_PATH"), "PROVIDER_PATH is required")
local providerId = assert(os.getenv("PROVIDER_ID"), "PROVIDER_ID is required")
local target = assert(os.getenv("STACK_TARGET"), "STACK_TARGET is required")
check(target == "deep" or target == "kanto", "STACK_TARGET is deep or kanto")

local paths = {
  "wilds",
  "pokepc",
  providerPath,
  "sky/dramatic_sky_ride",
}
if target == "deep" then
  paths[#paths + 1] = "deep/dramatic_deep_dive"
else
  paths[#paths + 1] = "kanto/kanto_dive"
end

local run = Sdk.loadMods(paths, { root = "..", dev = true })

-- The committed Gen1Recomp mod-SDK fixture intentionally contains only a tiny
-- synthetic Pokemon/music dataset. DDD and Kanto Dive correctly reference real
-- Gen 1 species and songs, so post-merge reference validation reports those as
-- unresolved in this ROM-free fixture even though their entry chunks loaded.
local fixtureOwner = target == "deep" and "DRAMATIC_DEEP_DIVE" or "kanto_dive"
local expectedFixtureErrors, unexpectedErrors = {}, {}
for _, raw in ipairs(run.errors or {}) do
  local err = tostring(raw)
  local owned = err:sub(1, #fixtureOwner + 1) == fixtureOwner .. ":"
  local fixtureReference = owned and (
    err:find("unresolved reference to pokemon", 1, true) ~= nil
    or err:find("unresolved reference to music", 1, true) ~= nil
  )
  if fixtureReference then
    expectedFixtureErrors[#expectedFixtureErrors + 1] = err
  else
    unexpectedErrors[#unexpectedErrors + 1] = err
  end
end

for _, err in ipairs(unexpectedErrors) do
  io.stderr:write("unexpected loader error: ", err, "\n")
end
if #expectedFixtureErrors > 0 then
  print(string.format("fixture-only unresolved references ignored: %d (%s)",
    #expectedFixtureErrors, fixtureOwner))
end
check(#unexpectedErrors == 0, target .. " stack has no unexpected Loader errors")

local expectedLoaded = {
  "overworld_wild_spawns",
  "PokePCFollowers_VoxelMerge",
  providerId,
  "DRAMATIC_SKY_RIDE",
  target == "deep" and "DRAMATIC_DEEP_DIVE" or "kanto_dive",
}
for _, id in ipairs(expectedLoaded) do
  local rec = run.loader.mods[id]
  check(rec and rec.failed ~= true and rec.state == "loaded",
    id .. " reaches Loader state=loaded")
end

local wilds = run.loader.exports.overworld_wild_spawns or {}
local pokepc = run.loader.exports.PokePCFollowers_VoxelMerge or {}
local sky = run.loader.exports.DRAMATIC_SKY_RIDE or {}

check(wilds.version == "2.1.5" or type(wilds.version) == "string",
  "Wilds publishes its current version")
check(type(wilds.resolveFollowerSprite) == "function",
  "Wilds publishes resolveFollowerSprite")
check(type(wilds.syncAll) == "function",
  "Wilds publishes sandbox-safe follower sync")
check(pokepc.providerOnly == true and type(pokepc.resolveFollowerSprite) == "function",
  "PokéPC remains a sprite provider while Wilds owns follower runtime")

local skyWilds = assert(sky.wildsCompatibility)
check(skyWilds.mode == "sandbox_public_exports",
  "Sky Ride uses the sandbox public-export Wilds bridge")
check(skyWilds.sandboxBaseline == "2.1.5",
  "Sky Ride records Wilds 2.1.5 as its sandbox baseline")
check(skyWilds.available() == true,
  "Sky Ride sees the loaded Wilds public API")
check(skyWilds.updateGuardRequired == false and skyWilds.hookGuardReady() == false,
  "Sky Ride does not require debug/upvalue update-chain surgery")
check(type(skyWilds.syncFollowers) == "function",
  "Sky Ride exposes the public Wilds follower-resync seam")
check(type(skyWilds.composeAround) == "function",
  "legacy cooperative composition shim remains callable for companions")

if target == "deep" then
  local deep = run.loader.exports.DRAMATIC_DEEP_DIVE or {}
  local diagnosticTravelOnly = type(deep.isActive) == "function" and deep.isActive() == false
  if diagnosticTravelOnly then
    check(deep.wildsCompatibility and deep.wildsCompatibility.hookGuardReady == false,
      "Deep Dive diagnostic travel-only mode leaves update guard intentionally disabled")
  elseif deep.wildsCompatibility and deep.wildsCompatibility.hookGuardReady ~= nil then
    check(deep.wildsCompatibility.hookGuardReady == true
        or deep.wildsCompatibility.hookGuardReady == false,
      "Deep Dive publishes a defined compatibility guard state")
  end
  check(deep.wildsCompatibility and type(deep.wildsCompatibility.ownsUpdate) == "function",
    "Deep Dive publishes cooperative compatibility metadata")
  local selectedProvider = type(deep.voxelProvider) == "function"
    and select(1, deep.voxelProvider()) or nil
  check(selectedProvider == providerId,
    "Deep Dive selects the expected voxel provider: " .. providerId)
else
  local kanto = run.loader.mods.kanto_dive
  check(kanto and kanto.failed ~= true,
    "Kanto Dive coexists with Wilds, PokéPC and Sky Ride")
end

run.release()
print("wilds loader stack (" .. target .. ", " .. providerId .. "): PASS")
