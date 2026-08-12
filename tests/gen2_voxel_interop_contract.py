#!/usr/bin/env python3
from pathlib import Path
import json
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
stadium = (src / "main_28_stadium_compat.lua").read_text(encoding="utf-8")
interop = (src / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")
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
require('return "gen2_stadium2_voxel"' in stadium,
        "Gen2 voxel provider is not represented in renderer arbitration")
require(stadium.index('return "gen2_stadium2_voxel"') < stadium.index('return "native_stadium2"'),
        "Gen2 voxel provider must be preferred ahead of DSR native Stadium 2")
require("usesGen2VoxelStadium" in stadium and "usesNativeStadium" in stadium,
        "renderer ownership helpers are missing")
require("voxelPipelineState" in stadium and "voxelComposeHook" in stadium,
        "Gen2 provider activity is not capability-detected")

require(parts.index("main_56_gen2_player_bridge.lua")
        < parts.index("main_57_gen2_ground_water_bridge.lua")
        < parts.index("main_58_gen2_voxel_interop.lua"),
        "Gen2 voxel interop must load after the mature Gold player/water bridges")

require('id = "DSR_GEN2_VOXEL_MOUNT"' in interop,
        "separate Gen2 voxel mount entity is missing")
require("passable = true" in interop,
        "voxel mount proxy must never participate in gameplay collision")
require("dramaticSkyRideMountSpecies" in interop and "skyRideMountSpecies" in interop,
        "mount identity tags expected by Gen2-3D-Sprites are missing")
require("_stadiumSkyRideMount = true" in interop
        and "_stadiumSkyRideAnchorPx" in interop
        and "_stadiumSkyRideLift" in interop,
        "Randy Stadium mount positioning contract is incomplete")
require("proxy.stadiumModel = stadium and true or false" in interop
        and "proxy.pokemonModel = stadium and true or false" in interop,
        "2D renderer opt-out is not propagated to the voxel proxy")

# The provider's Wilds/native party follower must never become a second copy of
# the Pokemon currently owned by DSR as the visual mount.
require("isCurrentMountFollower" in interop
        and "filteredMountFollowers" in interop
        and "suppressedFollowers" in interop,
        "active mount follower deduplication is missing")
require("entity.stadiumModel = false" in interop
        and "entity.pokemonModel = false" in interop,
        "suppressed native followers can still be rescued as Stadium models")
require("bridge.extraEntitiesProvider" in interop
        and "previousExtraProvider" in interop
        and "pcall(previous, world)" in interop,
        "existing Wilds/voxel extra-entity provider is not preserved")
require("appendUnique" in interop,
        "composed extra entities are not deduplicated")

# Voxel composition must use the same cropped rider as normal DSR instead of a
# complete standing Gold/red_3d_player actor.
require('id = "DSR_GEN2_VOXEL_RIDER"' in interop
        and "mountedRiderPose" in interop
        and "groundRiderPose" in interop,
        "DSR cropped rider pose is not reused in Gen2 voxel mode")
require("_dramaticSkyRideVoxelRider" in interop
        and "safeDrawPlayerSkin" in interop,
        "full red_3d_player skin is not suppressed while DSR owns the rider")
require("rawset(player, \"pose\", wrapper)" in interop
        and "restoreRiderPose" in interop,
        "player pose override is not reversible")

# Stadium 2 mount models must follow DSR's own Pokedex/user size contract rather
# than Randy's compressed generic overworld model scale.
require("desiredModelWorldHeight" in interop
        and "mountVisualScale" in interop
        and "return 16 * scale" in interop,
        "Stadium model height does not follow DSR mount sizing")
require("Mat4.scale(factor, factor, factor)" in interop
        and "p.stadiumTargetHeight = wanted" in interop,
        "Stadium model matrix is not rescaled to DSR target height")
require("modelScaleFrames" in interop and "modelTargetHeight" in interop,
        "Stadium size diagnostics are missing")

require("flightLift" in interop and "_stadiumSkyRideAltitude" in interop,
        "Flight altitude is not propagated to the voxel mount")
require("gen2VoxelInterop" in interop
        and "existingExtraProviderPreserved" in interop
        and "rendererEffective" in interop,
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
