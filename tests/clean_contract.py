from pathlib import Path
import json
import re

root = Path(__file__).parents[1]
mod = root / "dramatic_sky_ride"
src = mod / "src"
manifest = json.loads((mod / "manifest.json").read_text(encoding="utf-8"))

assert manifest["api"] == 2
assert set(manifest["games"]) == {"gen1", "gen2"}
assert manifest["version"].startswith("0.3.0")
assert "engine_internals" in manifest.get("permissions", [])
assert "filesystem" not in manifest.get("permissions", [])
assert not list(src.glob("main_*.lua")), "legacy layered runtime must stay deleted"
assert not (src / "parts.txt").exists(), "legacy parts loader must stay deleted"

text = "\n".join(p.read_text(encoding="utf-8") for p in src.glob("*.lua"))
for hook in ["movement.collision", "movement.speed", "core.update", "ui.party.submenu"]:
    assert hook in text, hook

catalog = (src / "catalog.lua").read_text(encoding="utf-8")
for feature in ["flight", "ground", "surf"]:
    assert feature in catalog.lower()
for species in ["CHARIZARD", "HO_OH", "ARCANINE", "SUICUNE", "LAPRAS", "LUGIA"]:
    assert species in catalog, species
assert len(re.findall(r'\{"[A-Z0-9_]+",\d+', catalog)) == 41

sprites = (src / "sprites.lua").read_text(encoding="utf-8")
assert "resolveFollowerSprite" in sprites
assert "STADIUM2_OVERWORLD_MODELS" in sprites
assert "bundled_pokepc" in sprites

compat = (src / "compat.lua").read_text(encoding="utf-8")
assert "mod.world.current" not in compat
assert "mod.world.overworld" in compat
assert 'state == "surf" or state == "surf_pika"' in compat

runtime = (src / "runtime.lua").read_text(encoding="utf-8")
assert "mountSprite" in runtime
assert "native surf started" in runtime
assert "start Surf through the game first" in runtime

assert any("wild_skies" in x for x in manifest["optional_dependencies"])
assert any("CRYSTAL_251" in x for x in manifest["optional_dependencies"])
print("clean-contract-ok")
