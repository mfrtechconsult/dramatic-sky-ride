#!/usr/bin/env python3
from pathlib import Path
import base64
import hashlib
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('dramatic_sky_ride')
src = root / 'src'
parts = [p.strip() for p in (src / 'parts.txt').read_text(encoding='utf-8').splitlines() if p.strip()]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

open_parts = [
    'main_53b_gen2_open_sky.lua',
    'main_53c_gen2_open_sky_playable.lua',
    'main_53d_gen2_open_sky_runtime_guard.lua',
    'main_53e_gen2_open_sky_input_latch.lua',
    'main_53f_gen2_open_sky_art_map.lua',
    'main_53g_gen2_open_sky_stadium2_3d.lua',
]
for name in open_parts:
    require(name in parts, f'{name} is not loaded')
if all(name in parts for name in open_parts):
    positions = [parts.index(name) for name in open_parts]
    require(positions == sorted(positions), 'Open Sky modules are not loaded in the expected order')
    require(parts.index(open_parts[-1]) < parts.index('main_54_settings_ux.lua'),
            'Open Sky must be installed before the late settings/runtime bridges')

base = (src / open_parts[0]).read_text(encoding='utf-8')
play = (src / open_parts[1]).read_text(encoding='utf-8')
latch = (src / open_parts[3]).read_text(encoding='utf-8')
art = (src / open_parts[4]).read_text(encoding='utf-8')
three = (src / open_parts[5]).read_text(encoding='utf-8')

require('key = OPEN_SKY_OPTION' in base and 'OPEN_SKY_ENTRY_ALTITUDE = 88' in base
        and 'OPEN_SKY_EXIT_ALTITUDE = 76' in base,
        'Open Sky option or altitude hysteresis changed')
require('generation.isGen2' in base and 'outdoorWorld' in base,
        'Open Sky is no longer constrained to the Gen2 outdoor flight path')
require('OPEN_SKY_FAST_SPEED = 3.4' in play and 'OPEN_SKY_BOOST_SPEED = 5.4' in play,
        'manual Open Sky speed profile changed')
require('local targetSpeed = 0' in play and 'if throttle then targetSpeed = OPEN_SKY_FAST_SPEED end' in play,
        'Open Sky has regained automatic forward movement')
require('input:isDown("b") and throttle' in play and 'input:isDown("down")' in play,
        'boost/brake controls are missing')
require('input:wasPressed("a")' in play and 'self:descendAt(self.nearest)' in play,
        'A landing control is missing')
require('input:wasPressed("b")' not in play,
        'B is incorrectly treated as a cancel press instead of the held boost')
require('OPEN_SKY_TURN_RATE' in play and 'TURNING BACK' in play,
        'manual steering or boundary turnaround is missing')
require('blockedUntilAltitudeNeutral' in latch,
        'held-altitude re-entry latch is missing')
require('MAP_ASSET_PARTS' in art and 'drawOpenSkyWidescreen' in art,
        '2D illustrated fallback map is missing')

require('STADIUM2_OVERWORLD_MODELS' in three,
        'Open Sky 3D provider id changed')
require('MAX_RENDER_W, MAX_RENDER_H = 1920, 1080' in three,
        'Open Sky HD render cap changed')
require('CRUISE_FLIGHT_Y = WORLD_RELIEF + 92' in three
        and 'local wy = CRUISE_FLIGHT_Y + altitudeDelta * ALTITUDE_INPUT_SCALE' in three,
        'Open Sky no longer uses the stable absolute flight level')
pose_block = three[three.find('local function mountWorldPose'):three.find('local function visitedPoints')]
require('local wy = heightAt' not in pose_block and 'local wy = CRUISE_FLIGHT_Y' in pose_block,
        'terrain height is moving the rider again')
require('assets/open_sky_glb/albedo_part01.b64' in three
        and 'assets/open_sky_glb/height_part01.b64' in three,
        'baked GLB assets are not read from the scoped Open Sky package')
require('love.data.decode' in three and 'mod.read' in three,
        'Open Sky GLB asset loader is not using scoped mod reads')
require('sourceModel = "Meshy_AI_map_monde_de_la_regio_0812201706_texture.glb"' in three,
        'Open Sky source model provenance changed')
require('nativeResolution = true' in three,
        'native-resolution 3D pass is not advertised')

# Verify the split package reconstructs the exact baked PNGs used by the final
# launcher-ready Open Sky ZIP. These hashes are over the decoded PNG bytes.
def decode_parts(pattern):
    files = sorted((root / 'assets/open_sky_glb').glob(pattern))
    require(bool(files), f'no asset parts found for {pattern}')
    if not files:
        return b''
    return base64.b64decode(''.join(f.read_text(encoding='ascii').strip() for f in files))

albedo = decode_parts('albedo_part*.b64')
height = decode_parts('height_part*.b64')
require(hashlib.sha256(albedo).hexdigest() == 'b187ac820d1568637f50a74204aa64785c935a7c717358e35f81e13eac501288',
        'Open Sky GLB albedo does not match the validated launcher-ready build')
require(hashlib.sha256(height).hexdigest() == 'b6b85a69bccd1042d59ac7746c5f58c34d86019dda765973d0355348fd4007a5',
        'Open Sky GLB heightfield does not match the validated launcher-ready build')

manifest = (root / 'manifest.json').read_text(encoding='utf-8')
require('"version": "0.2.14"' in manifest, 'candidate version is not 0.2.14')
require('"filesystem"' not in manifest, 'filesystem permission was reintroduced')
require('">=0.1.86 <2.0.0"' in manifest, 'Gen1Recomp 0.1.86+ requirement was lost')

if errors:
    print('Gen2 Open Sky release contract FAILED')
    for error in errors:
        print(' -', error)
    raise SystemExit(1)
print('Gen2 Open Sky release contract: PASS')
