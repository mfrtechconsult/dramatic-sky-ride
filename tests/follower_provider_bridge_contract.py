#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
compat = (root / "src" / "main_27_wilds_compat.lua").read_text(encoding="utf-8")

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

require('"PokePCFollowers_VoxelMerge"' in compat and '"pokepcfollowers"' in compat,
        "PokéPC current and legacy ids must remain provider candidates")
require('"FOLLOWERS_EX"' in compat and '"followers_ex"' in compat,
        "Followers EX aliases must remain compatibility candidates")
require('type(ex.resolveFollowerSprite) == "function"' in compat,
        "modern providers must use resolveFollowerSprite")
require('type(ex.assetPath) == "function"' in compat,
        "legacy providers must retain the sandbox-safe assetPath fallback")
require('pcall(ex.assetPath, species)' in compat,
        "assetPath fallback must be called only through provider exports")
require('provided.walker ~= false' in compat and 'width < 16 or height < 96' in compat,
        "all provider results must retain walker-sheet validation")
require('usableProviderDefinition(id, ex, species, role, "followers")' in compat,
        "Wilds must retain its dedicated followers-style fallback")
require(compat.index('usableProviderDefinition(id, ex, species, role, "followers")')
        < compat.index('usableLegacyProviderDefinition(id, ex, species)'),
        "Wilds canonical style fallback must outrank the legacy provider seam")
require('love.filesystem' not in compat,
        "provider compatibility must not restore raw cross-mod filesystem access")
require('local legacySyncFollowerMods = syncFollowerMods' in compat,
        "follower lifecycle synchronization chain must remain intact")

if errors:
    print("Follower provider bridge contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Follower provider bridge contract: PASS")
