#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
bridge = (src / "main_40c_wilds_210.lua").read_text(encoding="utf-8")
voxel = (src / "main_60a_wilds_210_voxel.lua").read_text(encoding="utf-8")
manifest = (root / "manifest.json").read_text(encoding="utf-8")
errors = []

def check(value, message):
    if not value:
        errors.append(message)

check("main_40c_wilds_210.lua" in parts, "Wilds 2.1 Gen2 bridge missing")
check("main_60a_wilds_210_voxel.lua" in parts, "Wilds 2.1 voxel bridge missing")
check(parts.index("main_40b_gen2_hgss_surf_visual.lua") < parts.index("main_40c_wilds_210.lua") < parts.index("main_41_stadium2_3d.lua"), "Wilds 2.1 bridge load order invalid")
check(parts.index("main_60_gen2_voxel_runtime_compat.lua") < parts.index("main_60a_wilds_210_voxel.lua") < parts.index("main_61_gen2_voxel_single_owner_guard.lua"), "Wilds 2.1 voxel load order invalid")
check('WILDS_ID = "overworld_wild_spawns"' in bridge, "stable Wilds id missing")
check("resolveFollowerSprite" in bridge, "public Wilds sprite API not used")
check('opts.style = "followers"' in bridge, "animated fallback missing")
check('got ~= "water" and got ~= "surfing"' in bridge, "water SpriteDef validation missing")
check("for k, v in pairs(source or {})" in bridge, "SpriteDef metadata copy missing")
check("self.getPoseGeometry" in bridge and "self.resolveImage" in bridge, "variable geometry/palette APIs not used")
check("math.min(16 / fw, 16 / fh, 1)" in bridge, "mount-card normalization missing")
check("logic._startBattle" in bridge and "flight.active == true" in bridge, "airborne Wilds battle gate missing")
check("wilds210Compatibility" in bridge and 'targetRelease = "2.1.0"' in bridge, "Wilds 2.1 diagnostics missing")
check("dramaticSkyRideWilds21" in voxel, "Wilds 2.1 voxel tag missing")
check("frameWidth" in voxel and "frameHeight" in voxel and "anchorX" in voxel and "anchorY" in voxel, "variable voxel geometry missing")
check("local fy = frame * fh" in voxel, "vertical frame UV support missing")
check("local x0 = 8 - ax * scale" in voxel and "local y0 = (ay - fh) * scale" in voxel, "voxel anchor pivot missing")
check("_dramaticSkyRide2DSizeHook" in voxel and "sizeMarker.meshWrapper = meshWrapper" in voxel, "voxel wrapper stability marker missing")
check('"overworld_wild_spawns"' in manifest, "Wilds optional dependency missing")

if errors:
    print("Wilds of Kanto 2.1 Gen2 contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Wilds of Kanto 2.1 Gen2 contract: PASS")
