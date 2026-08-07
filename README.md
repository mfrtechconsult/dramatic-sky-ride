# Dramatic Sky Ride — alpha.15

A gameplay add-on for **Gen1Recomp** and **Dramatic Shape Voxel Mod** that adds controllable flying mounts, visible Surf mounts and a terrestrial Ground Ride system.

## Download

Download the ready-to-install archive from GitHub Releases:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

Use the `dramatic_sky_ride-<version>.zip` asset attached to the latest release, not GitHub's source-code ZIP. Starting with `0.1.0-alpha.15.2.3`, the archive uses the Gen1Recomp Mod Index / launcher layout with `manifest.json` at the ZIP root.

## Alpha.15

Alpha.15 completes the current feature batch and becomes the maintenance baseline.

### Ground Ride mounts

- Arcanine
- Rapidash
- Dodrio
- Rhyhorn
- Rhydon
- Kangaskhan
- Tauros
- Snorlax

Ground Ride features:

- separate `G` / `SELECT + L1` shortcut;
- species-aware speed, acceleration, gallop, stamina and rider positioning;
- stamina HUD, cries, dust, sound and vibration;
- seamless boost continuity across connected maps in 2D, `1ST` and `3RD`;
- official low ledges traversable safely in both directions;
- remembered selection and robust restoration after battles, evolutions and party reordering;
- no remount when the mount is fainted, removed or incompatible;
- NPC conversations and signs available while mounted;
- automatic dismount before incompatible native interactions.

### Flying mounts

Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

Flight remains on `F` / `SELECT + R1`. The validated alpha.14 camera behaviour is unchanged. Airborne battles now restore altitude, boost and rider rendering correctly without leaving ghost entities.

### Visible Surf mounts

Blastoise, Tentacruel, Gyarados and Lapras can be selected through the `MOUNTS` menu. Native Surf movement, collisions, music and transitions remain unchanged.

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Ground Ride mount/dismount | `G` | `SELECT + L1` |
| Flight mount/takeoff | `F` | `SELECT + R1` |
| Move | Configured movement keys | Left stick / D-pad |
| Look in voxel views | Mouse | Right stick |
| Ascend | `Page Up` | `R2` |
| Descend | `Page Down` | `L2` |
| Boost / gallop | Configured B action | In-game `B` |
| Land | Configured A action | In-game `A` |

## Required dependencies

1. Gen1Recomp with Mod API 2 support.
2. Dramatic Shape Voxel Mod `>=1.7.0 <2.0.0`.
3. A compatible PokePC follower-sprite provider.

## Installation

### Launcher / Mod Index

Import the release ZIP directly through the Gen1Recomp launcher. The archive is already packaged in the layout expected by the Mod Index.

### Manual installation

1. Download the release archive.
2. Remove any older `dramatic_sky_ride` folder.
3. Create `mods/dramatic_sky_ride/`.
4. Extract the ZIP contents directly into that folder.
5. Confirm `mods/dramatic_sky_ride/manifest.json` exists.
6. Fully restart Gen1Recomp.

## Development status

Feature development is paused after alpha.15. Future work will primarily address bugs and compatibility regressions. Deferred features are documented in [`backlog/`](backlog/README.md).

## Known limitations

- Rider seating uses procedural offsets rather than dedicated seated trainer sprites.
- Advanced geometry-based roof and building collision detection is not implemented.
- Some follower sheets may still require visual offset tuning.
- This remains an alpha and should be tested with the exact Gen1Recomp, Dramatic Shape and follower-provider versions used by the player.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
