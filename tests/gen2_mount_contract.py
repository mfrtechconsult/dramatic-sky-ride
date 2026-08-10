#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
gen2 = (src / "main_33_gen2_mounts.lua").read_text(encoding="utf-8")
surf = (src / "main_17_polish_03.lua").read_text(encoding="utf-8")
surf_runtime = (src / "main_17_polish_04.lua").read_text(encoding="utf-8")
runtime = (src / "main_34_mount_runtime_polish.lua").read_text(encoding="utf-8")
followup = (src / "main_35_mount_runtime_followup.lua").read_text(encoding="utf-8")
stadium = (src / "main_28_stadium_compat.lua").read_text(encoding="utf-8")
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]

errors = []
def require(condition, message):
    if not condition:
        errors.append(message)

flight = {
    "NOCTOWL": 164, "CROBAT": 169, "XATU": 178,
    "SKARMORY": 227, "LUGIA": 249, "HO_OH": 250,
}
ground = {
    "MEGANIUM": 154, "GIRAFARIG": 203, "URSARING": 217,
    "DONPHAN": 232, "STANTLER": 234, "RAIKOU": 243,
    "ENTEI": 244, "SUICUNE": 245, "TYRANITAR": 248,
}
surf_mounts = {
    "FERALIGATR": 160, "MANTINE": 226, "KINGDRA": 230, "LUGIA": 249,
}

for species, dex in flight.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", gen2) is not None,
            f"missing Gen2 flight mount {species} #{dex}")
for species, dex in ground.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", gen2) is not None,
            f"missing Gen2 ground mount {species} #{dex}")
for species, dex in surf_mounts.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", surf) is not None,
            f"missing Gen2 visible Surf mount {species} #{dex}")

# Suicune is deliberately unique: Ground Ride owns both land and water visuals.
require("SUICUNE" not in re.search(r"local WATER_ELIGIBLE\s*=\s*\{(.*?)\n\}", surf, re.S).group(1),
        "Suicune must not become a normal visible-Surf mount")
require('SUICUNE   = { dex = 245' in gen2 and 'amphibious = true' in gen2,
        "Suicune amphibious Ground Ride profile missing")
require('partyKnows, ow, "SURF"' in gen2,
        "Suicune water running must preserve normal Surf progression")
require("Game.save.forcedBike" in gen2 and "surfBlockedHere" in gen2,
        "Suicune water running must preserve vanilla Surf restrictions")
require("setSuicuneWaterState(self, true)" in gen2,
        "Suicune must arm native water collision before grid movement")
require("Map.defIsWaterCell(dest, ts, x, y)" in gen2,
        "Suicune must handle water landings across map connections")
require("suicuneBattleWaterResume" in gen2,
        "Suicune water battle remount continuity missing")
require("battleWaterResumePending" in surf_runtime,
        "visible Surf must stay suppressed during Suicune battle remount")
require("ground.amphibiousWater == true" in runtime and "p.surfing = false" in runtime,
        "Suicune seamless map connection must mask native Surf before Ground Ride checks")
require("ground.amphibiousWater = waterHere" in runtime,
        "Suicune destination land/water state must be restored after a map seam")

# FreeMove owns 1ST/3RD locomotion and bypasses Player.tryMove. It therefore
# needs its own pre-collision water arm for Suicune land -> water transitions.
require("freeMoveApproachesWater" in followup,
        "Suicune free-camera water approach probe missing")
require("dramaticFreeMove._pos" in followup and "dramaticFreeMove.RADIUS" in followup,
        "Suicune free-camera water probe must use the provider body position/radius")
require("dramaticFreeMove.dramaticSuicuneWaterHook" in followup,
        "Suicune FreeMove wrapper must install exactly once")
require("p.surfing = true" in followup and "ground.amphibiousWater = true" in followup,
        "Suicune FreeMove must arm native Surf traversal before the water collision check")
require("suicuneSurfUnlocked" in followup,
        "Suicune FreeMove must preserve normal Surf progression")

# Mounted follower policy: hidden by default on flight, Ground Ride and Surf.
require('key = "show_followers_while_mounted"' in runtime and "default = false" in runtime,
        "mounted followers option must exist and default to hidden")
require("entity.wildsFollower == true" in runtime and "entity._wildsFollowerSpecies" in runtime,
        "Wilds follower entities must be recognized by the mounted policy")
require("purgeFollowersDuringFlight = function" in runtime,
        "shared follower purge must be rebound to the mounted policy")
require('callBoolExport("isWaterRiding")' in runtime and "player.surfing == true" in runtime,
        "mounted follower suppression must cover visible and native Surf")
require("entityIsCurrentMountFollower" in runtime,
        "re-enabled mounted followers must still identify the active mount Pokemon")

# When mounted followers are enabled, Wilds' trailer list must remain intact.
# Hiding the current mount via draw override preserves normal follow behaviour
# and avoids Wilds re-seeding the whole pack at the player's cell every frame.
require("previousSuspendFollowers" in followup and "mountedFollowerPassthrough" in followup,
        "enabled mounted followers must bypass destructive follower suspension")
require("hiddenFollowerDraw" in followup and "hideFollowerDraw" in followup,
        "active mount follower must be hidden non-destructively")
require("applyFollowerDrawPolicy" in followup and "isActiveMountFollower" in followup,
        "mounted follower visibility must preserve other live followers")
require("previousPurgeFollowers" in followup and "return previousPurgeFollowers" in followup,
        "default hidden mode must retain the mature destructive suppression path")
require("syncFollowerMods" in followup,
        "enabling followers mid-mount must be able to rebuild a previously hidden Wilds pack once")

# Wilds may run a late follower update. Reassert the free-camera body bearing
# after the full overworld tick so Gen 2 mount sprites follow 1ST/3RD direction.
require("stabilizeFlightFacing" in runtime and "fp.pointBody" in runtime,
        "1ST/3RD flight facing must be reasserted after late runtime hooks")
require("facingFromYaw" in runtime,
        "camera-facing fallback must remain available for compatible voxel forks")

# Battle visual continuity: keep Suicune as the player pose while Ground Ride
# is temporarily suspended, and extend the visible-Surf suppression window.
require("suicuneBattleVisual" in followup,
        "Suicune battle visual snapshot missing")
require("previousSuicuneBattlePose" in followup and "suicuneBattleVisual.sprite" in followup,
        "Suicune must override the vanilla Red Surf pose during battle handoff")
require("gen2.battleWaterResumePending = function" in followup,
        "generic visible Surf must remain suppressed until Suicune remount succeeds")
require("previousFollowerPolicyStartGroundRide" in followup and "suicuneBattleVisual = nil" in followup,
        "successful Suicune remount must retire the battle continuity sprite")

# The Wilds self-healing guard must capture every Overworld update wrapper.
# main_35 deliberately does not add another OverworldState.update wrapper, but
# must load before the guard so its start/pose/free-move hooks are final.
require(parts.index("main_33_gen2_mounts.lua") < parts.index("main_34_mount_runtime_polish.lua")
        < parts.index("main_35_mount_runtime_followup.lua")
        < parts.index("main_27_wilds_compat.lua"),
        "Gen2/runtime follow-up must load before the DSR update-chain guard")

# Current Stadium 1 models are Gen1 only unless a provider explicitly advertises more.
require("supportsSpecies" in stadium and "hasModel" in stadium and "modelAvailable" in stadium,
        "Stadium capability-based species probe missing")
require("dex >= 1 and dex <= 151" in stadium,
        "Gen2 Stadium fallback to the 2D billboard is missing")

if errors:
    print("Generation II mount contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Generation II mount contract: PASS")