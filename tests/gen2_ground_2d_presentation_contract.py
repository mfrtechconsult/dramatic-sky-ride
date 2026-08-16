#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
interop = (root / "src" / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")
compat = (root / "src" / "main_60_gen2_voxel_runtime_compat.lua").read_text(encoding="utf-8")

required_compat = (
    "local GROUND_2D_MIN_SCALE = 1.75",
    "local WATER_2D_MAX_SCALE = 1.40",
    "local THIRD_PERSON_2D_MAX_SCALE = 1.25",
    "local CLASSIC_2D_WIDTH_SCALE = { GYARADOS = 1.45 }",
    'if kind == "ground" then',
    "math.max(scale, GROUND_2D_MIN_SCALE)",
    'if kind == "water" then',
    "math.min(scale, WATER_2D_MAX_SCALE)",
    "correctedScale = presentation2DScale(species, correctedScale)",
    "mod.exports.gen2Voxel2DPresentation",
    "waterMaximum = WATER_2D_MAX_SCALE",
    "thirdPersonMaximum = THIRD_PERSON_2D_MAX_SCALE",
    "waterWorldLift = WATER_2D_WORLD_LIFT",
    "widthScale",
)
required_interop = (
    "gen2Voxel2DPresentation",
    "visualScale - canonicalScale",
    "riderSeat(species)",
    "align2DSeat",
    'align2DSeat("flight", species, py)',
    'align2DSeat("ground", species, py)',
    "water2DWorldLift",
)
missing = [token for token in required_compat if token not in compat]
missing += [token for token in required_interop if token not in interop]
if missing:
    print("Gen2 Ground 2D presentation contract FAILED")
    for token in missing:
        print(" - missing:", token)
    raise SystemExit(1)

print("Gen2 Ground 2D presentation contract: PASS")
