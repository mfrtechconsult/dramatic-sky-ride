#!/usr/bin/env python3
from pathlib import Path
import sys


root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [
    line.strip()
    for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
name = "main_53b_gen2_open_sky.lua"
text = (src / name).read_text(encoding="utf-8")
settings_name = "main_54_settings_ux.lua"

errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require(name in parts, "the Gen2 Open Sky layer is not loaded")
require(settings_name in parts and parts.index(name) < parts.index(settings_name),
        "Open Sky options must be registered before the settings UX snapshots the schema")
require('key = OPEN_SKY_OPTION' in text and 'default = false' in text,
        "Regional Soaring must remain explicitly opt-in while experimental")
require('OPEN_SKY_ENTRY_ALTITUDE = 88' in text,
        "Open Sky entry altitude drifted from the prototype contract")
require('OPEN_SKY_EXIT_ALTITUDE = 76' in text,
        "Open Sky needs hysteresis below its entry altitude")
require('Game.data.gen2Landmarks' in text and 'record.x' in text and 'record.y' in text,
        "Open Sky does not build its regional atlas from Gen2 landmark coordinates")
require('src.core.gen2.Nests' in text and 'regionOf' in text,
        "Open Sky is not using Gen2's Johto/Kanto landmark split")
require('src.world.gen2.FieldMoves' in text and 'hasVisitedSpawn' in text
        and 'SPAWN_INDIGO' in text,
        "Kanto soaring is not tied to Gold's existing Indigo discovery gate")
require('flight.active and flight.phase == "cruise"' in text,
        "Open Sky can activate outside normal DSR cruise flight")
require('Map2' in text and 'isOutdoor' in text,
        "Open Sky does not restrict automatic activation to outdoor Gen2 maps")
require('altitude <= OPEN_SKY_EXIT_ALTITUDE' in text,
        "Open Sky does not leave cleanly after descending through the hysteresis floor")
require('mod.exports.openSky' in text and 'atlas = buildAtlas' in text
        and 'currentAnchor = currentAnchor' in text,
        "future renderer/navigation layers have no stable Open Sky API")
require('local previousOpenSkyUpdate = OverworldState.update' in text,
        "Open Sky is not observing the mature flight update chain")
require('self:setMap(' not in text and ':setMap(' not in text,
        "Stage 1 must not teleport or replace Gold map traversal yet")
require('flight.requestedAltitude =' not in text,
        "Stage 1 must not take ownership of normal DSR altitude control")

if errors:
    print("Gen2 Open Sky contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 Open Sky contract: PASS")
