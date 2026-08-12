#!/usr/bin/env python3
from pathlib import Path
import sys


root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [
    line.strip()
    for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
bridge_name = "main_56_gen2_player_bridge.lua"
bridge = (src / bridge_name).read_text(encoding="utf-8")
rider = (src / "main_06.lua").read_text(encoding="utf-8")
rider_source = (src / "main_05.lua").read_text(encoding="utf-8")
sizes = (src / "main_21_mount_size.lua").read_text(encoding="utf-8")
rules = (src / "main_22_flight_rules.lua").read_text(encoding="utf-8")

errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require(bridge_name in parts, "the Gold live-player bridge is not loaded")
require('require("src.world.gen2.Player")' not in bridge
        and "require('src.world.gen2.Player')" not in bridge,
        "the bridge must not import or monkey-patch Gold's private Player class")
require("player.sprite = sprite" in bridge and "player.spriteDef =" in bridge,
        "Gold's live player never receives the active mount renderer")
require("player.spriteYOffset" in bridge and "flightLift" in bridge,
        "Gold flight has no visible altitude offset")
require("drawMountedPlayer" in bridge and "mountedRiderPose" in bridge
        and 'rawset(player, "draw", visual.drawWrapper)' in bridge,
        "Gold must compose the rider and mount through its live draw signature")
require("sourceSprite.objColors" in rider and "sprite:setObjPalette" in rider,
        "Gold's cropped rider must inherit the live CGB object palette")
require("_riderSourceSprite" in rider_source
        and "bridge.nativePlayerSprite" in rider_source,
        "rider crops do not resolve Gold's native sprite under a mount")
require("nativePlayerSprite = function(player)" in bridge,
        "the Gold bridge does not expose its preserved native player sprite")
require("riderPlayerSprite = function(player)" in bridge
        and 'id == "SPRITE_SURF"' in bridge
        and "world.sprites.SPRITE_CHRIS" in bridge,
        "Gold's generic Surf sheet can still become the rider on a custom mount")
require("player.sprite ~= visual.installedSprite" in bridge
        and "visual.originalSprite = player.sprite" in bridge,
        "Surf -> Flight can crop Gold's stale native Surf sheet as its rider")
require('mod.hooks:wrap("movement.collision"' in bridge,
        "Gold flight does not use the shared collision seam")
require('ctx.reason ~= "bounds"' in bridge and "return next(true, ctx)" in bridge,
        "Gold flight must open scenery while preserving native route edges")
require('rawMethod("interact")' in bridge and "beginLanding(Game, false)" in bridge,
        "Gold's direct A-button path cannot begin a landing")
require('rawMethod("tryConnection")' in bridge
        and "Map2.connectionLanding" in bridge
        and "self:setMap(info.target" in bridge,
        "Gold flight cannot cross an authored seam with a blocked ground landing")
require("flightConnectionAllowed" in bridge
        and "storyGateBlocks" in bridge and "isMapReached" in bridge,
        "the airborne Gold seam bypasses progression gates")
require("effectiveMountVisualScale" in sizes
        and "current ~= mountVisualScale" in sizes,
        "2D/voxel mounts ignore late Gen2 Pokedex height fallbacks")
require("storyGateBlocks = storyGateBlocks" in rules,
        "Gold cannot reuse the flight story-gate rule")
for method in (
    "checkTrainerBattle", "checkWarpOnArrive", "tryCoordScript",
    "countStep", "tryWildEncounter", "checkCarpetWhileStanding",
):
    require(f'"{method}"' in bridge,
            f"Gold flight does not suppress ground-only {method} consequences")
require("restorePlayerVisual" in bridge and "restoreFlightGuards" in bridge,
        "Gen2 instance overrides are not reversible after dismount")
require("if raw == state.absent then" in bridge
        and "rawset(world, name, nil)" in bridge,
        "inherited Gold methods must restore to nil, not to the sentinel table")

if errors:
    print("Gen2 live-player bridge contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 live-player bridge contract: PASS")
