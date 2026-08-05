# Dramatic Sky Ride — Discord announcement

## Message 1/3 — Overview and requirements

**Dramatic Sky Ride — v0.1.0-alpha.12**

Hi! I’m sharing the first public alpha of **Dramatic Sky Ride**, an independent gameplay add-on for **Gen1Recomp**.

It adds manual, controllable overworld flight on large Generation 1 Pokémon. Instead of using a simple Fly transition, you can take off, move freely, change altitude, boost, explore in first or third person, and choose where to land.

### Required before installing

1. **Gen1Recomp** — a compatible current build.
2. **Dramatic Shape Voxel Mod v1.6.0 or newer** — required for the 3D world, first-person/third-person cameras and free movement:
   https://github.com/DramaticShape/DramaticShapeVoxelMod
3. **A compatible PokePC follower-sprite installation** — `PokePC Followers` or `PokePC Followers Voxel Merge`. Sky Ride reads the existing 16×96 follower sheets from that mod; it does not redistribute Pokémon artwork.

**Followers EX is optional.** Its follower entities are supported and are temporarily hidden during flight, then restored after landing.

Install the prerequisite mods first, verify that Dramatic Shape and the follower sprites work, and only then install Dramatic Sky Ride.

Project and download:
https://github.com/mfrtechconsult/dramatic-sky-ride

Use **Code → Download ZIP**, then copy the included `dramatic_sky_ride` folder into your Gen1Recomp `mods` directory.

## Message 2/3 — Features, mounts and controls

### Current features

- Free, continuous analogue movement in `1ST` and `3RD` voxel views.
- First-person camera positioned at the trainer’s eye level.
- Optional smooth camera follow in first and third person.
- Mouse/right-stick input always overrides camera follow immediately.
- Manual altitude control and smooth boosting.
- Controlled landings with green/red validity feedback.
- Dynamic ground shadow.
- Stable wing animation without vertical camera bobbing.
- Normal access to the pause menu while airborne.
- Safety handling for map changes, warps, scripts and follower restoration.
- `STORY SAFE` mode to reduce the risk of flying through runtime quest entities.
- No automatic destination or fast-travel system: flight is fully manual.

### Supported mounts

Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

Each compatible, conscious Pokémon in the party receives its own **RIDE & FLY** action. If several are available, you choose the mount directly from the party menu. The quick shortcut then reuses the last selected valid mount; if it is unavailable, the first valid compatible Pokémon in party order is used.

### Default controls

- Move: configured movement keys / left stick
- Look: mouse / right stick
- Ascend: `Page Up` / `R2`
- Descend: `Page Down` / `L2`
- Boost: the game’s `B` action
- Land: the game’s `A` action
- Quick mount or request landing: `F` / `SELECT + R1`

## Message 3/3 — Installation, alpha status and feedback

### Installation

1. Remove any older `dramatic_sky_ride` folder.
2. Install and test Dramatic Shape Voxel Mod.
3. Install a compatible PokePC follower-sprite mod and confirm its Pokémon sprites are available.
4. Download the repository ZIP, then copy its `dramatic_sky_ride` folder so the final path is:
   `mods/dramatic_sky_ride/manifest.json`
5. Fully restart Gen1Recomp.
6. Put a supported Pokémon in the party, open its party submenu and choose **RIDE & FLY**.

### Alpha status / known limitations

This is still an alpha and needs real-world testing across maps, controllers and display modes.

- Rider offsets on the newly added mounts may still need per-Pokémon adjustment.
- Roof and obstacle detection currently uses safety approximations rather than complete voxel-geometry analysis.
- The trainer still uses the normal cropped overworld pose; a dedicated seated riding pose is planned later.
- Quest compatibility is defensive, not guaranteed for every third-party script.
- First-person and camera-follow comfort may require further tuning based on player feedback.

Useful bug reports should include:

- Gen1Recomp version
- Dramatic Shape version
- follower mod and version
- game version: Red, Blue or Yellow
- camera mode
- mount used
- keyboard/controller model
- exact reproduction steps
- screenshot, video or log when possible

Source, download and testing sheet:
https://github.com/mfrtechconsult/dramatic-sky-ride

Feedback and compatibility reports are welcome.
