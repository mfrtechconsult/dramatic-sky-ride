#!/usr/bin/env python3
from pathlib import Path
import json
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
stadium = (src / "main_28_stadium_compat.lua").read_text(encoding="utf-8")
interop = (src / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")
calibration = (src / "main_59_gen2_voxel_visual_fixes.lua").read_text(encoding="utf-8")
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

optional = manifest.get("optional_dependencies", [])
require("STADIUM2_OVERWORLD_MODELS" in optional,
        "Gen2-3D-Sprites is not declared as an optional dependency")
require('local GEN2_COMPANION_ID = "STADIUM2_OVERWORLD_MODELS"' in stadium,
        "Stadium compatibility layer does not detect Randy's Gen2 provider")
require("gen2ProviderAvailable" in stadium,
        "stable Gen2 provider availability helper is missing")
require('if gen2ProviderAvailable() then return "gen2_stadium2_voxel" end' in stadium,
        "Gen2 voxel provider ownership still depends on per-species model probing")
require(stadium.index('return "gen2_stadium2_voxel"') < stadium.index('return "native_stadium2"'),
        "Gen2 voxel provider must be preferred ahead of DSR native Stadium 2")
require("usesGen2VoxelStadium" in stadium and "usesNativeStadium" in stadium,
        "renderer ownership helpers are missing")
require("voxelPipelineState" in stadium and "voxelComposeHook" in stadium,
        "Gen2 provider activity is not capability-detected")

require(parts.index("main_56_gen2_player_bridge.lua")
        < parts.index("main_57_gen2_ground_water_bridge.lua")
        < parts.index("main_58_gen2_voxel_interop.lua")
        < parts.index("main_59_gen2_voxel_visual_fixes.lua"),
        "clean Gen2 voxel layers must load after the Gold gameplay bridges")
for obsolete in (
    "main_61_gen2_voxel_single_owner.lua",
    "main_62_gen2_voxel_draw_guard.lua",
    "main_63_gen2_voxel_battle_handoff.lua",
):
    require(obsolete not in parts, f"obsolete conflicting layer is still loaded: {obsolete}")

require('id = "DSR_GEN2_VOXEL_MOUNT"' in interop,
        "separate Gen2 voxel mount entity is missing")
require("passable = true" in interop,
        "voxel mount proxy must never participate in gameplay collision")
require("dramaticSkyRideMountSpecies" in interop and "skyRideMountSpecies" in interop,
        "mount identity tags expected by Gen2-3D-Sprites are missing")
require('proxy._stadiumSkyRideMount = kind == "flight"' in interop,
        "Ground/Surf are still using Randy's airborne Sky Ride transform")
require("_stadiumSkyRideAnchorPx" in interop and "_stadiumSkyRideLift" in interop,
        "Flight positioning metadata is incomplete")
require("proxy.stadiumModel = use3D and true or false" in interop
        and "proxy.pokemonModel = use3D and true or false" in interop,
        "2D renderer opt-out is not propagated to the voxel proxy")

require("currentMountFollower" in interop and "filteredFollowers" in interop,
        "extra-provider mount follower deduplication is missing")
require("setShouldSpawn" in interop and "_dramaticSkyRideCleanMountGate" in interop,
        "native Gold party follower is not gated while mounted")
require("bridge.extraEntitiesProvider" in interop
        and "state.previousExtra" in interop
        and "pcall(previous, ow)" in interop,
        "existing Wilds/voxel extra-entity provider is not preserved")

require('id = "DSR_GEN2_VOXEL_RIDER"' in interop
        and "mountedRiderPose" in interop
        and "groundRiderPose" in interop,
        "DSR cropped rider pose is not reused in Gen2 voxel mode")
require("_dramaticSkyRideVoxelRider" in interop
        and "safeDrawPlayerSkin" in interop,
        "full red_3d_player skin is not suppressed while DSR owns the rider")
require("rawset(player, \"pose\", wrapper)" in interop
        and "restoreRider" in interop,
        "player pose override is not reversible")

require("desiredModelHeight" in interop and "mountVisualScale" in interop,
        "Stadium model height does not follow DSR mount sizing")
require("M.scale(factor, factor, factor)" in interop
        and "p.stadiumTargetHeight = wanted" in interop,
        "Stadium model matrix is not rescaled to DSR target height")
require("GYARADOS = 6.5" in calibration and "LUGIA = 5.2" in calibration
        and "HO_OH = 3.8" in calibration,
        "canonical Gen2/large-mount size calibration is missing")
require("_dramaticSkyRideGen2NativeGuard" in calibration
        and "usesGen2VoxelStadium" in calibration,
        "DSR native Stadium renderer is not explicitly blocked under Randy ownership")

require("flightLift" in interop and "_stadiumSkyRideAltitude" in interop,
        "Flight altitude is not propagated to the voxel mount")
require("gen2VoxelInterop" in interop and "rendererEffective" in interop,
        "diagnostic API for Gen2 voxel interop is incomplete")

for kind in ("flight", "ground", "water"):
    require(f'return "{kind}"' in interop,
            f"Gen2 voxel proxy does not cover {kind}")

if errors:
    print("Gen2 voxel interop contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Gen2 voxel interop contract: PASS")
