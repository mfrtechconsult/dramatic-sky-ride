#!/usr/bin/env python3
from pathlib import Path
import json, struct, sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('dramatic_sky_ride')
src = root / 'src'
parts = [line.strip() for line in (src / 'parts.txt').read_text(encoding='utf-8').splitlines() if line.strip()]
name='main_53g_gen2_open_sky_stadium2_3d.lua'
text=(src/name).read_text(encoding='utf-8') if (src/name).exists() else ''
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
height=root/'assets'/'open_sky_region_height.png'
tex=root/'assets'/'open_sky_region_map.jpg'
errors=[]
def require(c,m):
    if not c: errors.append(m)
require(name in parts, 'Gen2 Open Sky 3D bridge is not loaded')
require('main_53f_gen2_open_sky_art_map.lua' in parts and name in parts and parts.index('main_53f_gen2_open_sky_art_map.lua') < parts.index(name), '3D bridge must load after 2D illustrated fallback')
require('STADIUM2_OVERWORLD_MODELS' in manifest.get('optional_dependencies',[]), 'Gen2-3D-Sprites mod id is not an optional dependency')
require('PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"' in text, 'bridge does not detect randyadr Gen2-3D-Sprites by its manifest id')
require('exports.lib.require' in text and '"Voxel3D"' in text and '"Mat4"' in text, 'bridge does not use Gen2-3D-Sprites public renderer library export')
require('Voxel3D.beginScene' in text and 'Voxel3D.draw' in text and 'Voxel3D.project' in text, 'bridge does not render/project through Gen2-3D-Sprites Voxel3D')
require('Voxel3D.newMesh' in text and 'love.image.newImageData' in text, 'Meshy height map is not rebuilt as a compact Voxel3D mesh')
require('Voxel3D.seams(false)' in text, 'non-voxel Meshy terrain is not protected from voxel-grid seam shader')
require('fallbackDraw' in text, '3D renderer has no safe 2D fallback')
require('flight.sprite' in text and 'sprite.draw' in text, '3D view does not keep the selected flight mount miniature')
require('visitedPoints(state.region)' in text and 'projectWorld' in text, '3D landing beacons are not driven by real Gold Fly Points')
require(height.exists(), 'optimized Meshy-derived Open Sky height map is missing')
require(tex.exists(), 'Open Sky 3D texture asset is missing')
if height.exists():
    raw=height.read_bytes()
    require(raw.startswith(b'\x89PNG\r\n\x1a\n'), 'Open Sky 3D height map is not PNG')
    if len(raw) >= 24 and raw[12:16] == b'IHDR':
        w,h=struct.unpack('>II',raw[16:24])
        require((w,h)==(128,99), f'Open Sky height map expected 128x99, got {w}x{h}')
if tex.exists():
    raw=tex.read_bytes()
    require(raw.startswith(b'\xff\xd8\xff') and raw.endswith(b'\xff\xd9'), 'Open Sky 3D texture is not a complete JPEG')
if errors:
    print('Gen2 Open Sky Gen2-3D-Sprites contract FAILED')
    for e in errors: print(' -',e)
    raise SystemExit(1)
print('Gen2 Open Sky Gen2-3D-Sprites contract: PASS')
