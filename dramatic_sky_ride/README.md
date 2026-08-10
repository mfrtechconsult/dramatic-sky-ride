# Dramatic Sky Ride 0.1.6

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**, with native 2D flight, optional voxel cameras, Generation II mounts, Wild Skies integration, and compatibility with either Wilds of Kanto or PokéPC Followers.

## Installation and recommended mod stack

### What is actually required

Dramatic Sky Ride itself has **no mandatory third-party mod dependency**.

You need:

1. **[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)** `>=0.1.69 <2.0.0`;
2. **Dramatic Sky Ride**.

Native 2D flight works without Battle Art, Dramaless, Wild Skies, Crystal 251, or any music pack.

### Recommended complete setup

For the experience Dramatic Sky Ride is primarily designed around, use:

1. **Dramatic Sky Ride**;
2. **Wilds of Kanto** *or* **mfrtechconsult/PokePCFollowers** for Pokémon mount/follower sprites;
3. **Battle Art Voxel Fork** `>=1.7.6 <2.0.0` for the recommended voxel world and 1ST/3RD camera experience;
4. **Wild Skies** `>=1.4.1` for visible airborne Pokémon and aerial interceptions.

**Battle Art Voxel Fork is the recommended voxel companion for Dramatic Sky Ride.** It provides the voxel presentation and 1ST/3RD cameras while DSR keeps Flight, Ground Ride, Surf, collision, altitude and progression renderer-independent.

**Dramaless Shape** `>=1.6.4 <2.0.0` is also fully supported as an alternative voxel provider. Install one voxel provider for the voxel experience; native 2D flight needs neither.

If you want Johto mounts, add **Crystal 251 or another compatible Gen2 content mod** so Generation II Pokémon actually exist in the loaded game.

### Choose ONE Pokémon sprite / follower provider

For a normal installation, use **Wilds of Kanto OR PokéPC Followers — not both**.

#### Recommended for the fullest overworld experience: Wilds of Kanto

**[Wilds of Kanto](https://github.com/YoDrehDenSwagAuf/overworld-spawn-mod)** — `overworld_wild_spawns`

Recommended if you want the most complete living-overworld setup:

- visible overworld wild Pokémon;
- the Wilds follower system;
- Generation I and Generation II mount sprites for DSR;
- strong integration with DSR Flight, Ground Ride and Surf;
- works especially well alongside Wild Skies: Wilds populates the ground while Wild Skies populates the air.

When Wilds is installed, it remains the authoritative follower runtime so DSR does not create a competing follower lifecycle.

#### Alternative: maintained PokéPC Followers fork

**[mfrtechconsult/PokePCFollowers](https://github.com/mfrtechconsult/PokePCFollowers)** — `PokePCFollowers_VoxelMerge`

Recommended if you want a lighter follower-and-mount-sprite setup without Wilds of Kanto's overworld spawn system:

- Generation I and II follower sprites;
- Pokédex-proportional follower sizing;
- compatible mount art for Flight, Ground Ride and Surf;
- direct compatibility target maintained alongside DSR.

The fork deliberately keeps the original PokéPC mod id for save/install compatibility. Older PokéPC builds sharing that id remain best-effort legacy fallbacks, but the maintained `mfrtechconsult/PokePCFollowers` fork is the recommended PokéPC implementation.

> **Do not install Wilds of Kanto and PokéPC Followers together for the normal user setup.** DSR has resilience logic for accidental co-installation, but they are designed here as alternative providers.

## Recommended full experience

The following stack gives the broadest DSR experience while keeping responsibilities clean:

| Purpose | Recommended mod | Requirement level |
|---|---|---|
| Game engine | **Gen1Recomp** `>=0.1.69` | Required |
| Mount sprites + followers + living ground overworld | **Wilds of Kanto** | Strongly recommended; choose this **or** PokéPC |
| Lighter mount sprites + followers | **mfrtechconsult/PokePCFollowers** | Alternative to Wilds; do **not** use both normally |
| Voxel world / 1ST / 3RD cameras | **Battle Art Voxel Fork** | **Recommended voxel provider** |
| Alternative voxel provider | **Dramaless Shape** | Supported alternative |
| Visible airborne Pokémon and aerial interceptions | **[Wild Skies](https://github.com/ShaneHudson/gen1recomp-mods)** `>=1.4.1` | Strongly recommended |
| Generation II Pokémon in the actual game | **Crystal 251** or another compatible Gen2 content mod | Required only if you want Gen2 mounts |
| Flight music | FRLG, HGSS or LGPE music pack | Optional |

### Recommended 2D setup

For the complete 2D-oriented experience:

- Dramatic Sky Ride;
- **Wilds of Kanto** *or* **mfrtechconsult/PokePCFollowers**;
- **Wild Skies**;
- Crystal 251 or another compatible Gen2 content mod if you want Johto mounts;
- optionally one compatible music pack.

No voxel mod is required.

### Recommended voxel / 1ST / 3RD setup

Start with the recommended setup above, then use **Battle Art Voxel Fork** as the preferred voxel provider:

- **[Battle Art Voxel Fork](https://github.com/absol89/DramaticShapeVoxelMod)** `>=1.7.6 <2.0.0` — recommended;
- **[Dramaless Shape](https://github.com/artyrambles/DRAMALESS_SHAPE)** `>=1.6.4 <2.0.0` — supported alternative.

A normal setup only needs one voxel provider. Dramaless reserves `G` for V-GRID, so Ground Ride uses `J` with Dramaless. Battle Art and flat 2D use `G`.

## Native 2D flight

A voxel provider is **not required to fly**.

DSR uses one renderer-independent flight mechanic: movement, collision, altitude, progression, encounters, battles and map transitions share the same flight state in flat 2D and supported voxel cameras.

`2D SPRITES` is the default flight presentation. The flat overworld reuses Pokédex-proportional mount sizing and per-species size options.

## Wild Skies — strongly recommended

**[Wild Skies](https://github.com/ShaneHudson/gen1recomp-mods) 1.4.1+ is strongly recommended for the full flight experience.**

DSR uses its public API for ambient airborne Pokémon and consumes the exact visible species and level when an aerial interception starts a battle.

Wild Skies is complementary to both supported Pokémon providers:

- **Wilds of Kanto + Wild Skies** gives a populated ground and populated sky;
- **PokéPC Followers + Wild Skies** gives the lighter follower/mount setup plus airborne encounters.

Wild Skies is optional: DSR flight itself still works without it.

## Generation II mounts

Generation II support is based on **National Pokédex data**, not a hard dependency on Crystal 251 by mod id.

To actually use a Generation II mount, that Pokémon must exist in the loaded game data and be available to the player. **Crystal 251 or another compatible Gen2 content mod therefore becomes necessary if you want to use the Johto mount roster.** Wilds of Kanto or the maintained PokéPC fork then supplies compatible overworld mount art.

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

The same land/water transition support is applied to supported 1ST/3RD free-camera movement paths.

## Followers while mounted

Followers are hidden by default whenever a DSR mount is active.

`GROUND FOLLOWERS` can be enabled for **land Ground Ride only**. Flight and every Surf/water state keep followers hidden.

Known limitation in 0.1.6: when `GROUND FOLLOWERS` is enabled, the Pokémon currently used as the Ground Ride mount may still appear in the follower trail. The option is OFF by default.

## Wilds of Kanto compatibility

- Wilds can provide Generation I and II mount sprites without requiring PokéPC Followers.
- DSR uses cooperative/self-healing overworld update protection rather than restoring stale function snapshots.
- Generation II and Suicune runtime layers are part of the protected update chain.
- Gen II mount facing is reasserted after late Wilds updates in supported 1ST/3RD camera modes.
- Suicune preserves its amphibious Ground Ride across seamless map connections.

Known Wilds-only visual limitation: after a battle on water, Suicune can briefly show the ordinary Surf mount before the amphibious Ground Ride presentation is restored.

## Flying Music — optional

`FLYING MUSIC` defaults to `None`.

DSR can reuse compatible Surf/Bike OGG files from already-installed **FRLG**, **HGSS** or **LGPE** packs from [DarioMelo/Gen1Recomp-MusicMods](https://github.com/DarioMelo/Gen1Recomp-MusicMods).

DSR does not copy or redistribute those audio assets. Battle, victory and jingle cues retain priority, and normal map/Surf music is restored after landing.

A music pack is never required to use Flight.

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
- Pokédex-proportional mount sizing is enabled by default, with per-species overrides including Generation II mounts.
- Generation II Ground Ride species receive curated base/gallop speed profiles while retaining the existing stamina/acceleration behavior.

## Progression safeguards

DSR can require FLY and enforce THUNDERBADGE/SOULBADGE progression. `STORY GATES` respects data-driven story/badge gates while airborne.

`DISCOVERY GATES` prevent first-time airborne entry into canonical vanilla Kanto routes/cities until those maps have been reached normally. Unknown/custom map IDs remain open by default.

Suicune water running uses normal SURF field-move progression and preserves existing forced-bike and Seafoam restrictions.

## Compatibility summary

- **Required:** Gen1Recomp `>=0.1.69 <2.0.0` + Dramatic Sky Ride.
- **Normal sprite/follower setup:** Wilds of Kanto **or** maintained `mfrtechconsult/PokePCFollowers` — choose one.
- **Recommended voxel provider:** Battle Art Voxel Fork `>=1.7.6 <2.0.0`.
- **Alternative voxel provider:** Dramaless Shape `>=1.6.4 <2.0.0`.
- **Strongly recommended for Flight:** Wild Skies `>=1.4.1 <2.0.0`.
- **Gen2 mounts:** require those species to be supplied by Crystal 251 or another compatible Gen2 content mod.
- **Optional Flying Music:** `Music_FRLG`, `Music_HGSS`, or `Music_LGPE`.
- `free_fly` conflicts because it is an alternative player-flight engine.

The optional Stadium renderer remains an **experimental compatibility path** and is intentionally not part of the recommended 0.1.6 setup.

## Known limitations

- With `GROUND FOLLOWERS` enabled, the active Ground Ride mount may still appear in the follower trail. Leave the option OFF for the cleanest presentation.
- With Wilds of Kanto, Suicune may briefly show the ordinary Surf mount during the post-battle return before Suicune is restored.
- Experimental compatibility paths are not part of the validated core 0.1.6 experience.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, voxel cameras and 3D presentation.
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape voxel provider and public integration surface.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- mfrtechconsult/PokePCFollowers — maintained PokéPC compatibility fork used by DSR, including Gen 1/2 sprite-provider support and Pokédex-proportional sizing.
- gamecorner-033/PokePCFollowers — original PokéPC follower project and upstream foundation.
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto follower/wild overworld ecosystem and Generation II GSC sprite-provider support.
- ShaneHudson/gen1recomp-mods — Free Fly/Wild Skies public flight and hook interoperability patterns.
- DarioMelo/Gen1Recomp-MusicMods — optional FRLG/HGSS/LGPE music providers.

## Testing / bug reports

For bug reports, include:

- Gen1Recomp version;
- **Wilds of Kanto or PokéPC Followers** setup;
- voxel provider/version if used;
- Generation II content provider if used;
- Wild Skies version if used;
- music pack/version if used;
- mount species;
- camera mode;
- exact reproduction steps.