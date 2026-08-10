# Dramatic Sky Ride 0.1.6-rc.2 — development

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

`0.1.6-rc.2` is the current development state of `compat/wilds-of-kanto`. It has not been published as a prerelease yet.

## Native 2D flight

A voxel provider is **no longer required to fly**.

DSR now treats flight as one renderer-independent mechanic. Movement, collision, altitude, progression, encounters, battles and map transitions use the same flight state whether the game is displayed in flat 2D, a voxel camera or Stadium 3D.

The `FLIGHT RENDERER` option defaults to:

- **2D SPRITES** — preferred/default. In the normal flat overworld, DSR composes the cropped trainer first and the flying Pokémon over it. Existing Pokédex-proportional mount sizing and per-species size options are reused directly.
- **STADIUM 3D** — explicit opt-in. It becomes effective only when Pokémon Stadium Overworld Models is installed, a voxel pipeline is active and the selected species is supported. Otherwise DSR falls back to 2D without blocking takeoff.

Generation II flying mounts therefore remain safe 2D billboards with the current Stadium 1 provider instead of becoming invisible. A future 3D provider can advertise explicit species support through its public API.

## Optional voxel providers

For voxel world/camera rendering, install one supported provider:

- **Battle Art Voxel Fork 1.7.6+** — `BATTLE_ART_VOXEL_FORK`;
- **Dramaless Shape 1.6.4+** — `DRAMALESS_SHAPE`.

Battle Art is preferred automatically if both are installed. The retired upstream `DRAMATIC_SHAPE` id remains only as a best-effort compatibility fallback for older manual installations.

## Pokémon sprite / follower providers

DSR can obtain compatible overworld Pokémon art from:

- **Wilds of Kanto** — `overworld_wild_spawns`;
- **PokéPC Followers — maintained mfrtechconsult compatibility fork** — `PokePCFollowers_VoxelMerge`.

The officially tested PokéPC target is `mfrtechconsult/PokePCFollowers`. That fork deliberately retains the original `PokePCFollowers_VoxelMerge` mod id for save/install compatibility and exposes explicit provider metadata plus the common `resolveFollowerSprite()` provider API. Older PokéPC builds sharing the same id remain a best-effort legacy fallback.

When Wilds of Kanto is present it can remain the authoritative follower runtime, avoiding two mods competing for follower lifecycle ownership.

Third-party sprite packs can also dress DSR's **airborne 2D mount** through the same small contract used by Shane's Free Fly / Wild Skies family:

- `registerSpriteSource({ id|mod, resolve(exports, game, species, dex) })`;
- `unregisterSpriteSource(id)`.

The resolver returns an animated walker-style SpriteRenderer definition (`image`, `frames`, `walker`, `trueColor`). Registered sources take priority over DSR's built-in Wilds/PokéPC adapters and are re-consulted when the source mod changes options. Stadium models remain a separate explicit renderer.

## Generation II mounts

Generation II support is based on **National Pokédex data**, not a hard dependency on Crystal 251. Crystal 251 or another compatible content mod can provide Pokémon 152–251 in the game, while Wilds of Kanto or the maintained PokéPC fork supplies the overworld mount art.

Provider lookup retries by National Dex if species-name punctuation differs, so names such as Ho-Oh do not require every provider to use exactly the same internal key.

### Flying

Generation I: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair, Dragonite.

Generation II: **Noctowl, Crobat, Xatu, Skarmory, Lugia, Ho-Oh**.

### Ground Ride

Generation I: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros, Snorlax.

Generation II: **Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, Suicune, Tyranitar**.

### Visible Surf

Generation I: Blastoise, Tentacruel, Gyarados, Lapras.

Generation II: **Feraligatr, Mantine, Kingdra, Lugia**.

### Suicune — seamless land/water Ground Ride

Suicune is intentionally the **only amphibious Ground Ride mount**.

Once normal Surf progression is available, Suicune can run directly from land onto water and back onto land without dismounting, opening the Surf flow, changing to the Visible Surf subsystem or replacing its terrestrial running sprite. Ground Ride remains the visual and lifecycle owner for the complete trip.

DSR arms the engine's native Surf collision state immediately before a valid water step. It does not force a rejected collision after the fact, so normal water tile-pair rules, map connections, Wilds encounters and other collision hooks remain authoritative. Cycling Road and Seafoam Surf restrictions are preserved. The same continuity is handled across map seams and after battles on water when Suicune remains usable.

Ground dust is suppressed while Suicune is on water. Gallop state and the mounted presentation remain continuous across the shoreline.

## Public flight compatibility

The stable renderer-independent state follows the same small shape used by Shane's Free Fly ecosystem:

- `isFlying()` — true while DSR flight is active;
- `altitude()` — current DSR world-space altitude, or 0 on the ground;
- `mount()` — `{ species, level }` for the active flying mount, or nil.

Existing Stadium compatibility aliases remain available, but `mountSpecies()` returns a mount only when `STADIUM 3D` is effectively enabled for that species. Installing Stadium alone therefore does not opt DSR into a 3D flying mount.

Additional renderer inspection is available through `flightRendering` and `stadiumCompatibility`.

## Wilds of Kanto compatibility

- Wilds can provide Generation I and II mount sprites without forcing PokéPC Followers as a hard dependency.
- DSR uses a cooperative/self-healing overworld update chain rather than restoring stale function snapshots.
- The Generation II/Suicune update layer is part of that protected chain.
- Dramatic Deep Dive can compose around DSR's public compatibility guard.
- Regression coverage exercises Wilds + DSR + Deep Dive/Kanto Dive with both supported voxel providers.

## Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR uses its public API for ambient airborne Pokémon and consumes the exact visible species/level when an aerial interception starts a battle.

## Flying Music

`FLYING MUSIC` defaults to `None`.

If installed, DSR can reuse existing Surf/Bike OGG files from `Music_FRLG`, `Music_HGSS` and `Music_LGPE`. DSR does not copy or redistribute those audio assets. Battle, victory and jingle cues retain priority, and normal map/Surf music is restored after landing.

## Controls

### Flying

- Keyboard: `H` toggles Flight.
- Controller: `X` toggles Flight in free-roam.
- `R2/L2` or `Page Up/Page Down`: manual altitude.
- In voxel `1ST` / `3RD`, camera look can control altitude when `CAMERA ALTITUDE` is enabled.

### Ground Ride

- Flat 2D / Battle Art keyboard: `G`.
- Dramaless keyboard: `J`, because Dramaless reserves `G` for V-GRID.
- Controller: `Y`.

### Visible Surf

Native Surf movement, collision and progression remain authoritative. Suicune is excluded from the normal Visible Surf roster because its unique amphibious Ground Ride owns both land and water presentation.

## Speed and size

- `FLIGHT SPEED`: 50% to 200%, default 100%.
- `GROUND SPEED`: 50% to 200%, default 100%.
- Pokédex-proportional mount sizing remains enabled by default, with per-species overrides including the Generation II mount roster.
- Generation II Ground Ride species receive curated base/gallop speed profiles while retaining the mature stamina/acceleration behavior.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default.

Suicune water running uses the normal SURF field-move progression gate and preserves forced-bike and Seafoam restrictions.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- No voxel provider required for native 2D flight.
- Optional voxel providers: Battle Art Voxel Fork `>=1.7.6 <2.0.0` or Dramaless Shape `>=1.6.4 <2.0.0`.
- Compatible sprite/follower providers: Wilds of Kanto or the maintained `mfrtechconsult/PokePCFollowers` fork.
- Generation II mounts activate only when their Pokémon records exist in the current game data; Crystal 251 is supported but not required by id.
- Legacy PokéPC builds using the shared mod id remain best-effort fallbacks.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional Stadium renderer: `STADIUM_OVERWORLD_MODELS`, explicit opt-in with species-safe 2D fallback.
- Optional Flying Music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` remains a conflicting alternative player-flight engine.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel cameras and 3D presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- mfrtechconsult/PokePCFollowers — maintained PokéPC compatibility fork used by DSR, including Gen 1/2 sprite-provider support and Pokédex-proportional sizing.
- gamecorner-033/PokePCFollowers — original PokéPC follower project and upstream foundation.
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto follower/wild overworld ecosystem and Generation II GSC sprite provider support.
- ShaneHudson/gen1recomp-mods — Free Fly/Wild Skies public flight and hook interoperability patterns.
- randyadr/3D-Pokemon-Sprites — Pokémon Stadium Overworld Models integration target.
- DarioMelo/Gen1Recomp-MusicMods — optional FRLG/HGSS/LGPE music providers.

## Testing

For bug reports include Gen1Recomp version, renderer selection, voxel provider/version if used, Wilds/PokéPC setup, Generation II content provider if used, Wild Skies version, Stadium version if used, music pack/version if used, mount species, camera mode and exact reproduction steps.
