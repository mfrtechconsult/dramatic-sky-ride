# Dramatic Sky Ride 0.1.2

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Required setup

DSR 0.1.2 targets the current community voxel stack and requires:

- **Battle Art Voxel Fork** by absol89 — `BATTLE_ART_VOXEL_FORK >=1.7.6 <2.0.0`;
- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`, used as the overworld Pokémon/NPC sprite provider for mounts.

The retired `DRAMATIC_SHAPE` id is no longer a supported installation dependency. A best-effort runtime fallback remains only for older manual installations.

## Strongly recommended: Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR works without it, but the intended flying experience is DSR + Wild Skies: the sky becomes populated with visible Pokémon that can be intercepted in mid-air.

DSR integrates only through Wild Skies' public API:

- ambient airborne Pokémon remain owned and simulated by Wild Skies;
- visible flyers use species-specific overworld art when available;
- intercepting a flyer starts a battle against that exact visible species and level;
- DSR restores the mount and airborne state after battle;
- ordinary ground encounters are suppressed while DSR is airborne;
- 0.1.2 uses a more forgiving two-cell interception envelope so visually close passes are easier to engage.

Wild Skies remains a separate optional mod and is not bundled or patched by DSR.

## What's new in 0.1.2

- **Surf + 3RD camera fixed with Battle Art Voxel Fork.** Water no longer collapses the third-person camera boom as if it were a pedestrian obstacle, so the trainer and Surf mount remain visible at normal camera angles.
- **1ST remains true first-person.** DSR does not force the trainer or mount into the first-person camera.
- **Wild Skies interceptions are more forgiving.** The interception radius is now two cells, better matching Wild Skies 1.4.1's moving three-dimensional flocks.

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

Native Surf movement, collision, music and progression remain authoritative. A valid airborne water landing can continue directly into native Surf. In Battle Art `3RD`, DSR keeps water from incorrectly collapsing the camera boom; `1ST` keeps the normal first-person behavior.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default for map packs and total conversions.

## Battle Art Voxel Fork integration

Battle Art Voxel Fork is the primary voxel provider for DSR. DSR uses its public `exports.lib` API and does not patch Battle Art's sprite or battle-rendering internals.

Integration covers voxel overworld rendering, 1ST/3RD cameras, camera-driven altitude, mount billboards, staged 3D battle transitions, Surf third-person camera behavior and clean mount removal/restoration around battles.

## Installation

Import the release ZIP directly through the Gen1Recomp launcher. Install and enable the required dependencies before DSR.

Manual layout: `mods/dramatic_sky_ride/manifest.json`.

## Compatibility

- Required: Gen1Recomp `>=0.1.69 <2.0.0`.
- Required: Battle Art Voxel Fork `>=1.7.6 <2.0.0`.
- Required: PokéPC Followers (W/Voxel Support).
- Strongly recommended: Wild Skies `>=1.4.1 <2.0.0`.
- `free_fly` remains a conflicting alternative player-flight engine.
- Custom maps are permissive by default unless they explicitly opt into DSR discovery gates.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, primary voxel provider, cameras and 3D battle presentation.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — required Gen 1 overworld Pokémon sprite provider.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration API and airborne ecosystem.

## Bug reports

Include Gen1Recomp version, Battle Art Voxel Fork version, PokéPC Followers version, Wild Skies version if installed, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots/logs when available.
