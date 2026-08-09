-- ROM-free regression: Dramatic Sky Ride must load with no voxel provider.
-- Run from a Gen1Recomp checkout with LuaJIT 2.1.

package.path = "./?.lua;./?/init.lua;" .. package.path
love = require("tests.love_stub")

local function check(value, message)
  if not value then error("FAIL: " .. message, 2) end
  print("ok - " .. message)
end

local Sdk = require("tests.modkit.sdk")
local run = Sdk.loadMods({
  "wilds",
  "pokepc",
  "sky/dramatic_sky_ride",
}, { root = "..", dev = true })

for _, raw in ipairs(run.errors or {}) do
  io.stderr:write("loader error: ", tostring(raw), "\n")
end
check(#(run.errors or {}) == 0, "2D stack loads without a voxel provider")

local rec = run.loader.mods.DRAMATIC_SKY_RIDE
check(rec and rec.failed ~= true and rec.state == "loaded",
  "Dramatic Sky Ride reaches Loader state=loaded")

local sky = run.loader.exports.DRAMATIC_SKY_RIDE or {}
check(type(sky.isFlying) == "function", "canonical isFlying export is available")
check(type(sky.altitude) == "function", "canonical altitude export is available")
check(type(sky.mount) == "function", "canonical mount export is available")
check(type(sky.flightRendering) == "table", "flight renderer capability is exported")
check(sky.flightRendering.requested() == "2d", "2D sprites are requested by default")
check(sky.flightRendering.effective() == "2d", "2D sprites are effective without VOXEL")
check(type(sky.flatFlight) == "table" and sky.flatFlight.available() == true,
  "native flat 2D renderer is available")
check(sky.stadiumCompatibility and sky.stadiumCompatibility.enabled() == false,
  "Stadium rendering remains disabled unless explicitly available and selected")

run.release()
print("flat 2D loader regression: PASS")
