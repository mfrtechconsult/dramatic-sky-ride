#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
embedded = (src / "main_40a_gen2_embedded_hgss.lua").read_text(encoding="utf-8")
surf = (src / "main_40b_gen2_hgss_surf_visual.lua").read_text(encoding="utf-8")
voxel = (src / "main_60_gen2_voxel_runtime_compat.lua").read_text(encoding="utf-8")

errors = []
def require(cond, message):
    if not cond:
        errors.append(message)

require("main_40a_gen2_embedded_hgss.lua" in parts,
        "embedded HGSS resolver is not loaded")
require("main_40b_gen2_hgss_surf_visual.lua" in parts,
        "HGSS Surf visual bridge is not loaded")
require(parts.index("main_40_pokemmo_size_fix.lua") < parts.index("main_40a_gen2_embedded_hgss.lua")
        < parts.index("main_40b_gen2_hgss_surf_visual.lua") < parts.index("main_41_stadium2_3d.lua"),
        "HGSS bridges must load after native crop sizing and before Stadium runtime")

require('PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"' in embedded,
        "embedded resolver does not target the Gen2 provider")
require('WILDS_ID = "overworld_wild_spawns"' in embedded,
        "embedded resolver does not reuse the native Wilds seam")
require("api.resolve" in embedded and "dramaticSkyRideEmbeddedAlias" in embedded,
        "embedded HGSS path does not reuse main_38 native resolver")
require("setObjPalette" in embedded,
        "HGSS renderer does not satisfy Gold SpriteRenderer palette interface")
require("cropForDef" in embedded and "PaletteFX.markTrueColor" in embedded,
        "embedded HGSS renderer does not preserve native crop/true-colour drawing")
require("buildWaterSprite" not in embedded,
        "embedded resolver must not reach into Visible Surf's private builder")

require("_waterRideVisual" in surf and "previousWaterVisual" in surf,
        "Surf bridge does not use the public late-render seam")
require("nativePokeMMOMounts" in surf and "gen2EmbeddedPokeMMOMounts" in surf,
        "Surf does not support both standalone and embedded HGSS sources")
require("OverworldState.update" not in surf and "Player:pose" not in surf,
        "Surf bridge must not take gameplay/player ownership")

require("nativeHgssDef" in voxel and "buildNativeHgssCard" in voxel,
        "Gen2 voxel compat does not understand native HGSS atlas cards")
require("cropForDef" in voxel and "nativeRow" in voxel and "nativeColumn" in voxel,
        "HGSS voxel card does not use crop plus 4x4 direction/animation UVs")

if errors:
    print("Gen2 HGSS Surf contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)
print("Gen2 HGSS Surf contract: PASS")
