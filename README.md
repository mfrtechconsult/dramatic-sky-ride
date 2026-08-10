# Dramatic Sky Ride 0.1.6-rc.2 — development

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

> `0.1.6-rc.2` is the current development state of `compat/wilds-of-kanto`. The previously published `v0.1.6-rc.1` remains unchanged; rc.2 is not published automatically.

## Flight rendering

**Native 2D sprites are now the default and preferred flight renderer. A voxel mod is no longer required to take off.**

The `FLIGHT RENDERER` option controls only the visual presentation of the flying mount:

- **2D SPRITES** — default. Works in the normal flat overworld and remains the default billboard representation when a voxel provider is enabled.
- **STADIUM 3D** — explicit opt-in. Used only when Pokémon Stadium Overworld Models is installed, a voxel pipeline is active, and that renderer supports the selected species. Unsupported Generation II mounts automatically keep the safe 2D billboard instead of becoming invisible.

The same flight state, movement, collision, altitude, progression and Wild Skies logic is used in every renderer.

## Optional voxel providers

For voxel cameras/world rendering, install one of:

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0`;
- **Dramaless Shape** `>=1.6.4 <2.0.0`.

Battle Art is preferred automatically if both are installed. Neither is required for native 2D flight.

## Pokémon sprite / follower providers

This compatibility branch can use either:

- **Wilds of Kanto** (`overworld_wild_spawns`), or
- **PokéPC Followers — maintained mfrtechconsult compatibility fork** (`PokePCFollowers_VoxelMerge`).

The officially tested PokéPC implementation is **mfrtechconsult/PokePCFollowers**. It retains the upstream mod id for compatibility but exposes explicit provider metadata so DSR can identify the maintained fork. Older PokéPC builds with the same id remain best-effort legacy fallbacks.

Wilds of Kanto can act as the authoritative follower runtime so DSR does not need a second mod competing for the same follower lifecycle.

## Generation II mounts

Generation II support is **data-driven by National Pokédex number**. DSR does not require Crystal 251 specifically: Crystal 251 or another compatible content mod can provide Pokémon 152–251, while Wilds of Kanto or the maintained PokéPC fork provides compatible overworld art.

### Flight

Noctowl, Crobat, Xatu, Skarmory, Lugia and Ho-Oh.

### Ground Ride

Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, **Suicune** and Tyranitar.

### Visible Surf

Feraligatr, Mantine, Kingdra and Lugia.

### Suicune — seamless land/water running

Suicune is the **only amphibious Ground Ride mount**. Once normal Surf progression is available, it can run from land onto water and back onto land without dismounting, switching to the Visible Surf mount system, resetting gallop, or replacing its terrestrial running sprite.

Internally DSR arms the engine's native Surf collision state before the water step, so normal water tile-pair collision, map connections, Wilds encounters and other collision hooks remain authoritative. Cycling Road and Seafoam Surf restrictions remain respected. A battle on the water can restore Suicune directly back into the amphibious ride when the mount is still usable.

## Recommended airborne ecosystem

**Wild Skies 1.4.1+** remains strongly recommended. DSR uses its public API for visible airborne Pokémon and battles against the exact intercepted species and level.

## Current compatibility work

- Native flat-2D flight with trainer + mount composition and existing Pokédex-proportional mount sizing.
- Wilds of Kanto sprite/follower compatibility and cooperative overworld update-hook protection.
- Maintained `mfrtechconsult/PokePCFollowers` fork as the official PokéPC sprite-provider target.
- Data-driven Generation II flight, Ground Ride and Visible Surf mounts.
- Unique seamless land/water Ground Ride for Suicune.
- Shane-style public flight state: `isFlying()`, `altitude()` and `mount()`.
- Optional Pokémon Stadium Overworld Models integration, gated behind the explicit `STADIUM 3D` renderer setting with safe per-species fallback.
- Optional Flying Music using installed `Music_FRLG`, `Music_HGSS` and `Music_LGPE` Surf/Bike tracks without redistributing their audio.
- Compatibility regression coverage for DSR + Wilds + Deep Dive/Kanto Dive with Battle Art and Dramaless.

## Controls

| Action | Flat 2D / Battle Art | Dramaless | Controller |
|---|---|---|---|
| Flight | `H` | `H` | `X` |
| Ground Ride | `G` | `J` | `Y` |
| Ascend / descend | `Page Up` / `Page Down` | `Page Up` / `Page Down` | `R2` / `L2` |

`F` remains free for Gen1PC Overworld Encounters follower attacks. Dramaless reserves `G` for V-GRID.

## Compatibility

- Gen1Recomp `>=0.1.69 <2.0.0`.
- No voxel provider required for 2D flight.
- Optional: Battle Art Voxel Fork or Dramaless Shape for voxel rendering.
- Wilds of Kanto or the maintained `mfrtechconsult/PokePCFollowers` fork can provide compatible Pokémon overworld sprites.
- Generation II mounts activate only when those species actually exist in the loaded game data; Crystal 251 is supported but not required by name.
- Wild Skies `>=1.4.1 <2.0.0` strongly recommended.
- Optional music providers: `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- Optional Pokémon Stadium Overworld Models integration; unsupported species use the 2D fallback.
- `free_fly` conflicts as an alternative player-flight engine.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
