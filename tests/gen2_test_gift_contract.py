from pathlib import Path


root = Path(__file__).resolve().parents[1]
src = root / "dramatic_sky_ride" / "src"
parts = [line.strip() for line in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if line.strip()]
gift = (src / "main_55_gen2_test_gift.lua").read_text(encoding="utf-8")


def require(condition, message):
    if not condition:
        raise AssertionError(message)


require(parts[-1] == "main_55_gen2_test_gift.lua", "temporary test giver must load last")
require("if not isGen2Runtime(Game) then return end" in gift,
        "test giver must have a hard Gen 2-only guard")
require('local MAP_ID = "NEW_BARK_TOWN"' in gift and "api:spawnNpc" in gift,
        "New Bark Town runtime NPC is missing")
require("x = 9" in gift and "y = 10" in gift,
        "validated New Bark Town test coordinates changed")
for species in ("HO_OH", "SUICUNE", "RAIKOU", "GYARADOS"):
    require(f'species = "{species}"' in gift, f"missing test gift {species}")
require('requiredMove = "FLY"' in gift, "Ho-Oh must be ready for the FLY gate")
require(gift.count('requiredMove = "SURF"') == 2,
        "Suicune and Gyarados must be ready for the SURF gate")
require("storageRoom(save, Boxes, #missing)" in gift and "firstBoxWithRoom" in gift,
        "party/PC overflow handling is missing")
require("ownsSpecies(save, gift.species)" in gift,
        "repeated interactions must not duplicate owned gifts")

print("Gen 2 temporary test gift contract: PASS")
