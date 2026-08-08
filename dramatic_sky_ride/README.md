# Dramatic Sky Ride 0.1.1

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Required setup

DSR 0.1.1 targets the current community voxel stack and requires:

- **Battle Art Voxel Fork** by absol89 — `BATTLE_ART_VOXEL_FORK >=1.7.6 <2.0.0`;
- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`, used as the overworld Pokémon/NPC sprite provider.

The retired `DRAMATIC_SHAPE` id is no longer a supported installation dependency. A best-effort runtime fallback remains only for older manual installations.

## Recommended setup: Wild Skies

**Wild Skies is strongly recommended.** DSR works without it, but Wild Skies turns the sky into an actual encounter space instead of only a traversal system.

When installed, DSR integrates through Wild Skies' public API:

- ambient airborne Pokémon remain owned and simulated by Wild Skies;
- visible flyers use species-specific overworld art when available;
- intercepting a flyer starts a battle against that exact visible species and level;
- DSR restores the mount and airborne state after battle;
- ordinary ground encounters are suppressed while DSR is airborne.

Wild Skies remains a separate optional mod and is not bundled or patched by DSR.

## Controls

### Flying

Supported flying mounts: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

- Keyboard: `H` toggles Flight.
- Controller: `X` toggles Flight in free-roam.
- `R2/L2` or `Page Up/Page Down`: manual altitude.
- In voxel `1ST` / `3RD`, looking up/down can control altitude when `CAMERA ALTITUDE` is enabled.

`F` is deliberately not used by DSR because Gen1PC Overworld Encounters reserves `F`/`V` for follower attacks.

### Ground Ride

Supported Ground Ride mounts: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros and Snorlax.

- Keyboard: `G` toggles Ground Ride.
- Controller: `Y` toggles Ground Ride in free-roam.

Ground Ride includes species-specific movement, gallop/stamina, dust, guarded ledge traversal, connected-map continuity and battle restoration.

### Visible Surf

Supported visible Surf mounts: Blastoise, Tentacruel, Gyarados and Lapras.

Native Surf movement, collision, music and progression remain authoritative. A valid airborne water landing can continue directly into native Surf.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default for map packs and total conversions.

## Battle Art Voxel Fork integration

Battle Art Voxel Fork is the primary voxel provider for DSR 0.1.1. DSR uses its public `exports.lib` API and does not patch Battle Art's sprite or battle-rendering internals.

Integration covers voxel overworld rendering, 1ST/3RD cameras, camera-driven altitude, mount billboards, staged 3D battle transitions and clean mount removal/restoration around battles.

## Installation

Import the release ZIP directly through the Gen1Recomp launcher. The required dependencies should be installed and enabled before DSR.

Manual layout: `mods/dramatic_sky_ride/manifest.json`.

## Compatibility

- Required: Gen1Recomp `>=0.1.69 <2.0.0`, Battle Art Voxel Fork `>=1.7.6 <2.0.0`, PokéPC Followers (W/Voxel Support).
- Strongly recommended: Wild Skies `>=1.3.1 <2.0.0`.
- `free_fly` remains a conflicting alternative player-flight engine.
- Custom maps are permissive by default unless they explicitly opt into DSR discovery gates.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, primary voxel provider, cameras and 3D battle presentation.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — required Gen 1 overworld Pokémon sprite provider.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration API and airborne ecosystem.

## Bug reports

Include Gen1Recomp version, Battle Art Voxel Fork version, PokéPC Followers version, Wild Skies version if installed, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots/logs when available.
