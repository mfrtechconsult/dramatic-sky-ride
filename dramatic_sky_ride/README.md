# Dramatic Sky Ride 0.1.6

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Native 2D flight

A voxel provider is **no longer required to fly**.

DSR uses one renderer-independent flight mechanic: movement, collision, altitude, progression, encounters, battles and map transitions share the same flight state in flat 2D and supported voxel cameras.

`2D SPRITES` is the default flight presentation. The flat overworld reuses the existing Pokédex-proportional mount sizing and per-species size options.

## Optional voxel providers

For voxel world/camera rendering, install one supported provider:

- **Battle Art Voxel Fork 1.7.6+** — `BATTLE_ART_VOXEL_FORK`;
- **Dramaless Shape 1.6.4+** — `DRAMALESS_SHAPE`.

Battle Art is preferred automatically if both are installed. Neither is required for native 2D flight.

## Pokémon sprite / follower providers

Normal setups should use one of:

- **Wilds of Kanto** — `overworld_wild_spawns`;
- **PokéPC Followers — maintained mfrtechconsult compatibility fork** — `PokePCFollowers_VoxelMerge`.

The officially tested PokéPC target is `mfrtechconsult/PokePCFollowers`. It retains the original mod id for save/install compatibility and exposes the common public sprite-provider API used by DSR. Older PokéPC builds sharing the same id remain best-effort legacy fallbacks.

Wilds of Kanto and PokéPC Followers are alternatives for the normal user setup; they are not required together.

Third-party sprite packs can also dress DSR's airborne 2D mount through:

- `registerSpriteSource({ id|mod, resolve(exports, game, species, dex) })`;
- `unregisterSpriteSource(id)`.

Compatible sources return an animated walker-style sprite definition. Registered sources can override DSR's built-in Wilds/PokéPC sprite lookup without replacing the flight mechanic.

## Generation II mounts

Generation II support is based on **National Pokédex data**, not a hard dependency on Crystal 251. Crystal 251 or another compatible content mod can provide Pokémon 152–251, while Wilds of Kanto or the maintained PokéPC fork supplies compatible overworld art.

### Flying

Generation I: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair, Dragonite.

Generation II: **Noctowl, Crobat, Xatu, Skarmory, Lugia, Ho-Oh**.

### Ground Ride

Generation I: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros, Snorlax.

Generation II: **Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, Suicune, Tyranitar**.

### Visible Surf

Generation I: Blastoise, Tentacruel, Gyarados, Lapras.

Generation II: **Feraligatr, Mantine, Kingdra, Lugia**.

## Suicune — seamless land/water Ground Ride

Suicune is intentionally the **only amphibious Ground Ride mount**.

Once normal Surf progression is available, Suicune can run directly from land onto water and back onto land without dismounting or switching to the normal Visible Surf presentation. Ground Ride remains the visual and lifecycle owner for the trip.

Normal water collision, Surf progression, map connections and map restrictions remain authoritative. Gallop state stays continuous across the shoreline.

The same land/water transition support is applied to the supported 1ST/3RD free-camera movement paths.

## Followers while mounted

Followers are hidden by default whenever a DSR mount is active.

`GROUND FOLLOWERS` can be enabled for **land Ground Ride only**. Flight and every Surf/water state keep followers hidden.

Known limitation in 0.1.6: when `GROUND FOLLOWERS` is enabled, the Pokémon currently used as the Ground Ride mount may still appear in the follower trail. The option is OFF by default.

## Wilds of Kanto compatibility

- Wilds can provide Generation I and II mount sprites without forcing PokéPC Followers as a hard dependency.
- DSR uses cooperative/self-healing overworld update protection rather than restoring stale function snapshots.
- Generation II and Suicune runtime layers are part of the protected update chain.
- Gen II mount facing is reasserted after late Wilds updates in supported 1ST/3RD camera modes.
- Suicune preserves its amphibious Ground Ride across seamless map connections.

Known Wilds-only visual limitation: after a battle on water, Suicune can briefly show the ordinary Surf mount before the amphibious Ground Ride presentation is restored.

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
- In supported voxel `1ST` / `3RD` modes, camera look can control altitude when `CAMERA ALTITUDE` is enabled.

### Ground Ride

- Flat 2D / Battle Art keyboard: `G`.
- Dramaless keyboard: `J`, because Dramaless reserves `G` for V-GRID.
- Controller: `Y`.

### Visible Surf

Native Surf movement, collision and progression remain authoritative. Suicune is excluded from the normal Visible Surf roster because its unique amphibious Ground Ride owns both land and water presentation.

## Speed and size

- `FLIGHT SPEED`: 50% to 200%, default 100%.
- `GROUND SPEED`: 50% to 200%, default 100%.
- Pokédex-proportional mount sizing remains enabled by default, with per-species overrides including Generation II mounts.
- Generation II Ground Ride species receive curated base/gallop speed profiles while retaining the existing stamina/acceleration behavior.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default.

Suicune water running uses the normal SURF field-move progression gate and preserves existing forced-bike and Seafoam restrictions.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- No voxel provider required for native 2D flight.
- Optional voxel providers: Battle Art Voxel Fork `>=1.7.6 <2.0.0` or Dramaless Shape `>=1.6.4 <2.0.0`.
- Compatible sprite/follower providers: Wilds of Kanto **or** the maintained `mfrtechconsult/PokePCFollowers` fork.
- Generation II mounts activate only when their Pokémon records exist in the current game data; Crystal 251 is supported but not required by id.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional Flying Music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` remains a conflicting alternative player-flight engine.

The optional Stadium renderer remains present as an experimental compatibility path but is not part of the validated 0.1.6 feature highlights.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel cameras and 3D presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- mfrtechconsult/PokePCFollowers — maintained PokéPC compatibility fork used by DSR, including Gen 1/2 sprite-provider support and Pokédex-proportional sizing.
- gamecorner-033/PokePCFollowers — original PokéPC follower project and upstream foundation.
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto follower/wild overworld ecosystem and Generation II GSC sprite provider support.
- ShaneHudson/gen1recomp-mods — Free Fly/Wild Skies public flight and hook interoperability patterns.
- DarioMelo/Gen1Recomp-MusicMods — optional FRLG/HGSS/LGPE music providers.

## Testing

For bug reports include Gen1Recomp version, voxel provider/version if used, Wilds or PokéPC setup, Generation II content provider if used, Wild Skies version, music pack/version if used, mount species, camera mode and exact reproduction steps.
