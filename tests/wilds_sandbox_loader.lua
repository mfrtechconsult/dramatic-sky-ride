-- Focused Gen1Recomp Loader smoke test for Wilds of Kanto + Dramatic Sky Ride.
-- Uses the real current mod sandbox with no ROM requirement.

package.path = "./?.lua;./?/init.lua;" .. package.path
love = require("tests.love_stub")

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
  print("ok - " .. message)
end

local Sdk = require("tests.modkit.sdk")
local run = Sdk.loadMods({
  "wilds",
  "sky/dramatic_sky_ride",
}, { root = "..", dev = true })

for _, err in ipairs(run.errors or {}) do
  io.stderr:write("loader error: ", tostring(err), "\n")
end
check(#(run.errors or {}) == 0,
  "Wilds + Sky Ride load without sandbox/loader errors")

for _, id in ipairs({ "overworld_wild_spawns", "DRAMATIC_SKY_RIDE" }) do
  local rec = run.loader.mods[id]
  check(rec and rec.failed ~= true and rec.state == "loaded",
    id .. " reaches Loader state=loaded")
end

local wilds = run.loader.exports.overworld_wild_spawns or {}
local sky = run.loader.exports.DRAMATIC_SKY_RIDE or {}
local compat = assert(sky.wildsCompatibility)

check(type(wilds.resolveFollowerSprite) == "function",
  "Wilds exposes resolveFollowerSprite")
check(type(wilds.syncAll) == "function",
  "Wilds exposes syncAll")
check(compat.mode == "sandbox_public_exports",
  "Sky Ride selects the sandbox public-export bridge")
check(compat.available() == true,
  "Sky Ride resolves Wilds through mod.find(...).exports")
check(compat.updateGuardRequired == false,
  "Sky Ride does not require the removed debug/upvalue surface")
check(compat.hookGuardReady() == false and compat.protectedWrappers() == 0,
  "legacy update-chain guard is disabled rather than emulated")

run.release()
print("wilds sandbox loader: PASS")
