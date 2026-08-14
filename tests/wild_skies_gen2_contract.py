#!/usr/bin/env python3
from pathlib import Path
import json
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
wild = (src / "main_24_wild_skies.lua").read_text(encoding="utf-8")
free_flight = (src / "main_63_gen2_free_flight.lua").read_text(encoding="utf-8")
voxel = (src / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")
single_owner = (src / "main_61_gen2_voxel_single_owner_guard.lua").read_text(encoding="utf-8")
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

require('WILD_SKIES_INTERCEPT_RADIUS = 1' in wild,
        "Wild Skies interception should match the one-cell Free Fly seam")
require('exports.takeFlyer' in wild and 'pcall(take, p.cellX, p.cellY' in wild,
        "DSR must consume airborne encounters only through Wild Skies takeFlyer")
require('mod.exports._mountFreeRoam' in wild and 'pcall(freeRoam, Game, ow)' in wild,
        "Wild Skies interception must use DSR's Gen1/Gen2 free-roam predicate")
require('expectedBattle' not in wild,
        "The obsolete expectedBattle random-encounter allowance must stay removed")
require('mod.hooks:wrap("encounter.species"' in wild and 'if flight.active then return nil end' in wild,
        "Ordinary terrain encounters must remain blocked for the whole DSR flight")
require('mod.exports.runtimeGeneration' in wild and 'isGen2Runtime' in wild,
        "Wild Skies compatibility must reuse DSR's shared runtime generation detector")
require('if isGen2Runtime(Game) then' in wild and 'setSpriteMode("gen2_wild_skies_native")' in wild,
        "Gen2 must explicitly select Wild Skies native sprite ownership")
require(wild.index('if isGen2Runtime(Game) then') < wild.index('local register = exports.registerSpriteSource'),
        "The Gen2 early return must occur before DSR can register a sprite source")
require('dramaticSkyRideFreeFlying' in wild and 'p.freeFlying = true' in wild,
        "DSR must advertise and ownership-tag the Wild Skies airborne marker")
require('tagOrganic' in wild,
        "Aerial Wild Skies encounters should be tagged organic when Double Battles is present")
require('registerPartnerSource' in wild and 'takeFlockmate' in wild,
        "Double Battles should be able to recruit a nearby Wild Skies flockmate")
require('return mate.species, mate.level' in wild,
        "Double Battles partner source must return species and level separately")
require('lastIntercept' in wild and 'interceptCount' in wild
        and 'spriteIntegrationMode' in wild and 'integrationMode' in wild,
        "Wild Skies diagnostics must expose integration state and recent interceptions")

require('dramaticFirstPerson.moveVector()' in free_flight
        and 'dramaticFirstPerson.moveWorld(mx, mz)' in free_flight,
        "Gold 1ST/3RD Flight must reuse the provider camera-relative analog vector")
require('rawset(world, "pollInput", bridge.pollWrapper)' in free_flight
        and 'self.heldDir = nil' in free_flight,
        "Gold free Flight must suppress the native four-direction heldDir poll")
require('dramaticFirstPerson.onTop = function()' in free_flight
        and 'return freeRoam(liveWorld())' in free_flight,
        "Gold empty-stack free roam must keep FirstPerson look/move input driving")
require('p.px, p.py = bridge.posX - 8, bridge.posZ - 8' in free_flight
        and 'p.cellX, p.cellY = math.floor(bridge.posX / 16)' in free_flight,
        "Gold free Flight must keep continuous world position and logical cells synchronized")
require('world.tryConnection' in free_flight,
        "Gold free Flight must preserve authored route connection handling")

require('local previous = bridge.extraEntitiesProvider' in voxel,
        "Gen2 voxel integration must preserve the previous extra-entities provider chain")
require('pcall(previous, ow)' in voxel,
        "The chained voxel provider must actually call the previous provider")
require('follower' in single_owner.lower(),
        "The Stadium single-owner guard must remain follower-scoped rather than species-global")

optional = manifest.get("optional_dependencies", [])
require(any(x.startswith("wild_skies@>=1.4.1") for x in optional),
        "Wild Skies must remain optional and keep Gen1-compatible dependency range")
require("free_fly" in manifest.get("conflicts", []),
        "DSR and Free Fly must remain mutually exclusive flight engines")
require(set(manifest.get("games", [])) >= {"gen1", "gen2"},
        "Wild Skies interop release must continue targeting both generations")

if errors:
    print("Wild Skies Gen2 contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Wild Skies Gen2 contract: PASS")
