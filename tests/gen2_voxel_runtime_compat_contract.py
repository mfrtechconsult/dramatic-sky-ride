#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
provider = Path(sys.argv[2]) if len(sys.argv) > 2 else None
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
compat = (src / "main_60_gen2_voxel_runtime_compat.lua").read_text(encoding="utf-8")

errors = []

def require(cond, message):
    if not cond:
        errors.append(message)

require("main_60_gen2_voxel_runtime_compat.lua" in parts,
        "Gen2 voxel runtime compatibility layer is not loaded")
require(parts.index("main_59_gen2_voxel_visual_fixes.lua")
        < parts.index("main_60_gen2_voxel_runtime_compat.lua"),
        "runtime compatibility must load after the known-good single-model/altitude layers")

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

# Randy's separate SpriteBillboards cache must reproduce DSR's size geometry in
# 2D mode, but only for the currently active DSR mount definition.
require('providerModule(ex, "SpriteBillboards")' in compat
        and 'providerModule(ex, "Voxel3D")' in compat,
        "Randy billboard modules are not patched through its public lib seam")
require("renderer2D()" in compat and "def == activeDef" in compat,
        "2D sizing is not restricted to the active DSR mount")
require("mountVisualScale" in compat,
        "2D billboard does not use DSR's canonical/user mount size")
require("local halfW = 8 * scale" in compat and "local y1 = 16 * scale" in compat,
        "2D billboard geometry is not scaled around the feet like main_21")
require("billboards.mesh = meshWrapper" in compat
        and "billboards.shadowQuad = shadowWrapper" in compat,
        "solid and shadow billboard geometry do not share the same scale")

if provider is not None:
    spawn_logic = (provider / "lib" / "spawn_logic.lua").read_text(encoding="utf-8")
    billboards = (provider / "lib" / "SpriteBillboards.lua").read_text(encoding="utf-8")
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

if errors:
    print("Gen2 voxel runtime compat contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 voxel runtime compat contract: PASS")
