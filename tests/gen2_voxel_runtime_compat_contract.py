#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
provider = Path(sys.argv[2]) if len(sys.argv) > 2 else None
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
compat = (src / "main_60_gen2_voxel_runtime_compat.lua").read_text(encoding="utf-8")
owner = (src / "main_61_gen2_voxel_single_owner_guard.lua").read_text(encoding="utf-8")

errors = []

def require(cond, message):
    if not cond:
        errors.append(message)

require("main_60_gen2_voxel_runtime_compat.lua" in parts,
        "Gen2 voxel runtime compatibility layer is not loaded")
require("main_61_gen2_voxel_single_owner_guard.lua" in parts,
        "Gen2 voxel single-owner guard is not loaded")
require(parts.index("main_59_gen2_voxel_visual_fixes.lua")
        < parts.index("main_60_gen2_voxel_runtime_compat.lua")
        < parts.index("main_61_gen2_voxel_single_owner_guard.lua"),
        "single-owner guard must load after sizing/runtime compatibility")

# Flight must block only Randy's embedded ground/water roaming battle seam.
# Do not re-introduce the old broad battle renderer handoff.
require("wilds.logic" in compat and "logic._startBattle" in compat,
        "Randy embedded Wilds battle seam is not targeted")
require("flight.active == true" in compat and "blockedGroundBattles" in compat,
        "ground/water Wilds encounters are not gated during DSR Flight")
require("Wild Skies" in compat,
        "contract does not document that airborne Wild Skies encounters stay independent")
require("battle.started" not in compat and "pushBattle" not in compat,
        "runtime compatibility must not take ownership of general battle rendering")

# main_60 still owns construction of DSR-sized ordinary 16x96 2D meshes.
require('providerModule(ex, "SpriteBillboards")' in compat
        and 'providerModule(ex, "Voxel3D")' in compat,
        "Randy billboard modules are not patched through its public lib seam")
require("mountVisualScale" in compat,
        "2D billboard does not use DSR's canonical/user mount size")
require("local halfW = 8 * scale" in compat and "local y1 = 16 * scale" in compat,
        "2D billboard geometry is not scaled around the feet like main_21")

# Regression: the HGSS/PokeMMO renderer is a native 4x4 high-resolution atlas,
# not a 16x96 six-frame sheet. The generic main_60 UV builder used to sample
# only its top-left 16px, producing a partial mount (and occasionally leaving
# only the rider visible). Native definitions must delegate to main_40's crop/
# animation-aware billboard chain instead of entering buildScaledCard().
require("nativePokeMMODef" in compat
        and "dramaticSkyRideNativePokeMMO == true" in compat,
        "runtime compatibility does not recognize native PokeMMO mount definitions")
require("if nativePokeMMODef(def) then" in compat
        and "return fallback(def, frame)" in compat,
        "native PokeMMO 4x4 atlases can still enter the generic 16x96 billboard builder")

# Regression: a mount SpriteDef is shared by Gold's flat player bridge and the
# DSR voxel proxy. Never use that SpriteDef identity as the final ownership
# decision. main_61 must narrow main_60's broad hook to the immediate proxy
# fallback draw identified from Randy's pose/entity-aware safeDraw seam.
require("dramaticSkyRideVoxelProxy == true" in owner
        and '"DSR_GEN2_VOXEL_MOUNT"' in owner,
        "single-owner guard does not identify the real DSR mount proxy")
require("local rawSafeDraw = stadium.safeDraw" in owner
        and "state.contextDef = p.sprite.def" in owner,
        "2D sizing is not scoped by Randy's entity-aware draw context")
require("if state.contextDef ~= nil and def == state.contextDef" in owner,
        "billboard sizing can still match a shared mount SpriteDef globally")
require("return rawMesh(def, frame)" in owner,
        "non-proxy marker/ghost paths do not return to Randy's raw billboard")
require("sizeMarker.meshWrapper = narrowMesh" in owner,
        "main_60 can reinstall its broad SpriteDef hook on the next update")
require("return rawShadow(def, frame)" in owner,
        "shared marker/ghost shadow paths are still globally replaced")

# A native/party follower of the mounted species may survive in Randy's base
# cast even when the extra-entity provider is filtered. It must never become a
# second Stadium model or 2D card while the DSR proxy is active.
require("duplicateMountFollower" in owner
        and "e.stadiumModel = false" in owner
        and "e.pokemonModel = false" in owner,
        "same-species follower is not opted out during Stadium preparation")
require("suppressedDuplicatePoses" in owner
        and "return true" in owner,
        "same-species follower fallback is not suppressed from the solid pass")
require("stadium.prepare = prepareWrapper" in owner
        and "stadium.safeDraw = safeDrawWrapper" in owner,
        "single-owner guard is not attached to both prepare and solid draw seams")

if provider is not None:
    spawn_logic = (provider / "lib" / "spawn_logic.lua").read_text(encoding="utf-8")
    billboards = (provider / "lib" / "SpriteBillboards.lua").read_text(encoding="utf-8")
    stadium = (provider / "lib" / "OverworldStadium.lua").read_text(encoding="utf-8")
    main = (provider / "main.lua").read_text(encoding="utf-8")
    require("mod.exports.wilds = wildsExports" in main,
            "Gen2-3D-Sprites no longer exports embedded Wilds")
    require("function SpawnLogic:_startBattle(record)" in spawn_logic,
            "Gen2-3D-Sprites embedded Wilds _startBattle seam changed")
    require("self:_startBattle(record)" in spawn_logic
            and "function SpawnLogic:onCollision" in spawn_logic
            and "function SpawnLogic:onStepped" in spawn_logic,
            "embedded Wilds contact paths no longer converge on _startBattle")
    require("function SpriteBillboards.mesh(def, frame)" in billboards
            and "{ 0, 0, 0" in billboards and "{ 16, 16, 0" in billboards,
            "Gen2-3D-Sprites billboard geometry contract changed")
    require("function OverworldStadium.safeDraw(p)" in stadium
            and "function OverworldStadium.prepare(posed)" in stadium,
            "Gen2-3D-Sprites entity-aware Stadium draw seams changed")
    require("entity.stadiumModel == false or entity.pokemonModel == false" in stadium,
            "Gen2-3D-Sprites explicit per-entity Stadium opt-out contract changed")

if errors:
    print("Gen2 voxel runtime compat contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 voxel runtime compat contract: PASS")
