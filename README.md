# Dramatic Sky Ride 0.1.7

Dramatic Sky Ride adds controllable **Flight, Ground Ride and Visible Surf mounts** to **Gen1Recomp**, with native 2D flight, optional voxel cameras, Generation II mounts, Wild Skies integration, support for either Wilds of Kanto or PokéPC Followers, optional OTF Player Switcher compatibility, and a high-detail PokeMMO mount path for Wilds.

## What do I need to install?

### Required

You only need:

1. **[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)** `>=0.1.69 <2.0.0`;
2. **Dramatic Sky Ride**.

DSR has **no mandatory third-party mod dependency**. Native 2D flight works without a voxel mod.

### Recommended complete setup

For the experience DSR is primarily designed around, use:

1. **Dramatic Sky Ride**;
2. **Wilds of Kanto** *or* **mfrtechconsult/PokePCFollowers** for Pokémon mount/follower sprites;
3. **Battle Art Voxel Fork** `>=1.7.6 <2.0.0` for the recommended voxel, 1ST and 3RD camera experience;
4. **Wild Skies** `>=1.4.1` for visible airborne Pokémon and aerial encounters.

**Battle Art Voxel Fork is the recommended voxel companion for Dramatic Sky Ride.** It provides the 3D voxel world and 1ST/3RD camera modes used by DSR while keeping the mount gameplay itself renderer-independent.

**Dramaless Shape** `>=1.6.4 <2.0.0` is also fully supported as an alternative voxel provider. Install one voxel provider for the voxel experience; native 2D flight needs neither.

If you want Generation II mounts, also install **Crystal 251 or another compatible Gen2 content mod** so those Pokémon actually exist in the game.

## Choose ONE Pokémon provider

### Recommended for the fullest overworld experience: Wilds of Kanto

**[Wilds of Kanto](https://github.com/YoDrehDenSwagAuf/overworld-spawn-mod)** — `overworld_wild_spawns`

Use this if you want:

- visible wild Pokémon in the overworld;
- Wilds followers;
- Generation I and II mount sprites for DSR;
- optional high-detail PokeMMO mount rendering;
- a more populated Kanto;
- the best complement to Wild Skies, with Pokémon on the ground and in the air.

### Alternative: maintained PokéPC Followers fork

**[mfrtechconsult/PokePCFollowers](https://github.com/mfrtechconsult/PokePCFollowers)** — `PokePCFollowers_VoxelMerge`

Use this if you prefer a lighter follower-and-mount-sprite setup without Wilds' overworld spawn system.

The maintained fork provides Generation I/II follower sprites, Pokédex-proportional sizing and the sprite-provider API used by DSR.

> **Wilds of Kanto and PokéPC Followers are alternatives. Do not install both for the normal user setup.**

## Recommended full experience

| Purpose | Recommended mod | Status |
|---|---|---|
| Game engine | **Gen1Recomp** `>=0.1.69` | Required |
| Mount sprites + followers + living ground overworld | **Wilds of Kanto** | Strongly recommended; choose this **or** PokéPC |
| Lighter mount sprites + followers | **mfrtechconsult/PokePCFollowers** | Alternative to Wilds |
| Voxel world / 1ST / 3RD cameras | **Battle Art Voxel Fork** | **Recommended voxel provider** |
| Alternative voxel provider | **Dramaless Shape** | Supported alternative |
| Visible airborne Pokémon / aerial encounters | **[Wild Skies](https://github.com/ShaneHudson/gen1recomp-mods)** `>=1.4.1` | Strongly recommended |
| Generation II Pokémon in-game | **Crystal 251** or another compatible Gen2 content mod | Needed only for Gen2 mounts |
| Player character switching | **[OTF Player Switcher](https://github.com/on1san/otf-player-switcher)** | Optional |
| Flight music | FRLG, HGSS or LGPE music pack | Optional |

### Suggested 2D setup

For a complete 2D experience:

- Dramatic Sky Ride;
- **Wilds of Kanto** *or* **mfrtechconsult/PokePCFollowers**;
- **Wild Skies**;
- Crystal 251 or another Gen2 content mod if you want Johto mounts;
- optionally OTF Player Switcher;
- optionally one compatible music pack.

### Suggested voxel / 1ST / 3RD setup

Use the setup above and add **Battle Art Voxel Fork**:

- **[Battle Art Voxel Fork](https://github.com/absol89/DramaticShapeVoxelMod)** `>=1.7.6 <2.0.0` — recommended;
- **[Dramaless Shape](https://github.com/artyrambles/DRAMALESS_SHAPE)** `>=1.6.4 <2.0.0` — supported alternative.

Neither is required for native 2D flight. A normal setup only needs one voxel provider.

The optional Stadium renderer remains experimental and is intentionally **not** part of the recommended 0.1.7 setup.

## 0.1.7 highlights

- **OTF Player Switcher compatibility** is now optional and integrated: mounted rider art follows the active player character during Flight, Ground Ride and Surf.
- **High-detail PokeMMO mounts** can use Wilds' native 32/64 px source sprites instead of enlarging the generated 16 px runtime cards.
- PokeMMO sprites now use a stable opaque crop before DSR sizing, so transparent padding no longer makes mounts such as Suicune look artificially small.
- **Generation II size fallbacks** keep Johto mount proportions coherent even when the active content mod does not expose Pokédex height fields.
- **Flat 2D Flight** no longer visibly jumps over tall buildings when an internal safety climb is required; logical altitude and collision rules remain unchanged.
- OTF and the PokeMMO renderer remain entirely optional and do not alter the normal DSR path when absent/inactive.

## Generation II mounts

Generation II support is data-driven. DSR does not hard-depend on Crystal 251 by mod id, but a compatible Gen2 content mod must actually provide those Pokémon to the game before they can be used as mounts.

### Flight

Noctowl, Crobat, Xatu, Skarmory, Lugia and Ho-Oh.

### Ground Ride

Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, **Suicune** and Tyranitar.

### Visible Surf

Feraligatr, Mantine, Kingdra and Lugia.

## Suicune — seamless land/water running

Suicune is the only amphibious Ground Ride mount. Once normal Surf progression is available, it can run directly from land to water and back while preserving its Ground Ride presentation, movement state and gallop continuity.

Normal Surf progression and map restrictions remain authoritative.

## Followers while mounted

Followers are hidden by default while mounted.

`GROUND FOLLOWERS` can be enabled for **land Ground Ride only**. Followers remain hidden during Flight and Surf.

Known limitation in 0.1.7: when `GROUND FOLLOWERS` is enabled, the Pokémon currently being ridden can still appear in the follower trail. The option is OFF by default.

## PokeMMO sprite quality

When Wilds of Kanto is installed and its sprite style is set to **PokeMMO**, DSR can use the original higher-resolution follow-sprite atlas for mounted Pokémon. This path keeps nearest-neighbor filtering, trims shared transparent padding, and then applies the normal Pokédex/per-species DSR size.

Other Wilds sprite styles are unchanged.

## OTF Player Switcher

**[OTF Player Switcher](https://github.com/on1san/otf-player-switcher)** is optional. DSR refreshes the mounted rider when OTF changes the active character. During Flight, `Page Up/Page Down` remain DSR altitude controls; outside Flight, OTF keeps its normal shortcuts.

## Wild Skies

**[Wild Skies](https://github.com/ShaneHudson/gen1recomp-mods) 1.4.1+ is strongly recommended for the full Flight experience.**

It provides visible airborne Pokémon and lets DSR start battles against the exact intercepted species and level.

Wilds of Kanto + Wild Skies is the recommended combination if you want both a populated ground overworld and a populated sky.

## Flying Music

Flying Music is optional and defaults to `None`.

DSR can reuse compatible tracks from installed FRLG, HGSS or LGPE packs from **[DarioMelo/Gen1Recomp-MusicMods](https://github.com/DarioMelo/Gen1Recomp-MusicMods)** without redistributing their audio.

## Controls

| Action | Flat 2D / Battle Art | Dramaless | Controller |
|---|---|---|---|
| Flight | `H` | `H` | `X` |
| Ground Ride | `G` | `J` | `Y` |
| Ascend / descend | `Page Up` / `Page Down` | `Page Up` / `Page Down` | `R2` / `L2` |

`F` remains free for Gen1PC Overworld Encounters follower attacks. Dramaless reserves `G` for V-GRID.

## Compatibility summary

- **Required:** Gen1Recomp `>=0.1.69 <2.0.0` + Dramatic Sky Ride.
- **Normal Pokémon provider:** Wilds of Kanto **or** maintained `mfrtechconsult/PokePCFollowers`.
- **Recommended voxel provider:** Battle Art Voxel Fork `>=1.7.6 <2.0.0`.
- **Alternative voxel provider:** Dramaless Shape `>=1.6.4 <2.0.0`.
- **Strongly recommended:** Wild Skies `>=1.4.1 <2.0.0`.
- **Gen2 mounts:** require the Gen2 species to exist through Crystal 251 or another compatible content mod.
- **Optional player switching:** OTF Player Switcher.
- **Optional high-detail PokeMMO mounts:** Wilds of Kanto with PokeMMO sprite style selected.
- **Optional music:** `Music_FRLG`, `Music_HGSS`, `Music_LGPE`.
- `free_fly` conflicts because it is an alternative player-flight engine.

## Known limitations

- `GROUND FOLLOWERS` may still show the active Ground Ride mount as a follower.
- With Wilds of Kanto, Suicune may briefly show the ordinary Surf mount during the post-battle return before Suicune is restored.
- The optional Stadium renderer remains experimental and is not part of the validated 0.1.7 highlights.

## More details

The full mod documentation, compatibility notes, controls and technical integration details are also bundled in `dramatic_sky_ride/README.md`.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
