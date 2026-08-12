#!/usr/bin/env python3
from pathlib import Path
import base64
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [line.strip() for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if line.strip()]
name = "main_53f_gen2_open_sky_art_map.lua"
text = (src / name).read_text(encoding="utf-8")
asset = root / "assets" / "open_sky_region_map.jpg.b64"

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

require(name in parts, "illustrated Open Sky map layer is not loaded")
require("main_53e_gen2_open_sky_input_latch.lua" in parts and
        parts.index("main_53e_gen2_open_sky_input_latch.lua") < parts.index(name),
        "illustrated map must load after the runtime/input safety layers")
require(asset.exists(), "Open Sky regional artwork asset is missing")
if asset.exists():
    try:
        raw = base64.b64decode(asset.read_text(encoding="ascii"), validate=True)
        require(raw.startswith(b"\xff\xd8\xff"), "Open Sky artwork is not a JPEG")
        require(raw.endswith(b"\xff\xd9"), "Open Sky artwork JPEG is truncated")
        # The runtime renders the art into roughly a 160x90 panel, so the
        # deliberately optimized source JPEG can remain compact without losing
        # visible detail. This floor catches empty/place-holder files only.
        require(len(raw) > 4000, "Open Sky artwork unexpectedly small")
    except Exception as exc:
        errors.append(f"Open Sky artwork Base64 cannot be decoded: {exc}")

require('mod:read(MAP_ASSET)' in text,
        "Open Sky artwork is not loaded through the mod filesystem")
require('REGION_RECT' in text and 'project(state.region' in text,
        "Open Sky does not project Gold regional coordinates onto the artwork")
require('visitedPoints(state.region)' in text,
        "landing markers are no longer driven by Gold visited Fly Points")
require('flight.sprite' in text and 'sprite.draw' in text,
        "Open Sky moving icon is not the active DSR mount sprite")
require('cleanMapName' in text and 'state.nearest.row' in text,
        "Open Sky labels are not sourced from real Gold landmark/fly-point data")

if errors:
    print("Gen2 Open Sky illustrated map contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 Open Sky illustrated map contract: PASS")
