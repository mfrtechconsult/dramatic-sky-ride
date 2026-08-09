# Dramatic Sky Ride 0.1.6-rc.1

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

> **Compatibility preview:** `0.1.6-rc.1` is published from the `compat/wilds-of-kanto` development branch for ecosystem testing before the changes are promoted to `main`.

## Download

Use the launcher-ready ZIP attached to the `v0.1.6-rc.1` GitHub prerelease.

Do not use GitHub's automatic source-code ZIP as the mod package.

## Voxel provider

Install one supported voxel provider:

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0`;
- **Dramaless Shape** `>=1.6.4 <2.0.0`.

Battle Art is preferred automatically if both providers are installed.

## Pokémon sprite / follower provider

This compatibility branch can use either:

- **Wilds of Kanto** (`overworld_wild_spawns`), or
- **PokéPC Followers (W/Voxel Support)** (`PokePCFollowers_VoxelMerge`).

Wilds of Kanto can act as the authoritative follower runtime so DSR does not need a second mod competing for the same follower lifecycle.

## Recommended airborne ecosystem

**Wild Skies 1.4.1+** remains strongly recommended. DSR integrates through Wild Skies' public API, starts aerial battles against the exact visible species and level, and restores the mount and airborne state afterward.

## What's new in 0.1.6-rc.1

- Added **Wilds of Kanto compatibility**, including compatible sprite-provider discovery and cooperative overworld update-hook protection.
- Added a public **Pokémon Stadium Overworld Models compatibility API** exposing flight state, altitude and active mount species.
- Added optional **FLYING MUSIC** support.
- Detects installed DarioMelo `Music_FRLG`, `Music_HGSS` and `Music_LGPE` packs and exposes their Surf/Bike themes as flight choices without redistributing their audio.
- Added an extensible local flight-music catalog for future redistributable or user-supplied tracks.
- Added compatibility regression tests for the Wilds/DSR/Deep Dive/Kanto Dive stack.
- Retains the Dramaless canonical `voxel` pipeline fix introduced in 0.1.5.

## Controls

| Action | Battle Art | Dramaless | Controller |
|---|---|---|---|
| Flight | `H` | `H` | `X` |
| Ground Ride | `G` | `J` | `Y` |
| Ascend / descend | `Page Up` / `Page Down` | `Page Up` / `Page Down` | `R2` / `L2` |

`F` remains free for Gen1PC Overworld Encounters follower attacks. Dramaless reserves `G` for V-GRID.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- Battle Art Voxel Fork `>=1.7.6 <2.0.0` or Dramaless Shape `>=1.6.4 <2.0.0`.
- Wilds of Kanto or PokéPC Followers can provide compatible Pokémon overworld sprites on this branch.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- Optional Pokémon Stadium Overworld Models integration through DSR's read-only flight API.
- `free_fly` conflicts as an alternative player-flight engine.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
