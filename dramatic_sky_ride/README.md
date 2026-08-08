# Dramatic Sky Ride 0.1.1 compatibility test

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

The primary voxel provider is now **Battle Art Voxel Fork** by absol89 (`BATTLE_ART_VOXEL_FORK`), currently validated against 1.7.6. The retired `DRAMATIC_SHAPE` provider remains a best-effort compatibility fallback for existing installations, but new DSR builds target Battle Art Voxel Fork first.

## Highlights

### Flying

Supported flying mounts:

- Charizard
- Pidgeot
- Fearow
- Golbat
- Aerodactyl
- Articuno
- Zapdos
- Moltres
- Dragonair
- Dragonite

Use `H` on keyboard or `X` on controller.

`F` is intentionally not used by DSR because Gen1PC Overworld Encounters reserves `F`/`V` for follower attacks.

Flight includes altitude control, boost, rider rendering, battle restoration, connected-map traversal, safe landing and voxel-camera support.

### Story-aware FLY progression

DSR can require the selected mount to use FLY and can enforce the normal progression concepts around THUNDERBADGE and SOULBADGE.

`STORY GATES` respects data-driven badge/event gates while airborne.

`DISCOVERY GATES` prevents first-time airborne entry into canonical vanilla Kanto routes and cities until those maps have been reached through legitimate non-DSR-flight gameplay. Unknown/custom map ids are **allowed by default** so custom map packs and total conversions remain compatible.

### Camera-directed altitude

In voxel `1ST` and `3RD`, vertical camera input can directly control requested flight altitude:

- look up to climb;
- look down to descend;
- existing `R2/L2` and `Page Up/Page Down` manual altitude controls remain available;
- `CAMERA ALTITUDE` can be disabled independently.

### Ground Ride

Supported Ground Ride mounts:

- Arcanine
- Rapidash
- Dodrio
- Rhyhorn
- Rhydon
- Kangaskhan
- Tauros
- Snorlax

Use `G` on keyboard or `Y` on controller.

Ground Ride includes species-specific movement profiles, gallop/stamina, dust, ledge traversal, connected-map continuity, battle restoration and mounted interaction safeguards.

### Visible Surf mounts

Supported visible Surf mounts:

- Blastoise
- Tentacruel
- Gyarados
- Lapras

Native Surf movement, collisions, music and transitions remain in control. While flying, manual Surf is blocked; a valid water landing can continue directly into native Surf when progression and party requirements are satisfied.

### Pokédex-proportional mount sizing

Flying and Ground Ride mounts use Gen 1 Pokédex height as the visual baseline, with per-species size controls. Scaling is visual only and does not alter logical cells, collisions or map rules.

## Battle Art Voxel Fork compatibility

DSR uses the fork's public `exports.lib` API and treats it as the primary voxel provider. It does not patch Battle Art's sprite or battle-rendering internals.

Validated integration targets include:

- voxel overworld rendering;
- `1ST` and `3RD` camera modes;
- camera-driven flight altitude;
- Ground Ride and flight rider billboards;
- Battle Art 3D battle transitions;
- mount removal before the battle world snapshot;
- mount restoration after wild/trainer battles;
- optional Wild Skies aerial battles.

If both voxel providers are present, DSR selects `BATTLE_ART_VOXEL_FORK` first.

## Optional Wild Skies integration

Wild Skies remains a completely separate optional mod. DSR integrates through Wild Skies' public API: ambient flyers remain owned by Wild Skies, visible flyers can use species-specific follower art when available, and interception starts a battle against the exact visible species and level.

Free Fly and Dramatic Sky Ride remain alternative player-flight engines and are declared conflicting.

## Installation

Import the release ZIP directly through the Gen1Recomp launcher, or extract it so that `mods/dramatic_sky_ride/manifest.json` exists.

## Dependencies

Required for current builds:

- Gen1Recomp `>=0.1.69 <2.0.0` with Mod API 2 support;
- Battle Art Voxel Fork `>=1.7.6 <2.0.0`.

Optional / compatibility:

- retired Dramatic Shape `>=1.7.0 <2.0.0` as a best-effort legacy fallback;
- a compatible PokePC follower-sprite provider;
- Wild Skies.

## Compatibility philosophy

DSR prefers public APIs and capability detection over patching another mod's internals. Battle Art owns its battle presentation; Wild Skies owns its ambient flyers; follower mods own their follower systems. DSR only coordinates the mount lifecycle it needs.

## Credits

- absol89/DramaticShapeVoxelMod — primary Battle Art voxel provider, voxel scene, cameras and battle presentation compatibility.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture and legacy compatibility target.
- gamecorner-033/PokePCFollowers — Gen 1 follower sprite assets when installed by the user.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration seams and Free Fly progression/API patterns.

## Bug reports

Include the Gen1Recomp version, Battle Art Voxel Fork version, follower provider, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots/logs when available.
