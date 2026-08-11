# Dramatic Sky Ride 0.2.0

Dramatic Sky Ride adds controllable **Flight**, **Ground Ride** and **Visible Surf** mounts to Gen1Recomp. It works in native 2D and with supported voxel renderers, supports Generation II mounts, integrates with Wild Skies, and can optionally render the active mount with animated **Pokemon Stadium 2** models generated locally from the player's own ROM through Crystal 251.

DSR remains the gameplay owner at all times: movement, collision, altitude, progression, mounted state, rider placement and mount sizing stay inside Dramatic Sky Ride. Renderers and companion mods only provide presentation capabilities.

## What's new in 0.2.0 — since 0.1.7

0.2.0 is the largest visual update to Dramatic Sky Ride since the stable 0.1.x line.

### Native animated Pokemon Stadium 2 mounts

- The Stadium 2 renderer is now part of the stable branch.
- The active Flight, Ground Ride or Visible Surf mount can use a native Stadium 2 3D model instead of the normal 2D mount presentation.
- Models come from Crystal 251's **locally generated DSM cache**. DSR does not ship Nintendo assets or ROM data.
- Real Stadium 2 skeletal tracks are decoded, interpolated and updated directly from the render path.
- Normal and shiny Stadium 2 packs are supported for National Dex 1-251 when present in the generated cache.
- Stadium effect-frame animation is supported for compatible model materials/effects.

### Full DSR mount roster support

The native Stadium 2 path covers the complete current mount roster:

- **16 Flight roles**;
- **17 Ground Ride roles**;
- **8 Visible Surf roles**;
- plus Suicune's dedicated amphibious-water presentation.

### Mount-specific 3D motion

0.2.0 adds a morphology-aware presentation layer on top of the genuine Stadium animation:

- Flight adds speed-sensitive cadence, forward pitch, climb/dive response and banking;
- Ground Ride adds tuned body cadence, bob/lean and turn response;
- Visible Surf adds buoyancy, pitch and water-turn roll;
- Suicune now has its own Stadium water-motion profile while remaining a Ground Ride mount;
- heavy bipeds such as Snorlax and Tyranitar deliberately remain calmer than fast quadrupeds or runner birds.

DSR does **not** pretend that Stadium 2 exposes a universal overworld `walk`, `run`, `fly` or `swim` animation. Arbitrary battle attacks are not reused as fake locomotion. Genuine Stadium skeletal animation is kept, then adapted to DSR's actual movement state.

### Crystal 251 import improvements

- Crystal 251 `>=0.9.13` is supported with its corrected Stadium 2 pose decoder.
- Cache generation is now separated from the selected voxel renderer.
- A valid cache remains usable even if the renderer later changes.
- The `STADIUM 2 ROM` row now remains available after a successful import and after restarting the game.
- When the cache is already valid, the row reports `READY` instead of disappearing.
- Reattaching the import UI never deletes or rebuilds a healthy cache.

### Better provider interoperability

0.2.0 separates three different capabilities that were previously easy to confuse:

1. **Voxel renderer** — draws the 3D world and model.
2. **Stadium import host** — contains the complete Stadium extraction/build module family.
3. **ROM selection UI** — exposes a picker/menu action to the player.

This allows DSR to work cleanly with **Battle Art**, **Dramaless Shape**, compatible legacy providers and `STADIUM_OVERWORLD_MODELS`-style companion mods without assuming that every renderer is also an importer.

When DSR's native Stadium 2 renderer owns the active mount, compatible Stadium overworld companion mods are prevented from also rebuilding/rendering that same mount. They can continue handling their own wild Pokemon, followers and UI alongside DSR.

### Everything from 0.1.7 is retained

0.2.0 keeps the existing stable feature set, including:

- renderer-independent native 2D Flight;
- Generation II Flight/Ground/Surf mounts;
- Wilds of Kanto and maintained PokéPC Followers compatibility;
- Wild Skies aerial encounters;
- optional high-detail PokeMMO mounted sprites when Wilds uses that style;
- OTF Player Switcher rider compatibility;
- optional FRLG/HGSS/LGPE Flying Music integration;
- Suicune seamless land/water Ground Ride;
- story, badge and discovery progression safeguards.

---

## Requirements

Dramatic Sky Ride itself has no mandatory third-party mod dependency.

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
- **Dramaless Shape** `>=1.6.4 <2.0.0` — supported alternative and currently the easiest Stadium import host.

DSR remains the owner of movement, collision, altitude, progression, mounted state and rider logic. The voxel provider owns the world presentation.

---

# Pokemon Stadium 2 3D mounts

## What the feature does

Set:

`MOUNT RENDERER = STADIUM 3D`

DSR then replaces only the **active DSR mount** with a native animated Pokemon Stadium 2 model.

The trainer remains a separate rider. Flight, Ground Ride, Visible Surf, collisions, altitude, progression and sizing continue to work exactly through DSR rather than being delegated to the Stadium renderer.

Normal wild Pokemon, followers and NPCs remain owned by their respective mods unless another companion mod intentionally changes them.

## What you need

For native Stadium 2 mounts you need:

- Dramatic Sky Ride 0.2.0 or newer;
- Crystal 251 `>=0.9.13 <1.0.0`;
- a supported voxel renderer;
- a legally obtained compatible **Pokemon Stadium 2 US ROM** supplied by the player;
- a completed Crystal 251 Stadium 2 cache.

**DSR never includes or redistributes Pokemon Stadium 2 ROM/model assets.**

The generated persistent cache lives under:

`crystal_251/stadium2/`

A complete cache contains the Stadium 2 DSM packs used by DSR, including normal and shiny variants.

---

## Quick start — first Stadium 2 import with Dramaless

This is currently the easiest way to generate the cache for the first time.

### 1. Install the required mods

Enable:

- Dramatic Sky Ride;
- Crystal 251 `0.9.13+`;
- Dramaless Shape `1.6.4+`.

Your normal follower/Wilds/Wild Skies setup can remain installed.

### 2. Start the game and open Options

Crystal 251 attaches its Stadium 2 bridge to Dramaless through DSR's compatibility layer.

You should see:

`STADIUM 2 ROM`

Before the first import, the row reports an import state.

### 3. Select your Pokemon Stadium 2 ROM

Activate `STADIUM 2 ROM` and choose your compatible Pokemon Stadium 2 US ROM.

Crystal 251 performs the extraction and builds the local DSM cache. DSR itself does not extract or keep the ROM.

Wait for the build to complete before closing the game.

### 4. Confirm the cache is ready

After a successful build, the Stadium 2 row reports:

`READY`

The cache now persists in `crystal_251/stadium2/`.

**You do not need to import the ROM again every time the game starts.**

DSR 0.2.0 specifically fixes the old behavior where the Stadium 2 import row could disappear after the first successful build. On later boots, the bridge is reattached even when the cache is already healthy, so `STADIUM 2 ROM = READY` remains available for status and reimport.

### 5. Enable the 3D mount renderer

In DSR's options, set:

`MOUNT RENDERER = STADIUM 3D`

Then use Flight, Ground Ride or Surf normally. If the selected mount has a valid Stadium 2 model in the cache, DSR uses it automatically.

If a model/cache/provider check fails, DSR falls back instead of intentionally making the mount disappear.

---

## Using Battle Art after the cache has been generated

Battle Art is fully supported as a **renderer** for an existing Stadium 2 cache.

Battle Art currently does not ship the complete Stadium importer module family required by Crystal 251 to build the cache from scratch. This means the recommended flow is:

1. enable Crystal 251 + Dramaless + DSR;
2. import Stadium 2 once;
3. confirm `STADIUM 2 ROM = READY`;
4. close the game;
5. disable Dramaless if you do not want to use it;
6. enable Battle Art;
7. keep Crystal 251 and DSR enabled;
8. keep the existing `crystal_251/stadium2/` cache;
9. set `MOUNT RENDERER = STADIUM 3D`.

**Do not delete or regenerate the cache just because you switch from Dramaless to Battle Art.**

DSR reads the persistent Stadium 2 DSM cache while Battle Art provides the voxel renderer.

If a future Battle Art or compatible provider exposes the complete importer family, DSR's capability-based detection can use that instead of relying on a hard-coded provider name.

---

## Reimporting Stadium 2

A healthy cache is kept indefinitely until the player deliberately rebuilds it or a future cache-format change requires regeneration.

When the row displays `READY`, activating `STADIUM 2 ROM` can be used to reimport when necessary, for example after replacing the ROM with another supported revision or after an importer/cache format update.

Simply restarting the game, changing voxel renderer or toggling the DSR Stadium renderer does **not** require a rebuild.

---

## STADIUM_OVERWORLD_MODELS compatibility

DSR 0.2.0 supports `STADIUM_OVERWORLD_MODELS` and compatible Crystal-aware forks without allowing two mods to own the active DSR mount at the same time.

The integration is capability-based:

- voxel rendering, Stadium cache building and ROM-selection UI are treated as separate capabilities;
- companion mods may continue to handle wild Pokemon, followers and their own UI;
- when DSR's native Stadium 2 renderer owns the active mount, the companion renderer is prevented from rebuilding that same mount;
- external companion fallback behavior remains available when DSR cannot use the native Stadium 2 model.

This lets players keep a Stadium overworld/follower mod installed beside DSR without intentionally duplicating the mount renderer.

---

## Stadium 2 animation and DSR mount motion

The generated DSM cache contains genuine Stadium skeletal data. DSR does more than display the mesh statically:

- skeletal animation is advanced continuously;
- poses are interpolated instead of visibly stepping at the original source rate;
- pose/skin updates are driven from the render path so provider update-order differences cannot leave a visible mount frozen;
- compatible Stadium material/effect frames are animated;
- model transforms and model shadows share the same mount-motion presentation.

DSR then adapts that real Stadium animation to the current ride state.

### Flight

Flight can add:

- movement-sensitive animation cadence;
- forward lean;
- climb/dive pitch;
- turn banking;
- stronger response while travelling quickly.

### Ground Ride

Ground Ride can add:

- movement-sensitive cadence;
- morphology-specific body bob and forward lean;
- turn response;
- stronger presentation for fast quadrupeds/equines/runner birds;
- deliberately restrained presentation for heavy bipeds.

### Visible Surf

Visible Surf can add:

- gentle idle buoyancy;
- stronger movement response;
- forward pitch;
- water-turn roll;
- morphology-aware behavior for serpentine, ray-like and large swimming mounts.

### Why DSR does not force fake walk/run clips

Pokemon Stadium 2's packed animation contexts are battle-oriented and do not provide a trustworthy universal overworld `walk`, `run`, `fly` or `swim` contract shared by every species.

DSR therefore does not blindly select attack animations or guess bone indices to fake locomotion. Species-specific true locomotion clips may be added later only when an actual Stadium source clip has been individually verified as visually appropriate.

---

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

0.2.0 includes a dedicated Stadium water-motion profile for Suicune while preserving Ground Ride ownership of the state.

---

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

---

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

---

## Troubleshooting Stadium 2

### `STADIUM 2 ROM` is missing

With DSR 0.2.0 + Crystal 251 + a compatible full import host such as Dramaless, the bridge should be attached again on every boot, including when the cache is already `READY`.

If the row is still missing, include `stadium3DCrystalBootstrap.status()` in the bug report.

### Battle Art displays no import option

This is expected with current Battle Art builds when no full Stadium importer host is installed. Battle Art can render an existing cache, but it cannot currently build the complete Crystal Stadium 2 cache by itself.

Generate the cache once with a compatible full import host, then switch back to Battle Art.

### The model is missing but the 2D mount still appears

DSR intentionally fails closed. Invalid/incomplete Stadium cache data or an unsupported provider path should fall back to a normal mount presentation instead of hiding the mount entirely.

### The model is present but motion looks too subtle

Flight, Ground and Surf use different morphology-aware profiles. Heavy Pokemon intentionally have less bob/lean than fast quadrupeds or birds. Stadium 2 also does not provide a reliable universal overworld gait clip for every species.

---

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

See `STADIUM2_TESTING.md` and `STADIUM2_MOUNT_MOTION.md` for the deeper technical notes.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork
- artyrambles/DRAMALESS_SHAPE — Dramaless Shape and Stadium provider/import surface
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