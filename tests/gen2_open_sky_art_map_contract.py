#!/usr/bin/env python3
from pathlib import Path
import base64, sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('dramatic_sky_ride')
src = root / 'src'
parts = [line.strip() for line in (src / 'parts.txt').read_text(encoding='utf-8').splitlines() if line.strip()]
name = 'main_53f_gen2_open_sky_art_map.lua'
text = (src / name).read_text(encoding='utf-8')
# Strip Lua line comments before assertions that target executable calls.
code_only = '\n'.join(line.split('--', 1)[0] for line in text.splitlines())
asset_parts = [root/'assets'/'open_sky_map'/name for name in ('part01.b64','part02.b64','part03a.b64','part03b.b64','part04.b64')]
errors=[]
def require(c,m):
    if not c: errors.append(m)
require(name in parts, 'illustrated Open Sky map layer is not loaded')
require('main_53e_gen2_open_sky_input_latch.lua' in parts and parts.index('main_53e_gen2_open_sky_input_latch.lua') < parts.index(name), 'illustrated map must load after runtime/input safety layers')
three_d = 'main_53g_gen2_open_sky_stadium2_3d.lua'
require(three_d in parts and parts.index(name) < parts.index(three_d), 'optional 3D overlay must load after the safe 2D widescreen renderer')
require(all(p.exists() for p in asset_parts), 'Open Sky regional artwork fragments are missing')
if all(p.exists() for p in asset_parts):
    try:
        encoded=''.join(p.read_text(encoding='ascii').strip() for p in asset_parts)
        raw=base64.b64decode(encoded, validate=True)
        require(raw.startswith(b'\xff\xd8\xff'), 'Open Sky artwork is not a JPEG')
        require(raw.endswith(b'\xff\xd9'), 'Open Sky artwork JPEG is truncated')
        require(len(raw)>8000, 'Open Sky artwork unexpectedly small')
    except Exception as exc:
        errors.append(f'Open Sky artwork fragments cannot be decoded: {exc}')
require('MAP_ASSET_PARTS' in text and 'love.data.decode' in text, 'Open Sky does not reconstruct the packaged artwork fragments')
require('openSkyMapImage = loadMapImage' in text, 'Open Sky does not expose its decoded image for optional 3D rendering')
require('REGION_RECT' in text and 'project(state.region' in text, 'Gold regional coordinates are not projected onto artwork')
require('visitedPoints(state.region)' in text, 'landing markers are no longer driven by visited Fly Points')
require('flight.sprite' in text and 'sprite.draw' in text, 'moving icon is not the active DSR mount sprite')
require('state.drawsWidescreen = function() return true end' in text, 'Open Sky is not opting into Gold native widescreen rendering')
require('state.drawWidescreen = function' in text and 'drawWidescreen(self, winW, winH)' in text, 'Open Sky does not provide the widescreen renderer Game2 calls directly')
require('state.wantsFillScale = function() return true end' in text, 'Open Sky widescreen state does not request Gold full-page scaling')
require('emergencyWidescreen' in text, 'Open Sky has no primitive-only emergency widescreen renderer')
require('local fallback = state.draw' in text and 'pcall(fallback, self)' in text, 'nested-state draw does not preserve the safe renderer fallback')
require('G.clear(' not in code_only, 'Open Sky 2D should not erase the active Game2 presentation canvas')
require('lastIllustratedDrawError' in text, 'illustrated draw failures are not exposed for diagnostics')
require('_dsrOpenSky2DWidescreen = true' in text, '2D renderer does not expose the safe-base marker used by optional overlays')
if errors:
    print('Gen2 Open Sky illustrated map contract FAILED')
    for e in errors: print(' -',e)
    raise SystemExit(1)
print('Gen2 Open Sky illustrated map contract: PASS')
