#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
interop = (root / "src" / "main_58_gen2_voxel_interop.lua").read_text(encoding="utf-8")

required = (
    "local function ensureDirectProxy",
    "ow.entities[#ow.entities + 1] = proxy",
    "if entities[i] == proxy then table.remove(entities, i) end",
    'providerMode = "gold-world-entities"',
    "local function syncRuntime",
    "removeLegacyRiders(ow)",
)
missing = [token for token in required if token not in interop]
if missing:
    print("Gen2 provider fallback contract FAILED")
    for token in missing:
        print(" - missing:", token)
    raise SystemExit(1)

print("Gen2 provider fallback contract: PASS")
