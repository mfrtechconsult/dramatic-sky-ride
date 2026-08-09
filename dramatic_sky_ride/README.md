# Dramatic Sky Ride 0.1.6-rc.2 — development

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

`0.1.6-rc.2` is the current development state of `compat/wilds-of-kanto`. It has not been published as a prerelease yet.

## Native 2D flight

A voxel provider is **no longer required to fly**.

DSR now treats flight as one renderer-independent mechanic. Movement, collision, altitude, progression, encounters, battles and map transitions use the same flight state whether the game is displayed in flat 2D, a voxel camera or Stadium 3D.

The new `FLIGHT RENDERER` option defaults to:

- **2D SPRITES** — preferred/default. In the normal flat overworld, DSR composes the cropped trainer first and the flying Pokémon over it so the mount body naturally hides the rider crop line. Existing Pokédex-proportional mount sizing and per-species size options are reused directly.
- **STADIUM 3D** — explicit opt-in. It becomes effective only when Pokémon Stadium Overworld Models is installed and a voxel pipeline is active. If either requirement is unavailable, DSR falls back to 2D without blocking takeoff.

With a voxel provider active and `2D SPRITES` selected, DSR keeps its existing Pokémon billboard presentation rather than switching to Stadium automatically.

## Optional voxel providers

For voxel world/camera rendering, install one supported provider:

- **Battle Art Voxel Fork 1.7.6+** — `BATTLE_ART_VOXEL_FORK`;
- **Dramaless Shape 1.6.4+** — `DRAMALESS_SHAPE`.

Battle Art is preferred automatically if both are installed. The retired upstream `DRAMATIC_SHAPE` id remains only as a best-effort compatibility fallback for older manual installations.

## Pokémon sprite / follower providers

DSR can obtain compatible overworld Pokémon art from:

- **Wilds of Kanto** — `overworld_wild_spawns`;
- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`.

When Wilds of Kanto is present it can remain the authoritative follower runtime, avoiding two mods competing for follower lifecycle ownership.

## Public flight compatibility

The stable renderer-independent state follows the same small shape used by Shane's Free Fly ecosystem:

- `isFlying()` — true while DSR flight is active;
- `altitude()` — current DSR world-space altitude, or 0 on the ground;
- `mount()` — `{ species, level }` for the active flying mount, or nil.

Existing Stadium compatibility aliases remain available, but `mountSpecies()` now returns a mount only when `STADIUM 3D` is effectively enabled. Installing the Stadium mod alone therefore does not opt DSR into a 3D flying mount.

Additional renderer inspection is available through `flightRendering` and `stadiumCompatibility`.

`currentLift()` is intentionally not faked because the current Stadium bridge treats it as optional and its vertical semantics differ from DSR's absolute world-space altitude.

## Wilds of Kanto compatibility

- Wilds can provide mount sprites without forcing PokéPC Followers as a hard dependency.
- DSR uses a cooperative/self-healing overworld update chain rather than restoring stale function snapshots.
- Dramatic Deep Dive can compose around DSR's public compatibility guard.
- Regression coverage exercises Wilds + DSR + Deep Dive/Kanto Dive with both supported voxel providers.

## Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR uses its public API for ambient airborne Pokémon and consumes the exact visible species/level when an aerial interception starts a battle.

## Flying Music

`FLYING MUSIC` defaults to `None`.

If installed, DSR can reuse the existing Surf/Bike OGG files from:

- `Music_FRLG`;
- `Music_HGSS`;
- `Music_LGPE`.

DSR does not copy or redistribute those audio assets. Battle, victory and jingle cues retain priority, and normal map/Surf music is restored after landing.

The local `audio/flying/tracks.lua` catalog remains available for future redistributable or user-supplied tracks.

## Controls

### Flying

Supported flying mounts: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

- Keyboard: `H` toggles Flight.
- Controller: `X` toggles Flight in free-roam.
- `R2/L2` or `Page Up/Page Down`: manual altitude.
- In voxel `1ST` / `3RD`, camera look can control altitude when `CAMERA ALTITUDE` is enabled.

### Ground Ride

Supported Ground Ride mounts: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros and Snorlax.

- Flat 2D / Battle Art keyboard: `G`.
- Dramaless keyboard: `J`, because Dramaless reserves `G` for V-GRID.
- Controller: `Y`.

### Visible Surf

Supported visible Surf mounts: Blastoise, Tentacruel, Gyarados and Lapras. Native Surf movement, collision and progression remain authoritative.

## Speed and size

- `FLIGHT SPEED`: 50% to 200%, default 100%.
- `GROUND SPEED`: 50% to 200%, default 100%.
- Pokédex-proportional mount sizing remains enabled by default, with per-species overrides.

Species profiles, Flight boost and Ground gallop remain meaningful on top of the global speed settings.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- No voxel provider required for native 2D flight.
- Optional voxel providers: Battle Art Voxel Fork `>=1.7.6 <2.0.0` or Dramaless Shape `>=1.6.4 <2.0.0`.
- Compatible sprite/follower providers: Wilds of Kanto or PokéPC Followers.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional Stadium renderer: `STADIUM_OVERWORLD_MODELS`, explicit opt-in from DSR options.
- Optional Flying Music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` remains a conflicting alternative player-flight engine.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel cameras and 3D presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — compatible Gen 1 follower/overworld sprite provider.
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto follower/wild overworld ecosystem.
- ShaneHudson/gen1recomp-mods — Free Fly/Wild Skies public flight and hook interoperability patterns.
- randyadr/3D-Pokemon-Sprites — Pokémon Stadium Overworld Models integration target.
- DarioMelo/Gen1Recomp-MusicMods — optional FRLG/HGSS/LGPE music providers.

## Testing

For bug reports include Gen1Recomp version, renderer selection, voxel provider/version if used, Wilds/PokéPC setup, Wild Skies version, Stadium version if used, music pack/version if used, mount species, camera mode and exact reproduction steps.
