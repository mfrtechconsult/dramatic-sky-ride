#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('dramatic_sky_ride')
src = root / 'src'
parts = [line.strip() for line in (src / 'parts.txt').read_text(encoding='utf-8').splitlines() if line.strip()]
name = 'main_53f_gen2_open_sky_art_map.lua'
text = (src / name).read_text(encoding='utf-8')
asset = root / 'assets' / 'open_sky_region_map.jpg'
errors=[]
def require(c,m):
    if not c: errors.append(m)
require(name in parts, 'illustrated Open Sky map layer is not loaded')
require('main_53e_gen2_open_sky_input_latch.lua' in parts and parts.index('main_53e_gen2_open_sky_input_latch.lua') < parts.index(name), 'illustrated map must load after runtime/input safety layers')
require(asset.exists(), 'Open Sky regional artwork asset is missing')
if asset.exists():
    raw=asset.read_bytes()
    require(raw.startswith(b'\xff\xd8\xff'), 'Open Sky artwork is not a JPEG')
    require(raw.endswith(b'\xff\xd9'), 'Open Sky artwork JPEG is truncated')
    # Native Open Sky renders at 160 px wide; a 320 px optimized source is
    # intentionally compact while retaining 2x source resolution.
    require(len(raw)>8000, 'Open Sky artwork unexpectedly small')
require('MAP_ASSET = "assets/open_sky_region_map.jpg"' in text, 'Open Sky does not reference the packaged JPG')
require('mod.read' in text and 'newFileData' in text, 'Open Sky artwork lacks package-read fallback')
require('REGION_RECT' in text and 'project(state.region' in text, 'Gold regional coordinates are not projected onto artwork')
require('visitedPoints(state.region)' in text, 'landing markers are no longer driven by visited Fly Points')
require('flight.sprite' in text and 'sprite.draw' in text, 'moving icon is not the active DSR mount sprite')
if errors:
    print('Gen2 Open Sky illustrated map contract FAILED')
    for e in errors: print(' -',e)
    raise SystemExit(1)
print('Gen2 Open Sky illustrated map contract: PASS')
