# Dramatic Sky Ride 0.1.4

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Download

Use the launcher-ready ZIP attached to the latest GitHub release:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

Do not use GitHub's automatic source-code ZIP as the mod package.

## Required setup

Install **PokéPC Followers (W/Voxel Support)** (`PokePCFollowers_VoxelMerge`) and one voxel provider:

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0`;
- **Dramaless Shape** `>=1.6.4 <2.0.0`.

Battle Art is preferred automatically if both providers are installed.

## Recommended airborne ecosystem

**Wild Skies 1.4.1+** is strongly recommended. DSR integrates only through Wild Skies' public API, starts aerial battles against the exact visible species and level, and restores the mount and airborne state afterward.

## What's new in 0.1.4

- Raised the Dramaless Shape baseline to 1.6.4, which fixes the 1ST/3RD menu softlock and camera-control issues present in 1.6.3.
- Battle Art Voxel Fork remains at 1.7.6.
- Flight, Ground Ride, visible Surf, speed settings and Wild Skies behavior are unchanged from 0.1.3.

## Controls

| Action | Battle Art | Dramaless | Controller |
|---|---|---|---|
| Flight | `H` | `H` | `X` |
| Ground Ride | `G` | `J` | `Y` |
| Ascend / descend | `Page Up` / `Page Down` | `Page Up` / `Page Down` | `R2` / `L2` |

`F` remains free for Gen1PC Overworld Encounters follower attacks. Dramaless reserves `G` for V-GRID.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- PokéPC Followers (W/Voxel Support) required.
- Battle Art Voxel Fork `>=1.7.6 <2.0.0` or Dramaless Shape `>=1.6.4 <2.0.0`.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- `free_fly` conflicts as an alternative player-flight engine.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
