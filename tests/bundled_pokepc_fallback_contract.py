#!/usr/bin/env python3
from pathlib import Path
import struct
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
assets = root / "assets" / "pokepc_followers"
src = root / "src"
errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


files = sorted(assets.glob("follower_*.png"))
expected = [f"follower_{dex_number:03d}.png" for dex_number in range(1, 252)]
require([path.name for path in files] == expected,
        "bundled fallback must contain exactly follower_001..251.png")

for path in files:
    data = path.read_bytes()
    valid = len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n"
    if valid:
        width, height = struct.unpack(">II", data[16:24])
        valid = (width, height) == (16, 96)
    require(valid, f"invalid 16x96 six-frame walker sheet: {path.name}")

resolver = (src / "main_13c_bundled_pokepc_fallback.lua").read_text(encoding="utf-8")
parts = [line.strip() for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines()]
require("mod.exports.bundledFollowerSprites" in resolver,
        "bundled fallback export is missing")
require("mod.read" in resolver and "mod.assets.path" in resolver,
        "bundled fallback is not rooted through sandbox-safe mod APIs")
for forbidden in ("io.open", "love.filesystem", "mod.path"):
    require(forbidden not in resolver, f"sandbox-unsafe resolver token: {forbidden}")
require(parts.index("main_13c_bundled_pokepc_fallback.lua")
        < parts.index("main_15_ground.lua"),
        "bundled fallback must load before ground and provider wrappers")

for filename in ("main_03.lua", "main_15_ground.lua"):
    text = (src / filename).read_text(encoding="utf-8")
    require("bundledFollowerSprites" in text,
            f"{filename} does not consume the bundled fallback")

require((root / "THIRD_PARTY_NOTICES.md").is_file(),
        "PokePC asset attribution notice is missing")

if errors:
    print("Bundled PokePC fallback contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Bundled PokePC fallback contract: PASS")
