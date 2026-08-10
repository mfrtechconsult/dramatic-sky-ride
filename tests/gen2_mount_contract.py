#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
gen2 = (src / "main_33_gen2_mounts.lua").read_text(encoding="utf-8")
surf = (src / "main_17_polish_03.lua").read_text(encoding="utf-8")
stadium = (src / "main_28_stadium_compat.lua").read_text(encoding="utf-8")
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]

errors = []
def require(condition, message):
    if not condition:
        errors.append(message)

flight = {
    "NOCTOWL": 164, "CROBAT": 169, "XATU": 178,
    "SKARMORY": 227, "LUGIA": 249, "HO_OH": 250,
}
ground = {
    "MEGANIUM": 154, "GIRAFARIG": 203, "URSARING": 217,
    "DONPHAN": 232, "STANTLER": 234, "RAIKOU": 243,
    "ENTEI": 244, "SUICUNE": 245, "TYRANITAR": 248,
}
surf_mounts = {
    "FERALIGATR": 160, "MANTINE": 226, "KINGDRA": 230, "LUGIA": 249,
}

for species, dex in flight.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", gen2) is not None,
            f"missing Gen2 flight mount {species} #{dex}")
for species, dex in ground.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", gen2) is not None,
            f"missing Gen2 ground mount {species} #{dex}")
for species, dex in surf_mounts.items():
    require(re.search(rf"\b{species}\b\s*=\s*\{{[^\n]*dex\s*=\s*{dex}\b", surf) is not None,
            f"missing Gen2 visible Surf mount {species} #{dex}")

# Suicune is deliberately unique: Ground Ride owns both land and water visuals.
require("SUICUNE" not in re.search(r"local WATER_ELIGIBLE\s*=\s*\{(.*?)\n\}", surf, re.S).group(1),
        "Suicune must not become a normal visible-Surf mount")
require('SUICUNE   = { dex = 245' in gen2 and 'amphibious = true' in gen2,
        "Suicune amphibious Ground Ride profile missing")
require('partyKnows, ow, "SURF"' in gen2,
        "Suicune water running must preserve normal Surf progression")
require("Game.save.forcedBike" in gen2 and "surfBlockedHere" in gen2,
        "Suicune water running must preserve vanilla Surf restrictions")
require("setSuicuneWaterState(self, true)" in gen2,
        "Suicune must arm native water collision before movement")
require("Map.defIsWaterCell(dest, ts, x, y)" in gen2,
        "Suicune must handle water landings across map connections")
require("suicuneBattleWaterResume" in gen2,
        "Suicune water battle remount continuity missing")
require("amphibiousGroundOwnsWaterVisual" in (src / "main_17_polish_04.lua").read_text(encoding="utf-8"),
        "visible Surf must yield visual ownership to amphibious Suicune")

# The Wilds self-healing guard must capture the Gen2 update wrapper too.
require(parts.index("main_33_gen2_mounts.lua") < parts.index("main_27_wilds_compat.lua"),
        "Gen2 wrapper must load before the DSR update-chain guard")

# Current Stadium 1 models are Gen1 only unless a provider explicitly advertises more.
require("supportsSpecies" in stadium and "hasModel" in stadium and "modelAvailable" in stadium,
        "Stadium capability-based species probe missing")
require("dex >= 1 and dex <= 151" in stadium,
        "Gen2 Stadium fallback to the 2D billboard is missing")

if errors:
    print("Generation II mount contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Generation II mount contract: PASS")
