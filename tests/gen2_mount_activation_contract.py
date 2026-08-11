#!/usr/bin/env python3
from pathlib import Path
import sys


root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"

base = (src / "main_01.lua").read_text(encoding="utf-8")
flight = (src / "main_10_01.lua").read_text(encoding="utf-8")
flight_shortcut = (src / "main_13a.lua").read_text(encoding="utf-8")
flight_menu = (src / "main_12b.lua").read_text(encoding="utf-8")
ground = (src / "main_15_ground.lua").read_text(encoding="utf-8")
mount_menu = (src / "main_17_polish_04.lua").read_text(encoding="utf-8")
gen2 = (src / "main_33_gen2_mounts.lua").read_text(encoding="utf-8")

errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require("mod.exports._mountWorld = function" in base
        and "return game.overworld or game.world" in base,
        "mount callbacks must normalize Game and Game2 world fields")
require("world.acceptsMenuInput" in base,
        "Gold free-roam must use the native idle-world gate")
require("type(stack.clear)" in base and "stack:clear()" in base,
        "Gold field actions must close Party/Mount and START screens")

require("mod.exports._mountFreeRoam(game, ow)" in flight,
        "flight activation still uses the Gen1-only stack gate")
require("mod.exports._mountFreeRoam(game, ow)" in flight_shortcut,
        "flight shortcut still uses the Gen1-only stack gate")
require(ground.count("mod.exports._mountFreeRoam(game, ow)") >= 2,
        "ground menu/shortcut paths must share the Gold free-roam gate")
require("mod.exports._closeMountMenus(liveGame)" in flight_menu,
        "party flight action must exit the full Gold menu stack")
require("mod.exports._closeMountMenus(liveGame)" in ground,
        "party ground action must exit the full Gold menu stack")
require("mod.exports._closeMountMenus(game)" in mount_menu,
        "unified mount menu must exit the Gold START menu")

require('type(ex.assetPath) == "function"' in gen2,
        "PokePCFollowers 0.8 assetPath API is not supported")
require("w >= 16 and h >= 96" in gen2,
        "PokePC mount sheets must be validated before use")

if errors:
    print("Gen2 mount activation contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 mount activation contract: PASS")
