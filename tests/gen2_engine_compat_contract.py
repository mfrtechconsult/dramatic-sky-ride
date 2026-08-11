#!/usr/bin/env python3
from pathlib import Path
import json
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
src = root / "src"
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
runtime = (src / "main_21b_gen2_runtime.lua").read_text(encoding="utf-8")
progression = (src / "main_22b_gen2_progression.lua").read_text(encoding="utf-8")

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

require(parts.index("main_21_mount_size.lua") < parts.index("main_21b_gen2_runtime.lua")
        < parts.index("main_22_flight_rules.lua") < parts.index("main_22b_gen2_progression.lua")
        < parts.index("main_23_camera_altitude.lua"),
        "Gen2 runtime/progression layers must wrap the legacy Gen1 rules in load order")

require("gen2Maps" in runtime and "save.player.badges" in runtime,
        "runtime bridge must detect Gold without hard-coded version strings")
require('key == "badge_checks"' in runtime and 'key == "story_gates"' in runtime
        and 'key == "require_fly_move"' in runtime,
        "Gold must bypass only the legacy Gen1 progression implementations")
require("rawOptionValue" in runtime,
        "Gold layer must preserve access to the user's actual option values")

require('"STORM"' in progression and '"FOG"' in progression,
        "Gold FLY/SURF badge mapping must use STORM and FOG")
require("monKnowsMoveGen2" in progression and '"FLY"' in progression,
        "Gold must enforce the REQUIRE FLY setting independently of Gen1 learnset data")
require("fieldmove.eligibility" in progression,
        "Gold FLY gate must remain compatible with shared field-move eligibility hooks")
require("mod.exports.gen2Progression" in progression,
        "Gold progression capability should be exported for later compatibility layers")

# This branch is preparation, not a false compatibility claim. The upstream
# guide says games=[gen1,gen2] means the author has actually boot-tested Gold.
games = manifest.get("games")
require(not games or "gen2" not in [str(x).lower().replace(" ", "") for x in games],
        "Do not declare Gen2 in the manifest before real Gold boot validation")

if errors:
    print("Gen2 engine compatibility contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 engine compatibility contract: PASS")
