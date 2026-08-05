# Dramatic Sky Ride — alpha.14

A gameplay add-on for **Gen1Recomp** and **Dramatic Shape Voxel Mod** that adds controllable flying mounts, Surf-aware water landings and terrestrial Ground Ride mounts.

## Download

Download the ready-to-install archive from **GitHub Releases**:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

Use the `dramatic_sky_ride-<version>.zip` asset attached to the latest release.

## Alpha.14: Ground Ride

Ground Ride is a separate terrestrial mount system with its own shortcut and party action.

Supported ground mounts:

- Arcanine — `follower_059.png`
- Rapidash — `follower_078.png`
- Dodrio — `follower_085.png`
- Rhyhorn — `follower_111.png`
- Rhydon — `follower_112.png`
- Kangaskhan — `follower_115.png`
- Tauros — `follower_128.png`

Each compatible, conscious party member receives a **RIDE** action.

Ground Ride features:

- bicycle-class movement speed;
- normal collisions, encounters, warps and scripts remain active;
- available outdoors and in caves;
- official low ledges can be jumped in either direction;
- ordinary walls, trees, rocks, buildings and water remain impassable;
- compatible transitions preserve the mount;
- incompatible indoor maps dismount automatically;
- followers and battle transitions are restored safely.

### Ground Ride controls

| Action | Keyboard | Controller |
|---|---|---|
| Mount or dismount | `G` | `SELECT + L1` |
| Move | Configured movement keys | Left stick / D-pad |

## Flying mounts

Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite receive **RIDE & FLY**.

| Flight action | Keyboard | Controller |
|---|---|---|
| Move | Configured movement keys | Left stick / D-pad |
| Look | Mouse | Right stick |
| Ascend | `Page Up` | `R2` |
| Descend | `Page Down` | `L2` |
| Boost | Configured B action | In-game `B` |
| Land | Configured A action | In-game `A` |
| Quick flight mount | `F` | `SELECT + R1` |

Using the flight shortcut while Ground Riding dismounts first and then attempts takeoff. Ground Ride cannot start while flying or surfing.

## Surf integration

When any party Pokémon knows **Surf**, water becomes a valid flight-landing surface. Landing activates Gen1Recomp's native surfing state, water collisions and Surf music. `F` or `SELECT + R1` can take off again directly from water.

## Required dependencies

1. **Gen1Recomp**, compatible with Mod API 2.
2. **Dramatic Shape Voxel Mod 1.6.0 or newer**:
   https://github.com/DramaticShape/DramaticShapeVoxelMod
3. **PokePC Followers** or **PokePC Followers Voxel Merge** for the installed follower sprites.

`Followers EX` is optional but supported.

## Installation

Extract the release archive so the final path is:

```text
mods/dramatic_sky_ride/manifest.json
```

Fully restart Gen1Recomp after replacing the mod.

## Known limitations

- Ground-mount rider offsets require in-game verification for all seven species.
- Reverse jumps are deliberately limited to official ledge definitions.
- Cave support follows cave/underground tileset metadata.
- A dedicated seated trainer pose is planned later.
- This remains an alpha and requires real-world testing.
