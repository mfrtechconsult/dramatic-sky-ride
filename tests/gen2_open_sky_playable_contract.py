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
base_name = "main_53b_gen2_open_sky.lua"
name = "main_53c_gen2_open_sky_playable.lua"
text = (src / name).read_text(encoding="utf-8")

errors = []


def require(condition, message):
    if not condition:
        errors.append(message)


require(name in parts, "the playable Gen2 Open Sky layer is not loaded")
require(base_name in parts and parts.index(base_name) < parts.index(name),
        "the playable layer must load after the Open Sky state contract")
require('OpenSkyState.isOpaque = true' in text,
        "Open Sky must freeze and visually replace the local overworld while navigating")
require('input:isDown("right")' in text and 'input:isDown("left")' in text
        and 'input:isDown("up")' in text and 'input:isDown("down")' in text,
        "Open Sky does not provide free directional regional navigation")
require('altitudeInputDirection' in text and 'OPEN_SKY_EXIT_ALTITUDE' in text,
        "DSR altitude controls cannot descend back out of Open Sky")
require('FieldMoves.flyPoints' in text,
        "Open Sky landing points are not derived from Gold's visited Fly Points")
require('OPEN_SKY_LAND_RADIUS' in text and 'nearestVisited' in text,
        "Open Sky has no proximity-based landing selection")
require('world.landmarks.spawns' in text and 'world.setMap' in text,
        "regional descent cannot resolve a visited spawn back into the local world")
require('World:flyTo()' in text and 'flight.phase = "cruise"' in text,
        "Open Sky must re-enter DSR flight instead of ending in vanilla Fly")
require('flight.originMap = spawn.map' in text,
        "emergency landing origin is stale after regional travel")
require('flight.originSurf = false' in text,
        "regional travel can incorrectly restore the pre-soaring Surf state")
require('self.region == "johto" and nx > MAP_MAX_X' in text
        and 'self:setRegion("kanto"' in text,
        "Johto cannot transition into Kanto airspace")
require('self:kantoUnlocked()' in text and 'KANTO IS NOT UNLOCKED YET' in text,
        "Kanto airspace ignores the existing progression gate")
require('self.region == "kanto" and nx < MAP_MIN_X' in text
        and 'self:setRegion("johto"' in text,
        "Kanto cannot transition back into Johto airspace")
require('gear.gfx.maps[self.region]' in text and 'gear.drawTilemap' in text,
        "Open Sky is not reusing Gold's native Johto/Kanto town-map art")
require('flight.sprite' in text and 'sprite.draw' in text,
        "the selected DSR flying Pokemon is not represented in Open Sky")
require('input:wasPressed("a")' in text and 'self:descendAt' in text,
        "A cannot initiate a regional descent")
require('input:wasPressed("b")' in text and 'self:returnToLocal' in text,
        "B cannot safely return to local flight")
require('top ~= nil then return' in text,
        "Open Sky can cover a dialogue/menu/cutscene")
require('mod.exports.openSkyPlayable' in text,
        "the playable Open Sky layer exposes no diagnostics/API")

if errors:
    print("Gen2 Open Sky playable contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 Open Sky playable contract: PASS")
