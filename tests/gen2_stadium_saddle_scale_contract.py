#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
interop = (root / "src" / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")

errors = []
def require(cond, message):
    if not cond:
        errors.append(message)

require("stadiumSeatFraction" in interop,
        "Stadium Flight scaling has no provider saddle model")
require("seatDelta = -(wanted - current) * stadiumSeatFraction(p.stadiumDex)" in interop,
        "Flight model scale is not compensated around the provider saddle point")
require("M.mul(M.translate(0, seatDelta, 0), scaled)" in interop,
        "saddle compensation is not applied as a world-space vertical translation")
require('if kind == "flight"' in interop,
        "saddle compensation is not restricted to Flight")
require("p.dramaticSkyRideSeatScaleDelta = seatDelta" in interop,
        "runtime does not expose the applied saddle correction for diagnosis")
require("seatScaleFrames" in interop and "seatScaleDelta" in interop,
        "interop status does not expose saddle correction telemetry")
require("STADIUM_SEAT_TRIM" not in interop,
        "per-species rider trim must not replace the common saddle correction")

if errors:
    print("Gen2 Stadium saddle scale contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Gen2 Stadium saddle scale contract: PASS")
