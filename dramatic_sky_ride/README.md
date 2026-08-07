# Dramatic Sky Ride 0.1.0

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp** when used with **Dramatic Shape Voxel Mod**.

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

Use `F` on keyboard or `SELECT + R1` on controller.

Flight includes altitude control, boost, rider rendering, battle restoration, connected-map traversal, safe landing and Dramatic Shape camera support.

### Story-aware FLY progression

The stable release can require the selected mount to use FLY and can enforce the normal progression concepts around THUNDERBADGE and SOULBADGE.

`STORY GATES` respects data-driven badge/event gates while airborne.

`DISCOVERY GATES` prevents first-time airborne entry into canonical vanilla Kanto routes and cities until those maps have been reached through legitimate non-DSR-flight gameplay. This prevents sequence breaks such as flying into Saffron City or an unvisited route too early.

Unknown/custom map ids are **allowed by default** so custom map packs and total conversions remain compatible. Mods that want stricter integration can opt in through DSR's public discovery-gate helpers.

### Camera-directed altitude

In Dramatic Shape `1ST` and `3RD`, vertical camera input can directly control requested flight altitude:

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

Use `G` on keyboard or `SELECT + L1` on controller.

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

## Optional Wild Skies integration

[Wild Skies](https://github.com/ShaneHudson/gen1recomp-mods) remains a completely separate optional mod.

When installed, DSR integrates through Wild Skies' public API:

- ambient Wild Skies flyers remain owned and simulated by Wild Skies;
- real species-specific follower/overworld sprites are preferred when available;
- an aerial interception starts a battle against the exact visible species and level returned by Wild Skies;
- DSR restores its mount/flight state after the battle;
- ground wild-battle starts are suppressed while DSR is airborne.

Free Fly and Dramatic Sky Ride are alternative player-flight engines and are declared conflicting. Wild Skies itself remains compatible with its wider ecosystem.

## Installation

### Launcher / Mod Index

Import the release ZIP directly through the Gen1Recomp launcher.

### Manual installation

1. Remove the previous `mods/dramatic_sky_ride` directory.
2. Create `mods/dramatic_sky_ride/`.
3. Extract the release ZIP contents directly into that folder.
4. Confirm that the final path is `mods/dramatic_sky_ride/manifest.json`.
5. Fully restart Gen1Recomp.

## Dependencies

Required:

- Gen1Recomp `>=0.1.69 <2.0.0` with Mod API 2 support;
- Dramatic Shape Voxel Mod `>=1.7.0 <2.0.0`.

Optional:

- a compatible PokePC follower-sprite provider;
- Wild Skies.

## Compatibility philosophy

DSR avoids hard-blocking unknown maps. Vanilla Kanto progression protections are deliberately conservative, while custom maps remain open unless a mod explicitly opts into DSR discovery gating.

Wild Skies is integrated only through its public interfaces; its code and ambient ecosystem are not embedded into DSR.

## Credits

- DramaticShape/DramaticShapeVoxelMod — voxel scene, first/third-person cameras and continuous free movement.
- gamecorner-033/PokePCFollowers — Gen 1 follower sprite assets when installed by the user.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration seams and Free Fly progression/API patterns.

## Bug reports

Include the Gen1Recomp version, Dramatic Shape version, follower provider, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots/logs when available.
