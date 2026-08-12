#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dramatic_sky_ride")
provider = Path(sys.argv[2]) if len(sys.argv) > 2 else None
src = root / "src"
parts = [x.strip() for x in (src / "parts.txt").read_text(encoding="utf-8").splitlines() if x.strip()]
bridge_name = "main_40a_gen2_embedded_pokemmo.lua"
adapter_name = "main_40b_gen2_pokemmo_sprite_interface.lua"
bridge = (src / bridge_name).read_text(encoding="utf-8")
adapter = (src / adapter_name).read_text(encoding="utf-8")

errors = []

def require(cond, message):
    if not cond:
        errors.append(message)

require(bridge_name in parts, "Gen2 embedded PokeMMO bridge is not loaded")
require(adapter_name in parts, "Gen2 PokeMMO SpriteRenderer interface adapter is not loaded")
if bridge_name in parts:
    require(parts.index("main_40_pokemmo_size_fix.lua") < parts.index(bridge_name),
            "embedded PokeMMO bridge must load after the shared crop/size correction")
    require(parts.index(bridge_name) < parts.index("main_56_gen2_player_bridge.lua"),
            "embedded PokeMMO builders must be installed before the Gold player bridge")
if adapter_name in parts:
    require(parts.index(bridge_name) < parts.index(adapter_name)
            < parts.index("main_56_gen2_player_bridge.lua"),
            "SpriteRenderer interface adapter must wrap the embedded bridge before Gold mounts run")

require('local PROVIDER_ID = "STADIUM2_OVERWORLD_MODELS"' in bridge,
        "bridge does not target Randy's Gen2 provider")
require('local WILDS_ID = "overworld_wild_spawns"' in bridge,
        "bridge does not reuse the established Wilds compatibility contract")
require("ex and ex.wilds" in bridge and '"sprite_style"' in bridge
        and '"pokemmo"' in bridge,
        "bridge does not discover the embedded Wilds PokeMMO style")
require('"flight_mount_renderer"' in bridge and 'lower() ~= "stadium"' in bridge,
        "embedded PokeMMO sprites are not explicitly limited to the 2D renderer")
require("nativePokeMMOMounts" in bridge and "api.resolve" in bridge,
        "bridge does not reuse DSR's native high-resolution atlas resolver")
require("mod.find = function" in bridge and "mod.find = originalFind" in bridge,
        "temporary Wilds alias is not restored after the synchronous native resolve")
require("buildMountSprite = function" in bridge,
        "Flight builder is not bridged")
require("buildGroundMountSprite = function" in bridge,
        "Ground Ride builder is not bridged")
require("buildWaterSprite = function" in bridge,
        "Visible Surf builder is not bridged")
require("nativePokeMMOSizeCorrection" in bridge and "cropForDef" in bridge
        and "liveCorrection.scale" in bridge,
        "Gold 2D mounts do not reuse DSR's opaque crop and Pokedex/user size correction")
require("PaletteFX.markTrueColor" in bridge and "love.graphics.newQuad" in bridge,
        "native true-color cropped atlas drawing contract is incomplete")
require("payload.mod == PROVIDER_ID" in bridge and 'payload.key == "sprite_style"' in bridge,
        "live Gen2 provider Sprite Style changes are not observed")

# Gold World:applySpritePalette unconditionally calls setObjPalette on a live
# actor renderer. Native HGSS/PokeMMO cards are true-color, so they accept and
# remember that interface call without palette-baking the source atlas.
require("dramaticSkyRideNativePokeMMO == true" in adapter,
        "SpriteRenderer adapter is not limited to native PokeMMO cards")
require("function renderer:setObjPalette(colors, group)" in adapter,
        "native PokeMMO renderer does not implement Gold setObjPalette contract")
require("self.objColors = colors" in adapter and "self.objGroup = group" in adapter,
        "setObjPalette compatibility call does not retain engine palette metadata")
require('wrapBuilder("buildMountSprite")' in adapter
        and 'wrapBuilder("buildGroundMountSprite")' in adapter
        and 'wrapBuilder("buildWaterSprite")' in adapter,
        "palette-compatible renderer is not guaranteed across Flight/Ground/Surf builders")
require("nativePokeMMOMounts" in adapter and "gen2EmbeddedPokeMMOMounts" in adapter,
        "public native/embedded resolve seams are not both decorated")

if provider is not None:
    options = (provider / "options.lua").read_text(encoding="utf-8")
    main = (provider / "main.lua").read_text(encoding="utf-8")
    embedded = (provider / "lib" / "EmbeddedWildsMain.lua").read_text(encoding="utf-8")
    providers = (provider / "lib" / "sprite_providers.lua").read_text(encoding="utf-8")
    runtime = (provider / "lib" / "runtime_sheets.lua").read_text(encoding="utf-8")

    require('"HGSS / PokeMMO", "pokemmo"' in options,
            "Gen2-3D-Sprites HGSS/PokeMMO option contract changed")
    require("mod.exports.wilds = wildsExports" in main,
            "Gen2-3D-Sprites no longer exposes embedded Wilds")
    require("mod.exports.resolveFollowerSprite" in embedded,
            "embedded Wilds follower sprite resolver is no longer public")
    require('POKEMMO = "pokemmo"' in providers and "_makePokemmoProvider" in providers,
            "embedded Wilds PokeMMO provider contract changed")
    require('assets/generated/followsprites_runtime' in runtime,
            "embedded Wilds runtime-sheet fallback path changed")

    atlas = provider / "assets" / "enhanced_overworld" / "followsprites"
    mount_dexes = [154, 160, 164, 169, 178, 203, 217, 226, 227,
                   230, 232, 234, 243, 244, 245, 248, 249, 250]
    missing = [dex for dex in mount_dexes if not list(atlas.glob(f"{dex:03d}-*-n.png"))]
    require(not missing, f"Gen2-3D-Sprites missing native PokeMMO mount atlases: {missing}")

if errors:
    print("Gen2 embedded PokeMMO contract FAILED")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print("Gen2 embedded PokeMMO contract: PASS")
