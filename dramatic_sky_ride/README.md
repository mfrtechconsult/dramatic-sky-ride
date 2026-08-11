# Dramatic Sky Ride 0.2.0

Dramatic Sky Ride adds controllable **Flight**, **Ground Ride** and **Visible Surf** mounts to Gen1Recomp. It works in native 2D and with supported voxel renderers, supports Generation II mounts, integrates with Wild Skies, and can optionally render the active mount with animated **Pokemon Stadium 2** models generated from the player's own ROM through Crystal 251.

## Requirements

Dramatic Sky Ride has no mandatory third-party mod dependency.

- Gen1Recomp `>=0.1.69 <2.0.0`
- Dramatic Sky Ride

Native 2D Flight works without Battle Art, Dramaless, Crystal 251, Wild Skies or a follower mod.

## Recommended setups

### Native 2D

Use Dramatic Sky Ride with either:

- **Wilds of Kanto** (`overworld_wild_spawns`), or
- **mfrtechconsult/PokePCFollowers** (`PokePCFollowers_VoxelMerge`).

Do not normally install both follower providers together.

Add **Wild Skies 1.4.1+** for visible airborne Pokemon and aerial interceptions. Add Crystal 251 or another compatible Gen II content provider if you want Johto Pokemon to exist in the game.

### Voxel / 1ST / 3RD camera

Supported voxel providers:

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0` — recommended renderer;
- **Dramaless Shape** `>=1.6.4 <2.0.0` — supported alternative.

DSR remains the owner of movement, collision, altitude, progression, mounted state and rider logic. The voxel provider owns the world presentation.

## Pokemon Stadium 2 mounts

Version 0.2.0 promotes the native Stadium 2 mount renderer to the stable branch.

Set:

`MOUNT RENDERER = STADIUM 3D`

DSR then replaces only the **active DSR mount** with a native animated Stadium 2 model. Normal wild Pokemon, followers and NPCs remain owned by their respective mods unless another companion mod changes them.

### What is required for Stadium 2

- Crystal 251 `>=0.9.13 <1.0.0`;
- a compatible voxel renderer;
- a legally obtained supported Pokemon Stadium 2 US ROM supplied by the player;
- a generated Crystal 251 Stadium 2 cache.

DSR never ships Nintendo model data or the ROM.

The generated cache is stored under:

`crystal_251/stadium2/`

with normal and shiny DSM packs for National Dex 1-251.

### Stadium 2 import with Dramaless

Dramaless contains the full Stadium module family Crystal 251 needs to build the Stadium 2 cache. DSR attaches Crystal's Stadium 2 bridge automatically.

The Options menu exposes the Stadium 2 import flow. After a successful import, the row remains available and reports `READY`; version 0.2.0 fixes the previous behavior where it could disappear on the next boot once the cache already existed.

An existing healthy cache is never deleted or rebuilt merely to restore the UI.

### Stadium 2 with Battle Art

Battle Art is fully supported for **rendering an existing Stadium 2 cache**.

Battle Art currently does not ship the complete Stadium importer module family Crystal 251 expects. A first-time cache therefore still needs a compatible full import host such as Dramaless/Dramatic Shape. After the cache exists, Battle Art can render DSR's Stadium 2 mounts directly.

### STADIUM_OVERWORLD_MODELS compatibility

DSR 0.2.0 supports `STADIUM_OVERWORLD_MODELS` and compatible Crystal-aware forks without allowing both mods to claim the active mount at the same time.

The integration is capability-based:

- voxel rendering, Stadium cache building and ROM-selection UI are treated as separate capabilities;
- companion mods may continue to handle wild Pokemon, followers and their own UI;
- when DSR's native Stadium 2 renderer owns the active mount, the companion renderer is prevented from rebuilding that same mount;
- fallback behavior remains available when DSR cannot use the native Stadium 2 model.

## Stadium 2 animation and mount motion

The Stadium 2 DSM cache contains real skeletal animations. DSR drives pose/skin updates from the render path so visible mounts continue animating even when a provider's overworld update seam does not advance the model reliably.

The supported mount-motion roster is:

- **16 Flight roles**
- **17 Ground Ride roles**
- **8 Visible Surf roles**
- plus Suicune's internal amphibious-water presentation

DSR does not fabricate generic bone mappings or reuse arbitrary battle attacks as fake walk/run animations. Pokemon Stadium 2 does not expose a reliable shared overworld `walk`, `run`, `fly` or `swim` contract, so 0.2.0 keeps genuine Stadium skeletal animation and adds morphology-aware whole-model presentation:

- Flight: playback cadence, forward pitch, climb/dive pitch and banking;
- Ground Ride: movement cadence, body bob/lean and restrained turn response;
- Visible Surf: buoyancy, pitch and water-turn roll;
- the model and its shadow use the same transform.

Fast quadrupeds and runner birds are intentionally more expressive than heavy bipeds such as Snorlax and Tyranitar.

## Supported mounts

### Flight — 16

Generation I: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair, Dragonite.

Generation II: Noctowl, Crobat, Xatu, Skarmory, Lugia, Ho-Oh.

### Ground Ride — 17

Generation I: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros, Snorlax.

Generation II: Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, Suicune, Tyranitar.

### Visible Surf — 8

Generation I: Blastoise, Tentacruel, Gyarados, Lapras.

Generation II: Feraligatr, Mantine, Kingdra, Lugia.

## Suicune amphibious Ground Ride

Suicune is the only amphibious Ground Ride mount. Once normal Surf progression is available, it can move directly from land to water and back without dismounting or switching to the normal Visible Surf lifecycle.

Version 0.2.0 includes a dedicated Stadium water-motion profile for Suicune while preserving Ground Ride ownership of the state.

## Wilds of Kanto and PokéPC Followers

For a normal installation, choose one primary Pokemon follower/sprite provider:

- Wilds of Kanto — living overworld, followers and optional high-detail PokeMMO mount atlases;
- mfrtechconsult/PokePCFollowers — lighter follower/mount setup with Gen I/II support.

When Wilds uses its PokeMMO sprite style, DSR can use the higher-resolution atlas only for mounted Pokemon while keeping the normal Wilds sprite pipeline intact elsewhere.

## Wild Skies

Wild Skies `>=1.4.1` is strongly recommended for Flight. DSR uses its public integration surface for visible airborne Pokemon and aerial interceptions while keeping DSR as the player's flight engine.

## OTF Player Switcher

OTF Player Switcher is optional. Mounted rider art follows the selected player character during Flight, Ground Ride and Visible Surf.

During Flight, Page Up/Page Down remain reserved for DSR altitude control.

## Flying Music

`FLYING MUSIC` defaults to `None`.

DSR can reuse compatible installed FRLG, HGSS or LGPE music packs without redistributing their audio assets. Battle, victory and jingle cues retain priority.

## Controls

### Flight

- Keyboard: `H`
- Controller: `X`
- Altitude: `R2/L2` or `Page Up/Page Down`

### Ground Ride

- Flat 2D / Battle Art: `G`
- Dramaless: `J` because Dramaless reserves `G` for V-GRID
- Controller: `Y`

Visible Surf uses the game's normal Surf movement/collision/progression rules.

## Speed and size

- `FLIGHT SPEED`: 50%-200%
- `GROUND SPEED`: 50%-200%
- Pokédex-proportional mount sizing is enabled by default
- Generation II mounts have canonical height fallbacks when the active content provider does not publish complete Pokédex height data

## Progression safeguards

DSR can enforce FLY, badge and story progression while flying. Discovery gates prevent first-time airborne entry into canonical vanilla Kanto maps until those areas have been reached normally. Unknown/custom maps remain open by default.

Suicune water running still requires normal Surf progression.

## Known limitations

- With `GROUND FOLLOWERS` enabled, the active Ground Ride Pokemon may still appear in the follower trail.
- With Wilds of Kanto, Suicune can briefly show the ordinary Surf mount during some post-battle restoration paths.
- Battle Art can render an existing Stadium 2 cache but cannot currently build one by itself.
- Stadium 2 Ground/Surf motion uses authentic skeletal clips plus whole-model presentation; species-specific true walk/run/swim clips are not claimed unless they have been individually validated.

## Diagnostics

Useful public APIs include:

- `stadium3DNative.cacheStatus()`
- `stadium3DCrystalBootstrap.status()`
- `stadium3DProviderInterop.status()`
- `stadium3DProviderRig.active()`
- `stadium3DLiveAnimation.stats(dex)`
- `stadium3DRenderClock.stats(dex)`
- `stadium3DMountMotion.audit()`
- `stadium3DDiagnostics.snapshot(species)`

See `STADIUM2_TESTING.md` and `STADIUM2_MOUNT_MOTION.md` for the technical Stadium 2 notes.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape and Stadium provider surface
- DramaticShape/DramaticShapeVoxelMod — original voxel/Stadium architecture
- Deftones565/gen1recomp-mod-crystal-251 — Crystal 251 Stadium 2 extraction/cache bridge
- randyadr/3D-Pokemon-Sprites and compatible forks — Stadium overworld companion interoperability target
- mfrtechconsult/PokePCFollowers and gamecorner-033/PokePCFollowers — follower/mount sprite integration
- YoDrehDenSwagAuf/overworld-spawn-mod — Wilds of Kanto integration
- ShaneHudson/gen1recomp-mods — Wild Skies interoperability patterns
- on1san/otf-player-switcher — player-switching integration
- DarioMelo/Gen1Recomp-MusicMods — optional music providers

## Bug reports

Please include:

- Gen1Recomp version;
- DSR version;
- selected mount and renderer;
- Battle Art or Dramaless version;
- Crystal 251 version if Stadium 2 is involved;
- whether the Stadium 2 cache already existed before the current launch;
- Wilds/PokéPC/Wild Skies setup;
- relevant DSR Stadium diagnostic log lines.
