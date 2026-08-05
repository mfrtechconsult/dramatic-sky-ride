# Dramatic Sky Ride — alpha.13

A gameplay add-on for **Gen1Recomp** and **Dramatic Shape Voxel Mod** that adds fully controllable flying mounts to the `FULL`, `15`, `35`, `50`, `75`, `1ST` and `3RD` voxel views.

## Download

Download the ready-to-install archive from the **GitHub Releases** page:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

For normal installation, use the `dramatic_sky_ride-<version>.zip` asset attached to the release rather than the repository source ZIP.

## Alpha.13 changes

- Water becomes a valid landing surface when at least one Pokémon in the party knows `SURF`.
- Landing on water automatically enables Gen1Recomp's native surfing state, water collision rules and Surf music.
- The normal mount shortcut can take off again directly from the water.
- Without a Pokémon that knows `SURF`, the landing marker remains invalid and displays `SURF REQUIRED`.
- Flight remains fully manual, free and continuous in `1ST` and `3RD`.
- Automatic camera follow remains optional and never controls the mount.
- `AUTO FLY` and the Pokémon Stadium experiment remain completely removed.

## Supported mounts

The following conscious Pokémon receive a `RIDE & FLY` party action:

- Charizard — `follower_006.png`
- Pidgeot — `follower_018.png`
- Fearow — `follower_022.png`
- Golbat — `follower_042.png`
- Aerodactyl — `follower_142.png`
- Articuno — `follower_144.png`
- Zapdos — `follower_145.png`
- Moltres — `follower_146.png`
- Dragonair — `follower_148.png`
- Dragonite — `follower_149.png`

Dodrio, Butterfree, Beedrill, Scyther and small levitating Pokémon are intentionally excluded. Being able to learn Fly or leave the ground does not necessarily make a Pokémon large or strong enough to carry the trainer convincingly.

If several compatible Pokémon are in the party, each one receives its own `RIDE & FLY` action. The quick-mount shortcut reuses the last valid selected mount, or the first valid mount in party order when necessary.

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Move | Arrow keys / configured movement keys | Left stick / D-pad |
| Look | Mouse | Right stick |
| Ascend | `Page Up` | `R2` |
| Descend | `Page Down` | `L2` |
| Boost | Configured B action | In-game `B` |
| Land | Configured A action | In-game `A` |
| Quick mount / take off again | `F` | `SELECT + R1` |

On water, the same quick-mount shortcut leaves the Surf state and immediately starts a new flight with the last valid mount.

## Camera follow

With `CAMERA FOLLOW: ON`:

- in `3RD`, the camera gradually returns behind the actual flight path;
- in `1ST`, it smoothly follows direction changes without instant snapping;
- mouse or right-stick input immediately gives full control back to the player;
- automatic follow resumes after a short delay;
- reversing does not force a sudden automatic 180-degree turn.

With `CAMERA FOLLOW: OFF`, the camera remains fully manual.

## Main features

- Free analogue movement in `1ST` and `3RD`.
- First-person view from the trainer's eye position.
- Trainer hidden in first-person view.
- Normal pause-menu access while airborne.
- Manual altitude from 20 to 96 pixels.
- Automatic safety altitude above terrain and known large buildings.
- Green/red landing marker, including Surf-aware water validation.
- Dynamic ground shadow.
- Stable wing animation without vertical camera bobbing.
- Ground encounters, underfoot warps and trainer sight lines suspended during flight.
- `STORY SAFE` protection for runtime quest entities.
- Followers hidden during flight and restored after landing.
- `LAND FIRST` warnings for incompatible external shortcuts without forcing a normal landing.

## Required dependencies

Install and test these before Dramatic Sky Ride:

1. **Gen1Recomp**, using a build compatible with Mod API 2.
2. **Dramatic Shape Voxel Mod 1.6.0 or newer**, which provides the 3D world, `1ST`/`3RD` cameras and continuous free movement:
   https://github.com/DramaticShape/DramaticShapeVoxelMod
3. **A compatible PokePC follower-sprite provider**, either `PokePC Followers` or `PokePC Followers Voxel Merge`. Sky Ride reads the already-installed 16×96 follower sheets and does not redistribute Pokémon artwork.

`Followers EX` is optional but supported. Its follower entities are hidden during flight and restored after landing.

The PokePC dependency is marked optional in the manifest only because different variants use different mod identifiers. **In practice, one compatible PokePC sprite installation is required to display the mounts.**

## Installation

1. Download the archive attached to the desired GitHub release.
2. Remove any older `dramatic_sky_ride` folder.
3. Extract the archive into the Gen1Recomp `mods` directory.
4. Confirm that the final path is `mods/dramatic_sky_ride/manifest.json`.
5. Fully restart Gen1Recomp.

Expected structure:

```text
mods/
├── DramaticShapeVoxelMod/
├── PokePCFollowers/
└── dramatic_sky_ride/
    ├── manifest.json
    ├── main.lua
    ├── src/
    ├── mod.card
    ├── README.md
    └── TESTING.md
```

## Recommended options

```text
SHOW RIDER       ON
MANUAL ALTITUDE  ON
ALTITUDE DISPLAY TEMPORARY
VERTICAL SPEED   NORMAL
LANDING MARKER   ON
DYNAMIC SHADOW   ON
MOUNT SHORTCUT   ON
FLIGHT BOOST     ON
CAMERA FOLLOW    ON
SOUND & RUMBLE   ON
STORY SAFE       ON
```

## Known limitations

- Rider offsets for the newer mounts still need in-game visual verification.
- Complete geometry-based roof detection is not implemented yet.
- A dedicated seated trainer pose is planned for a later version.
- Quest compatibility is defensive and cannot guarantee compatibility with every third-party script.
- First-person comfort and camera-follow tuning may still change based on player feedback.

## Bug reports

Please include the Gen1Recomp version, Dramatic Shape version, follower mod, game version, camera mode, mount, input device, exact reproduction steps and any available screenshots, video or logs.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
