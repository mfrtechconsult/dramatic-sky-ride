# Dramatic Sky Ride 0.1.6

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## 0.1.6 highlights

- **Native 2D flight**: a voxel provider is no longer required to take off.
- **Wilds of Kanto or PokéPC Followers** can provide mount sprites. The maintained `mfrtechconsult/PokePCFollowers` fork is the preferred PokéPC target.
- **Generation II mounts** are supported through National Pokédex data when those Pokémon exist in the loaded game.
- **Suicune** is the unique amphibious Ground Ride mount and can run from land onto water and back without dismounting once Surf progression is unlocked.
- **Optional voxel rendering** remains available through Battle Art Voxel Fork or Dramaless Shape.
- **Wild Skies** remains supported for visible airborne Pokémon and exact intercepted species/level battles.
- **Flying Music** can reuse installed FRLG, HGSS or LGPE Surf/Bike tracks without redistributing audio.
- Compatibility guards protect the active mount logic when Wilds or companion mods rebuild overworld hooks.

## Pokémon sprite / follower providers

Normal setups should use **one** of these:

- **Wilds of Kanto** (`overworld_wild_spawns`), or
- **PokéPC Followers — maintained mfrtechconsult fork** (`PokePCFollowers_VoxelMerge`).

They are not required together.

## Generation II mounts

### Flight

Noctowl, Crobat, Xatu, Skarmory, Lugia and Ho-Oh.

### Ground Ride

Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, **Suicune** and Tyranitar.

### Visible Surf

Feraligatr, Mantine, Kingdra and Lugia.

Generation II support is data-driven. Crystal 251 is supported, but DSR does not hard-depend on that mod id.

## Suicune — seamless land/water running

Suicune is the only amphibious Ground Ride mount. Once normal Surf progression is available, it can run directly from land to water and back while preserving its Ground Ride presentation, movement state and gallop continuity.

Normal Surf progression and map restrictions remain authoritative.

## Followers while mounted

Followers are hidden by default while mounted.

`GROUND FOLLOWERS` can be enabled for **land Ground Ride only**. Followers remain hidden during Flight and Surf.

Known limitation in 0.1.6: when `GROUND FOLLOWERS` is enabled, the Pokémon currently being ridden can still appear in the follower trail. The option is OFF by default.

## Optional voxel providers

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0`
- **Dramaless Shape** `>=1.6.4 <2.0.0`

Neither is required for native 2D flight. Battle Art is preferred automatically if both are installed.

## Controls

| Action | Flat 2D / Battle Art | Dramaless | Controller |
|---|---|---|---|
| Flight | `H` | `H` | `X` |
| Ground Ride | `G` | `J` | `Y` |
| Ascend / descend | `Page Up` / `Page Down` | `Page Up` / `Page Down` | `R2` / `L2` |

`F` remains free for Gen1PC Overworld Encounters follower attacks. Dramaless reserves `G` for V-GRID.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- Native 2D flight requires no voxel provider.
- Wilds of Kanto **or** the maintained `mfrtechconsult/PokePCFollowers` fork can provide compatible Pokémon sprites.
- Generation II mounts activate only when those species exist in the loaded game data.
- Wild Skies `>=1.4.1 <2.0.0` is optional and recommended.
- Optional music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` conflicts as an alternative player-flight engine.

## Known limitations

- `GROUND FOLLOWERS` may still show the active Ground Ride mount as a follower.
- With Wilds of Kanto, Suicune may briefly show the ordinary Surf mount during the post-battle return before Suicune is restored.
- The optional Stadium renderer remains experimental and is not part of the validated 0.1.6 highlights.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
