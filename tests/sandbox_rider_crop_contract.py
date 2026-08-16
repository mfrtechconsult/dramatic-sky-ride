#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
builder = (src / "main_05.lua").read_text(encoding="utf-8")
flight = (src / "main_06.lua").read_text(encoding="utf-8")
otf = (src / "main_37_otf_player_switcher.lua").read_text(encoding="utf-8")
owner = (src / "main_61_gen2_voxel_single_owner_guard.lua").read_text(
    encoding="utf-8")
water = (src / "main_17_polish_03.lua").read_text(encoding="utf-8")
all_source = "\n".join(
    path.read_text(encoding="utf-8") for path in src.glob("*.lua"))

errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require("buildInMemoryRiderSprite" in builder,
        "sandbox rider crop builder is missing")
require("love.graphics.newQuad" in builder
        and "sourceFrame * 16" in builder
        and "RIDER_CROP_HEIGHT" in builder,
        "rider crop does not retain the 16px source stride and 13px crop")
require("sprite.anchorY = (tonumber(sourceDef.anchorY) or 16) - RIDER_CROP_Y"
        in builder,
        "in-memory crop does not preserve the old seated output offset")
require("dramaticSkyRideRiderCrop = true" in builder
        and "dramaticSkyRideRiderSourceFrames" in builder,
        "provider-visible rider crop metadata is missing")
require("buildInMemoryRiderSprite(sourceSprite)" in flight,
        "ordinary riders do not use the sandbox-safe crop")
require("buildInMemoryRiderSprite(\n      sourceSprite, proxyDef" in otf,
        "OTF Player Switcher riders do not use the sandbox-safe crop")
require("uncropped_fallback" not in all_source,
        "a full standing-trainer mount fallback is still reachable")
require("local function riderCropMesh" in owner
        and "cardBottom = 16 - outputY - cropHeight" in owner
        and "cardTop = 16 - outputY" in owner,
        "provider billboard crop does not reproduce the old transparent sheet rows")
require("if isRiderCropDef(def) then" in owner
        and "croppedRiderBillboards" in owner,
        "solid/shadow provider draws are not routed through rider cropping")
require('"bundled_pokepc_fallback"' in water,
        "Visible Surf has no bundled fallback when providers are unavailable")

if errors:
    print("Sandbox rider crop contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Sandbox rider crop contract: PASS")
