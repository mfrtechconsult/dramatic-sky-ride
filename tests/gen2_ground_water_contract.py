#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = (src / "parts.txt").read_text(encoding="utf-8")
bridge = (src / "main_57_gen2_ground_water_bridge.lua").read_text(encoding="utf-8")
player_bridge = (src / "main_56_gen2_player_bridge.lua").read_text(encoding="utf-8")
water = (src / "main_17_polish_04.lua").read_text(encoding="utf-8")
water_state = (src / "main_17_polish_03.lua").read_text(encoding="utf-8")
ground = (src / "main_19_ground_final_01.lua").read_text(encoding="utf-8")
flight = (src / "main_13b.lua").read_text(encoding="utf-8")
ground_base = (src / "main_15_ground.lua").read_text(encoding="utf-8")
errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require("main_57_gen2_ground_water_bridge.lua" in parts,
        "Gold Ground/Water bridge is not loaded")
require('rawset(world, "tryLedgeJump"' in bridge
        and "Permissions.ledgeFacings" in bridge,
        "Gold reverse ledges do not wrap the live native jump seam")
require("map:cellCollision(landX, landY)" in bridge
        and "facings[opposite[dir]]" in bridge,
        "reverse ledges are not validated against Gold's authored landing tag")
require("map:isWalkable(landX, landY)" in bridge
        and "entityOccupies" in bridge and "map:warpAt" in bridge,
        "reverse ledge landing safety checks are incomplete")
require("previousSetSurfingState" in bridge
        and "world:applyPlayerState(surfState)" in bridge,
        "Flight water landing does not arm Gold's native Surf state")
require("isSurfState(world.playerState)" in bridge
        and "player.surfing = surfing" in bridge,
        "ordinary Gold Surf is not mirrored into Visible Surf")
require("_waterRideVisual" in water and "_waterRideRiderPose" in water,
        "Visible Surf does not expose its private read-only render bridge")
require("gen2Voxel2DPresentation" in water
        and "visualScale - 1" in water,
        "Visible Surf rider does not follow the bounded 2D card seat")
require("mod.exports._waterRideVisual" in player_bridge
        and "mod.exports._waterRideRiderPose" in player_bridge,
        "Gold's live player cannot render the private Visible Surf mount")
require("restoreGroundBridge" in bridge and "state.restore" in bridge,
        "the live Gold ledge override is not reversible")
require("mod.exports._mountFreeRoam(Game, self)" in ground,
        "Ground remount still expects Gold's empty stack to contain the World")
require("waterBattleResume = nil" in water_state
        and 'mod.events:on("battle.started"' in water
        and "resolveWaterBattleMount" in water
        and "activateWaterRide(Game, mon)" in water,
        "Visible Surf does not preserve the selected mount across battle cleanup")
require("flightBattleResume.ended = true" in flight
        and "tryFlightBattleResume" in flight
        and "mod.exports._mountFreeRoam(Game, self)" in flight,
        "Flight is restored before Gold actually returns to free roam")
require('environment == "TOWN"' in ground_base
        and 'environment == "ROUTE"' in ground_base
        and 'environment == "CAVE"' in ground_base
        and 'environment == "GATE"' in ground_base,
        "Ground Ride does not use Gold's Bicycle environment allowlist")
require('stopGroundRide(Game, "incompatible_map")' in ground_base
        and "if not groundAreaAllowed(self) then" in ground_base,
        "native Gold building warps can keep Ground Ride active indoors")
require("if not groundAreaAllowed(self) or self.player.surfing then"
            not in ground_base,
        "the building guard would incorrectly dismount amphibious Suicune")

if errors:
    print("Gen2 Ground/Water bridge contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 Ground/Water bridge contract: PASS")
