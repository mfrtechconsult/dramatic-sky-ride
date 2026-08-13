#!/usr/bin/env python3
from pathlib import Path
import base64, json, struct, sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('dramatic_sky_ride')
src = root / 'src'
parts = [line.strip() for line in (src/'parts.txt').read_text(encoding='utf-8').splitlines() if line.strip()]
name = 'main_53g_gen2_open_sky_stadium2_3d.lua'
text = (src/name).read_text(encoding='utf-8')
code_only = '\n'.join(line.split('--', 1)[0] for line in text.splitlines())
manifest = json.loads((root/'manifest.json').read_text(encoding='utf-8'))
height = root/'assets'/'open_sky_region_height.png'
texparts = [root/'assets'/'open_sky_map'/n for n in ('part01.b64','part02.b64','part03a.b64','part03b.b64','part04.b64')]
errors=[]
def require(c,m):
    if not c: errors.append(m)

require(name in parts, 'Gen2 Open Sky 3D bridge is not loaded')
require('main_53f_gen2_open_sky_art_map.lua' in parts and parts.index('main_53f_gen2_open_sky_art_map.lua') < parts.index(name), '3D overlay must load after safe 2D widescreen')
require('STADIUM2_OVERWORLD_MODELS' in manifest.get('optional_dependencies', []), 'Gen2-3D-Sprites is not an optional dependency')
require('PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"' in text, 'wrong Gen2-3D-Sprites provider id')
require('ex.lib.require' in text and '"Voxel3D"' in text, 'public Voxel3D export is not used')
require('rendererInstalled' not in code_only and 'voxelStatus' not in code_only, 'Open Sky 3D incorrectly gates on the overworld compositor')
require('type(ex.lib) ~= "table"' in text and 'type(ex.lib.require) ~= "function"' in text, 'provider capability is not based on public renderer library')
require('Voxel3D.available' in text, 'GPU renderer capability is not checked')
require('Voxel3D.newMesh' in text and 'love.image.newImageData' in text, 'Meshy heightfield is not rebuilt into Voxel3D mesh')
require('buildFlatTerrain' in text, '3D path has no flat proof/fallback mesh')
require('Voxel3D.beginScene' in text and 'Voxel3D.endScene' in text and 'Voxel3D.draw' in text, 'Voxel3D scene pipeline is incomplete')
require('G.getCanvas' in text and 'restoreTarget' in text, 'Gold presentation target is not restored after Voxel3D.endScene')
require(text.index('restoreTarget(G, target)') < text.index('G.draw(canvas, 0, 0)'), '3D canvas is composited before Gold target restoration')
require('local fallback = state.drawWidescreen' in text and 'pcall(fallback, self, winW, winH)' in text, '2D widescreen is not the permanent base layer')
require('state.draw=function' not in code_only.replace(' ', ''), '3D overlay must not replace normal state.draw')
require('G.clear(' not in code_only, '3D overlay must not clear the visible Game2 frame')
require('cameraFor(state)' in text and 'CHASE_DISTANCE' in text and 'LOOK_AHEAD' in text, '3D camera is not a mount-follow chase camera')
require('updateNavigation' in text and 'CAMERA_TURN_RATE' in text and 'targetHeading' in text, '3D movement does not steer the chase camera')
require('mountWorld(state)' in text and 'heightAt(wx, wz)' in text, 'mount does not actually travel over terrain height')
require('state._dsrOpenSky3DNavigation = true' in text, 'Open Sky state is not marked as navigable 3D')
require('G.draw(canvas, 0, 0)' in text, '3D scene is not presented as the full soaring viewport')
require('3D NAV' in text and 'drawNavigationHud' in text, 'navigable 3D HUD marker is missing')
require('stage = function() return cache.stage end' in text, '3D diagnostic stage is not exported')
require('flight.sprite' in text and 'sprite.draw' in text, '3D marker does not use current flight mount')
require('G.circle("line", x, y, 5' not in text and 'G.circle("line", x, y, 6' not in text, 'white mount selection ring returned in 3D')
require('visitedPoints(state.region)' in text and 'worldPoint' in text, '3D Fly Points are not projected from real Gold data')
require(height.exists(), 'Meshy-derived Open Sky height map is missing')
require(all(p.exists() for p in texparts), 'Open Sky map texture fragments are missing')
if height.exists():
    raw=height.read_bytes()
    require(raw.startswith(b'\x89PNG\r\n\x1a\n'), 'Open Sky height map is not PNG')
    if len(raw) >= 24 and raw[12:16] == b'IHDR':
        w,h=struct.unpack('>II', raw[16:24])
        require((w,h)==(128,99), f'Open Sky height map expected 128x99, got {w}x{h}')
if all(p.exists() for p in texparts):
    raw=base64.b64decode(''.join(p.read_text(encoding='ascii').strip() for p in texparts), validate=True)
    require(raw.startswith(b'\xff\xd8\xff') and raw.endswith(b'\xff\xd9'), 'Open Sky texture JPEG is invalid')

if errors:
    print('Gen2 Open Sky navigable Gen2-3D-Sprites contract FAILED')
    for e in errors: print(' -', e)
    raise SystemExit(1)
print('Gen2 Open Sky navigable Gen2-3D-Sprites contract: PASS')
