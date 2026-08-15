#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
interop = (root / "src" / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")
compat = (root / "src" / "main_60_gen2_voxel_runtime_compat.lua").read_text(encoding="utf-8")

required_compat = (
    "local GROUND_2D_MIN_SCALE = 1.75",
    "ground.active == true",
    "math.max(scale, GROUND_2D_MIN_SCALE)",
    "mod.exports.gen2Voxel2DPresentation",
)
required_interop = (
    "gen2Voxel2DPresentation",
    "visualScale - canonicalScale",
    "riderSeat(species)",
)
missing = [token for token in required_compat if token not in compat]
missing += [token for token in required_interop if token not in interop]
if missing:
    print("Gen2 Ground 2D presentation contract FAILED")
    for token in missing:
        print(" - missing:", token)
    raise SystemExit(1)

print("Gen2 Ground 2D presentation contract: PASS")
