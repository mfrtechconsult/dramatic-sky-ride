#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
handoff = (src / "main_63_gen2_voxel_battle_handoff.lua").read_text(encoding="utf-8")

errors = []

def require(cond, message):
    if not cond:
        errors.append(message)

require("main_63_gen2_voxel_battle_handoff.lua" in parts,
        "battle handoff module is not loaded")
require(parts.index("main_62_gen2_voxel_draw_guard.lua")
        < parts.index("main_63_gen2_voxel_battle_handoff.lua"),
        "battle handoff must load after all other Gen2 voxel visual layers")
require("OverworldState:pushBattle" in handoff and 'beginHandoff("pushBattle")' in handoff,
        "battle presentation is not yielded before provider snapshots")
require('mod.events:on("battle.started"' in handoff
        and 'mod.events:on("battle.ended"' in handoff,
        "battle lifecycle handoff is incomplete")
require("battleShot" in handoff and "return nil" in handoff
        and "updateBattle" in handoff and "return false" in handoff,
        "Randy live-overworld battle renderer is not yielded while DSR handoff is active")
require("isDsrPresentationEntity" in handoff
        and "dramaticSkyRideVoxelProxy" in handoff
        and "proxyEntitiesFiltered" in handoff,
        "DSR mount/rider proxies are not filtered from the battle snapshot")
require("gen2PlayerBridge" in handoff and "nativePlayerSprite" in handoff,
        "battle snapshot does not restore the native Gold trainer pose")
require("src.world.gen2.Follower" in handoff
        and "setShouldSpawn" in handoff
        and "followerGateReclaims" in handoff,
        "final native Gold follower gate is missing")
require("liveWorld()" in handoff and "purgeRealNativeFollower" in handoff,
        "native follower purge is not applied to the live Game2 world")
require("_mountFreeRoam" in handoff and "finishHandoff" in handoff,
        "battle handoff can end before real free roam/remount")
require("gen2VoxelBattleHandoff" in handoff,
        "battle handoff diagnostics are missing")

if errors:
    print("Gen2 voxel battle handoff contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Gen2 voxel battle handoff contract: PASS")
