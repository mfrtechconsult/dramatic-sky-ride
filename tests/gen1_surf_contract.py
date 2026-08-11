#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else "dramatic_sky_ride")
src = root / "src"
parts = [line.strip() for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if line.strip()]
visible = (src / "main_17_polish_03.lua").read_text(encoding="utf-8")
runtime = (src / "main_26b_gen1_surf_runtime.lua").read_text(encoding="utf-8")


def require(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")
    print(f"ok - {message}")


require('if w ~= 16 or h ~= 96 then' in visible,
        "Visible Surf rejects non-canonical provider sheets")
require('dex = dex' in visible,
        "Visible Surf resolves provider sprites with National Dex context")
require('{ surface = "water" }' in visible and '{ surface = "land"' in visible,
        "Visible Surf has water then canonical land-provider fallback")
require(visible.index('local path = genericFollowerPath(cfg)') < visible.index('local provided, reason = publicWaterMountSprite(species)'),
        "stable dex follower asset is preferred before provider visual modes")
require('generation.isGen1' in runtime and 'free.drop' in runtime,
        "Gen1 Surf transition drops stale FreeMove position")
require('player.bumpFrames = nil' in runtime and 'not player.inputLocked' in runtime,
        "Surf hotfix clears only idle movement cosmetics")
require(parts.index("main_26_surf_third_person.lua") < parts.index("main_26b_gen1_surf_runtime.lua") < parts.index("main_14.lua"),
        "Gen1 Surf transition bridge loads after Surf camera compatibility")

print("Gen1 Surf hotfix contract: PASS")
