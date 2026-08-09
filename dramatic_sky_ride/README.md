# Dramatic Sky Ride 0.1.5

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Required setup

DSR 0.1.5 supports either of the current voxel providers below. Install **one** of them:

- **Battle Art Voxel Fork 1.7.6+** by absol89 — `BATTLE_ART_VOXEL_FORK`;
- **Dramaless Shape 1.6.4+** by artyrambles — `DRAMALESS_SHAPE`.

If both are installed, DSR prefers Battle Art Voxel Fork.

Also required:

- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`, used as the overworld Pokémon/NPC sprite provider for mounts.

The retired `DRAMATIC_SHAPE` id remains only as a best-effort runtime fallback for older manual installations.

## Strongly recommended: Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR works without it, but the intended flying experience is DSR + Wild Skies: the sky becomes populated with visible Pokémon that can be intercepted in mid-air.

DSR integrates only through Wild Skies' public API:

- ambient airborne Pokémon remain owned and simulated by Wild Skies;
- visible flyers use species-specific overworld art when available;
- intercepting a flyer starts a battle against that exact visible species and level;
- DSR restores the mount and airborne state after battle;
- ordinary ground encounters are suppressed while DSR is airborne;
- the two-cell interception envelope makes visually close passes easier to engage.

Wild Skies remains a separate optional mod and is not bundled or patched by DSR.

## What's new in 0.1.5

- **Dramaless voxel detection fixed.** Current Dramaless Shape registers the canonical `voxel` render pipeline, and DSR now follows that pipeline instead of assuming `st_voxel`.
- **False VOXEL-off message fixed.** If the selected provider hint returns level 0, DSR now checks supported fallback pipeline ids before refusing takeoff.
- **Legacy fallback retained.** `st_voxel` remains a compatibility fallback for older forks only.
- **Battle Art unchanged.** Battle Art Voxel Fork remains preferred when both providers are installed and continues to use `voxel` exactly as before.
- **Diagnostics improved.** DSR logs the selected voxel provider, version, pipeline and current level once during provider initialization.
- **No Flying Music in 0.1.5.** The experimental music work remains outside `main`.

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

- Keyboard with Battle Art: `G` toggles Ground Ride.
- Keyboard with Dramaless Shape: `J` toggles Ground Ride because Dramaless reserves `G` for V-GRID.
- Controller: `Y` toggles Ground Ride in free-roam with either provider.

Ground Ride includes species-specific movement, gallop/stamina, dust, guarded ledge traversal, connected-map continuity and battle restoration.

### Visible Surf

Supported visible Surf mounts: Blastoise, Tentacruel, Gyarados and Lapras.

Native Surf movement, collision, music and progression remain authoritative. A valid airborne water landing can continue directly into native Surf. In voxel `3RD`, DSR keeps water from incorrectly collapsing the third-person camera boom; `1ST` keeps the normal first-person behavior.

## Speed settings

- `FLIGHT SPEED`: 50% to 200%, default 100%.
- `GROUND SPEED`: 50% to 200%, default 100%.

These are global multipliers. Species profiles remain meaningful: a faster Ground Ride species still stays faster than a slower one, and Flight boost / Ground gallop continue to stack with the selected global setting.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default for map packs and total conversions.

## Voxel provider integration

DSR uses the selected provider's public `exports.lib` interface rather than patching its rendering internals.

Supported providers:

- **Battle Art Voxel Fork** (`BATTLE_ART_VOXEL_FORK`) — preferred when both providers are present;
- **Dramaless Shape** (`DRAMALESS_SHAPE`) — supported alternative using the canonical `voxel` pipeline.

Integration covers voxel overworld rendering, 1ST/3RD cameras, camera-driven altitude, mount billboards, free movement, terrain-aware height handling and Surf third-person camera behavior. Battle Art staged 3D battle transitions continue to receive the existing DSR lifecycle protection.

## Installation

Import the release ZIP directly through the Gen1Recomp launcher. Install and enable PokéPC Followers plus one supported voxel provider before DSR.

Manual layout: `mods/dramatic_sky_ride/manifest.json`.

## Compatibility

- Required: Gen1Recomp `>=0.1.69 <2.0.0`.
- Required: PokéPC Followers (W/Voxel Support).
- Voxel provider: Battle Art Voxel Fork `>=1.7.6 <2.0.0` **or** Dramaless Shape `>=1.6.4 <2.0.0`.
- Strongly recommended: Wild Skies `>=1.4.1 <2.0.0`.
- `free_fly` remains a conflicting alternative player-flight engine.
- Custom maps are permissive by default unless they explicitly opt into DSR discovery gates.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel provider, cameras and 3D battle presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public `exports.lib` integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — required Gen 1 overworld Pokémon sprite provider.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration API and airborne ecosystem.

## Bug reports

Include Gen1Recomp version, selected voxel provider and version, PokéPC Followers version, Wild Skies version if installed, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots/logs when available.
