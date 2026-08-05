# Dramatic Sky Ride — alpha.14

A gameplay add-on for **Gen1Recomp** and **Dramatic Shape Voxel Mod** that adds controllable flying mounts, Surf-aware water landings and terrestrial Ground Ride mounts.

## Download

Download the ready-to-install archive from **GitHub Releases**:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

Use the `dramatic_sky_ride-<version>.zip` asset attached to the latest release, not GitHub's source-code ZIP.

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
- normal walls, trees, rocks, NPCs, encounters, warps and scripts remain active;
- available outdoors and in caves;
- official low ledges can be jumped in either direction;
- ordinary walls and other obstacles cannot be jumped;
- follower entities are hidden while mounted and restored afterwards;
- compatible map changes preserve the mount;
- entering an incompatible building dismounts automatically;
- battles temporarily hide the mount and restore it afterwards when possible.

### Ground Ride controls

| Action | Keyboard | Controller |
|---|---|---|
| Mount or dismount | `G` | `SELECT + L1` |
| Move | Configured movement keys | Left stick / D-pad |

The last valid terrestrial mount is remembered independently from the last flying mount.

## Flying mounts

The following conscious Pokémon receive a **RIDE & FLY** action:

Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

### Flight controls

| Action | Keyboard | Controller |
|---|---|---|
| Move | Configured movement keys | Left stick / D-pad |
| Look | Mouse | Right stick |
| Ascend | `Page Up` | `R2` |
| Descend | `Page Down` | `L2` |
| Boost | Configured B action | In-game `B` |
| Land | Configured A action | In-game `A` |
| Quick flight mount | `F` | `SELECT + R1` |

Using the flight shortcut while Ground Riding dismounts first and then attempts takeoff normally. Ground Ride cannot be started while flying or surfing.

## Surf integration

When any party Pokémon knows **Surf**, water becomes a valid flight-landing surface. Landing activates Gen1Recomp's native surfing state, water collisions and Surf music. `F` or `SELECT + R1` can take off again directly from the water.

## Required dependencies

1. **Gen1Recomp**, using a build compatible with Mod API 2.
2. **Dramatic Shape Voxel Mod 1.6.0 or newer**:
   https://github.com/DramaticShape/DramaticShapeVoxelMod
3. **A compatible PokePC follower-sprite provider**, either `PokePC Followers` or `PokePC Followers Voxel Merge`.

`Followers EX` is optional but supported.

## Installation

1. Download the archive attached to the desired GitHub release.
2. Remove any older `dramatic_sky_ride` folder.
3. Extract the archive into the Gen1Recomp `mods` directory.
4. Confirm that the final path is `mods/dramatic_sky_ride/manifest.json`.
5. Fully restart Gen1Recomp.

## Known limitations

- Ground-mount rider offsets require in-game verification for all seven species.
- Reverse ledge jumping is intentionally limited to official ledge definitions.
- Cave support currently follows compatible cave/underground tileset metadata.
- Complete geometry-based roof detection is not implemented yet.
- A dedicated seated trainer pose is planned for a later version.
- This remains an alpha and needs testing across maps, controllers and game versions.

## Bug reports

Include the Gen1Recomp version, Dramatic Shape version, follower mod, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and any available screenshots, video or logs.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
