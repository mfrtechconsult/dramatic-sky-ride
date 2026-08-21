from pathlib import Path
import json
root=Path(__file__).parents[1]
mod=root/'dramatic_sky_ride'
manifest=json.loads((mod/'manifest.json').read_text())
assert manifest['api']==2
assert set(manifest['games'])=={'gen1','gen2'}
assert manifest['version'].startswith('0.3.0')
text='\n'.join(p.read_text() for p in (mod/'src').glob('*.lua'))
for hook in ['movement.collision','movement.speed','core.update','ui.party.submenu']:
    assert hook in text
for feature in ['flight','ground','surf']:
    assert feature in (mod/'src/catalog.lua').read_text().lower()
assert 'resolveFollowerSprite' in (mod/'src/sprites.lua').read_text()
assert 'STADIUM2_OVERWORLD_MODELS' in (mod/'src/sprites.lua').read_text()
assert any('wild_skies' in x for x in manifest['optional_dependencies'])
assert any('CRYSTAL_251' in x for x in manifest['optional_dependencies'])
print('clean contract ok')
