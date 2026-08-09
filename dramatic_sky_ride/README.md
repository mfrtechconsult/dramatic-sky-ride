# Dramatic Sky Ride 0.1.6-rc.1

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

> **Compatibility preview:** `0.1.6-rc.1` is built from the `compat/wilds-of-kanto` branch so the next ecosystem update can be tested before promotion to `main`.

## Setup

Install one supported voxel provider:

- **Battle Art Voxel Fork 1.7.6+** — `BATTLE_ART_VOXEL_FORK`;
- **Dramaless Shape 1.6.4+** — `DRAMALESS_SHAPE`.

Battle Art is preferred automatically if both are installed.

For Pokémon overworld/follower sprites, this compatibility branch can work with either:

- **Wilds of Kanto** — `overworld_wild_spawns`;
- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`.

The retired `DRAMATIC_SHAPE` id remains only as a best-effort runtime fallback for older manual installations.

## Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR works without it, but DSR + Wild Skies remains the intended airborne setup: visible Pokémon populate the sky and can be intercepted into battles against the exact visible species and level.

DSR integrates through Wild Skies' public API and restores the active mount/airborne state after battle.

## What's new in 0.1.6-rc.1

### Wilds of Kanto compatibility

- Wilds of Kanto can act as an authoritative follower/sprite runtime for DSR.
- DSR can resolve compatible mount sprites through Wilds without forcing PokéPC Followers as a hard dependency.
- Added cooperative update-hook protection so DSR, Wilds and compatible overworld mods do not silently replace each other's update wrappers.
- Added regression coverage for the Wilds + DSR + Deep Dive / Kanto Dive compatibility stacks.

### Pokémon Stadium Overworld Models compatibility

DSR now exposes a small read-only public flight API for `STADIUM_OVERWORLD_MODELS` and similar integrations:

- `isFlying()`
- `currentAltitude()`
- `mountSpecies()`
- `stadiumCompatibility`

This allows a compatible renderer to identify the active flying Pokémon and position its 3D model at the correct airborne altitude without taking ownership of DSR movement.

`currentLift()` is intentionally not exposed with an approximate value in this preview because Stadium already treats it as optional.

### Flying Music

A new optional **FLYING MUSIC** setting is available. `None` is the default and keeps normal map music unchanged.

When compatible DarioMelo music packs are installed and enabled, DSR reuses their existing OGG files directly and adds their Surf/Bike themes as selectable flight music:

- **Music-FRLG** (`Music_FRLG`): FRLG Surf / Bike;
- **Music-HGSS** (`Music_HGSS`): HGSS Surf / Bike;
- **Music-LGPE** (`Music_LGPE`): LGPE Surf / Bike.

DSR does **not** copy or redistribute these audio assets. The source pack remains installed separately and owns its files.

Battle themes, victory cues, jingles and other higher-priority music remain authoritative. Landing restores normal map or Surf music.

A local `audio/flying/tracks.lua` catalog is also available for future redistributable or user-supplied flight tracks.

## Controls

### Flying

Supported flying mounts: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

- Keyboard: `H` toggles Flight.
- Controller: `X` toggles Flight in free-roam.
- `R2/L2` or `Page Up/Page Down`: manual altitude.
- In voxel `1ST` / `3RD`, looking up/down can control altitude when `CAMERA ALTITUDE` is enabled.

### Ground Ride

Supported Ground Ride mounts: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros and Snorlax.

- Keyboard with Battle Art: `G` toggles Ground Ride.
- Keyboard with Dramaless Shape: `J` toggles Ground Ride because Dramaless reserves `G` for V-GRID.
- Controller: `Y` toggles Ground Ride.

### Visible Surf

Supported visible Surf mounts: Blastoise, Tentacruel, Gyarados and Lapras.

Native Surf movement, collision, progression and music remain authoritative unless a Flying Music selection is actively replacing the map cue during DSR flight.

## Speed settings

- `FLIGHT SPEED`: 50% to 200%, default 100%.
- `GROUND SPEED`: 50% to 200%, default 100%.

Species profiles, Flight boost and Ground gallop remain meaningful on top of these multipliers.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- Voxel provider: Battle Art Voxel Fork `>=1.7.6 <2.0.0` **or** Dramaless Shape `>=1.6.4 <2.0.0`.
- Pokémon sprite/follower provider on this branch: Wilds of Kanto or PokéPC Followers.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional Stadium renderer integration: `STADIUM_OVERWORLD_MODELS`.
- Optional Flying Music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` remains a conflicting alternative player-flight engine.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel provider, cameras and 3D battle presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — compatible Gen 1 follower/overworld sprite provider.
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto follower/wild overworld ecosystem.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration API and airborne ecosystem.
- randyadr/3D-Pokemon-Sprites — Pokémon Stadium Overworld Models integration target.
- DarioMelo/Gen1Recomp-MusicMods — FRLG, HGSS and LGPE music packs and OGG intro/loop convention used by optional Flying Music integration.

## Testing

`0.1.6-rc.1` is a preview build. Please include Gen1Recomp version, voxel provider/version, Wilds or PokéPC setup, Wild Skies version if installed, Stadium version if installed, music pack/version if used, camera mode, mount species and reproduction steps in bug reports.
