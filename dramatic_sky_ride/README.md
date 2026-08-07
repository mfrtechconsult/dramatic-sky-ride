# Dramatic Sky Ride — alpha.15.4

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp** when used with **Dramatic Shape Voxel Mod**.

## Alpha.15.4 sizing and compatibility

- Keeps the alpha.15.1 combined 20-option schema and saved option compatibility.
- Blocks manual Surf while airborne; landing on water is the only way to enter Surf directly from flight.
- Keeps compatibility with Gen1Recomp `>=0.1.69 <2.0.0` and targets Dramatic Shape `>=1.7.0 <2.0.0`.
- Resolves Dramatic Shape terrain heights through its exported companion API first, including Mod Manager ZIP installs.
- Retains the unpacked-directory terrain resolver as a compatibility fallback.
- Does not change the validated alpha.14 flight camera.
- Adds the GitHub repository identifier used by the launcher and Mod Index for update tracking.
- Uses a Mod Index-compatible release ZIP with `manifest.json` at the archive root.

## Alpha.15 highlights

### Ground Ride

Supported mounts:

- Arcanine
- Rapidash
- Dodrio
- Rhyhorn
- Rhydon
- Kangaskhan
- Tauros
- Snorlax

Use `G` on keyboard or `SELECT + L1` on controller to mount or dismount.

Ground Ride now includes:

- species-specific speed, acceleration, gallop strength and stamina;
- a visible stamina HUD and dust while galloping with `B`;
- seamless boost continuity through connected maps in 2D, `1ST` and `3RD`;
- safe two-way traversal of official low ledges;
- species-weighted jump arcs, landing dust, sound and vibration;
- remembered mount selection after party reordering;
- safe restoration after wild and trainer battles;
- no remount when the selected mount fainted, left the party or became incompatible;
- ordinary NPC conversations and sign reading without dismounting;
- automatic dismount before incompatible native actions such as item pickup, PCs, Cut, Surf, fishing, Fly, Dig, Teleport and Strength boulder pushes.

### Flying

Use `F` on keyboard or `SELECT + R1` on controller.

The validated alpha.14 camera behaviour is preserved. Alpha.15 also keeps altitude, boost and rider rendering stable across battles, without leaving a ghost trainer sprite on the map.

### Visible Surf mounts

The `MOUNTS` menu can select:

- Blastoise
- Tentacruel
- Gyarados
- Lapras

Native Surf movement, collisions, music and transitions remain in control. While flying, manual Surf is unavailable: the only way to enter Surf from the air is to land on a valid water cell with a Surf-capable party.

### Pokédex-proportional mount sizing

- Every flying, Ground Ride and visible Surf mount is visually scaled from its Gen 1 Pokédex height.
- A 1.70 m Pokémon uses the original 16 px mount size; other species scale proportionally.
- The MODS > Dramatic Sky Ride > OPTIONS screen includes an individual numeric size control for all 22 mounts.
- `100` means the Pokédex-derived size; each species can be adjusted from 50 to 200 in 5-point steps.
- `POKEDEX SIZES` can be disabled to use the original 16 px size as the 100 baseline.
- Rider seat height follows the resized mount while the trainer remains human-sized.
- Scaling is visual only: collisions, cells, movement, encounters and map logic are unchanged.

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

- Gen1Recomp `>=0.1.69 <2.0.0` with Mod API 2 support.
- Dramatic Shape Voxel Mod `>=1.7.0 <2.0.0`.
- A compatible PokePC follower-sprite provider.

## Development status

Alpha.15.4 keeps the alpha.15.3 Pokédex-proportional sizing work and adds Mod Index / launcher release compatibility. Broader feature work remains paused outside targeted improvements and bug/compatibility fixes. Deferred improvements are documented in the repository `backlog/` directory.

## Bug reports

Include the Gen1Recomp version, Dramatic Shape version, follower provider, Red/Blue/Yellow version, camera mode, mount, input device, exact reproduction steps and screenshots or logs when available.
