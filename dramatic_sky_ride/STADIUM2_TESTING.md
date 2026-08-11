# Stadium 2 3D Mounts — Experimental Test Guide

This document applies only to the `experiment/stadium2-3d` branch of Dramatic Sky Ride.

The stable `main` branch does not enable the native Stadium 2 mount renderer.

## What this branch does

Dramatic Sky Ride can replace only the **active DSR mount** with a native animated Pokémon Stadium 2 model while keeping DSR in control of Flight, Ground Ride, Visible Surf, altitude, collisions, camera integration, rider display and mount sizing.

The renderer does **not** ship Pokémon Stadium 2 model data. It reads DSM4 packs generated locally from the user's own compatible Pokémon Stadium 2 ROM through Crystal 251's Stadium 2 importer.

Normal NPCs, followers, wild Pokémon and the trainer are not globally converted to Stadium models by this feature.

## Required test setup

1. Gen1Recomp compatible with the current DSR branch.
2. Dramatic Sky Ride from `experiment/stadium2-3d`.
3. A supported voxel provider:
   - Battle Art Voxel Fork, or
   - Dramaless Shape.
4. Crystal 251 0.9.13 or newer with its fixed Stadium 2 pose-table decoder.
5. A legally obtained supported Pokémon Stadium 2 US ROM supplied to Crystal 251 when requested.
6. A complete Crystal 251 Stadium 2 cache.

The expected cache contract is:

- root: `crystal_251/stadium2`
- marker: `crystal_251/stadium2/pack.info`
- format: `C2DSM10`
- species: 251
- variants: 2 (`normal` and `shiny`)

DSR refuses incomplete or stale native caches. Alpha.5+ also rejects the historical Charizard one-frame static cache even though that cache used the same `C2DSM10` marker. If safe reconstruction is possible through Crystal 251 + Dramaless, only the completion marker is invalidated and Crystal rebuilds the DSM set from the user's ROM.

## Building the Stadium 2 cache

Crystal 251's current importer is built on top of the full Stadium module family from Dramatic Shape. DSR therefore separates **cache generation** from **cache rendering**.

### Dramaless Shape

This is the easiest experimental setup.

DSR detects Crystal 251 plus Dramaless Shape and, when the DSM cache is missing or stale, attaches Crystal's own Stadium 2 bridge to Dramaless automatically. Alpha.5+ can load Crystal's bridge module directly even when Crystal itself did not export `crystalStadium2` because original `DRAMATIC_SHAPE` was absent. Crystal remains the owner of the ROM picker, extraction, cache format and generated files.

After the bridge is attached, use Crystal's normal `STADIUM 2 MODELS` / Stadium 2 ROM import flow if it does not start automatically.

### Original Dramatic Shape

Crystal 251 already discovers the original `DRAMATIC_SHAPE` provider itself. DSR does not need to take ownership of that importer path.

### Battle Art Voxel Fork

Battle Art is fully supported for **rendering an existing DSR Stadium 2 cache**, including the interpolated/anchored DSR skeleton fallback.

Battle Art does not currently ship the complete Stadium importer module family Crystal 251 expects. Therefore, if no valid DSM cache exists yet:

1. temporarily run Crystal 251 with Dramaless Shape or the original Dramatic Shape;
2. import the supported Stadium 2 ROM and let the 251 normal + shiny DSM packs finish building;
3. close the game after the cache is complete;
4. switch back to Battle Art Voxel Fork;
5. keep Crystal 251 and DSR enabled — DSR will read the same persistent `crystal_251/stadium2` cache directly.

The ROM/model data is never copied into the DSR mod package.

## Live-animation recovery (alpha.6+)

A DSM4 pack can contain several decoded clips while Crystal's provisional overworld context still points to a static one-frame or constant pose. Alpha.6 no longer assumes that `animCount > 1` means the selected idle is alive.

For each mounted species DSR now inspects the packed bone streams themselves:

- if the requested idle changes at least one bone component between frames, it is kept;
- if the requested idle is static but another Stadium clip has changing bone data, DSR selects a real moving clip for the experimental overworld idle (preferring an authored non-zero loop seam when available);
- if **no clip contains any changing skeletal track**, DSR logs that the generated DSM itself is still static and does not invent a procedural animation;
- if `runtime.time` fails to advance through the normal Overworld update path, a monotonic clock advances it only for the stalled frames. A normally advancing game clock is never double-counted.

Useful log messages are:

- `idle clip ... is static; using moving clip ...` — real Stadium motion exists and DSR recovered it;
- `contains no changing skeletal tracks` — the problem is upstream in the Crystal Stadium 2 extraction/cache, not the renderer;
- `Stadium 2 live-animation recovery loaded` — both pose seams were patched successfully.

## First validation target: Charizard

Charizard remains the primary end-to-end validation mount because it exercises:

- a Gen I Stadium 2 model;
- a flying mount;
- an animated skeleton;
- the independent 2D rider entity;
- DSR altitude and camera placement;
- Pokédex-proportional mount sizing;
- generated Stadium procedural-effect geometry and texture flipbooks (tail flame);
- shadows and the normal voxel depth path.

### Test sequence

1. Start with DSR `MOUNT RENDERER = 2D SPRITES` and verify normal Flight still works.
2. Confirm the Stadium 2 cache is complete.
3. Enter a supported voxel mode.
4. Set `MOUNT RENDERER = STADIUM 3D`.
5. Mount Charizard.
6. For alpha.6, first verify that the body/wing/tail pose visibly changes while stationary. No cache rebuild is required if alpha.5 already rebuilt it.
7. Confirm the generated tail flame is visible and its texture continuously animates rather than remaining frozen on one frame.
8. Test all four facings while stationary.
9. Fly forward, backward and sideways.
10. Ascend and descend through several manual altitude levels.
11. Toggle `SHOW RIDER` off and on.
12. Test at least one orbit/voxel camera and 3RD camera.
13. Land, take off again and change maps.
14. Enter and leave a battle, then verify the mount restores correctly.
15. If possible, test a shiny Charizard to verify the `shiny` DSM pack is selected.

## What should be visually correct

- The model must remain assembled during animation; limbs must not twist or separate.
- Charizard must face the same direction as DSR movement/facing.
- The model must remain centered on the player's world position.
- Flight altitude must move the entire 3D model without terrain-induced vertical bobbing.
- The trainer must remain a separate human-sized sprite and sit consistently relative to the resized mount.
- The model must participate in the voxel depth buffer and cast the model-shaped shadow supplied by the voxel provider.
- Skeletal animation should be interpolated rather than visibly stepping at the Stadium source rate.
- Animated Stadium material streams such as eye/blink changes should remain synchronized with the skeleton.
- Generated DSM4 `fxFrames` should animate at the Stadium source rate (30 Hz); Charizard's tail flame is the first visual check.
- Generated additive fire must not be included in the shadow pass.
- A missing/invalid Stadium 2 model must fall back instead of making the mount invisible.

## Runtime diagnostics

When `MOUNT RENDERER = STADIUM 3D`, DSR writes a compact status line only when the relevant state changes.

Look for `Stadium 2 status:` and `Stadium 2 model:`. Alpha.6 additionally exposes `stadium3DLiveAnimation.stats(dex)`, reporting the selected animation, source (`requested_idle`, `moving_loop_recovery`, `moving_clip_recovery`, or `no_moving_tracks`), frame count, moving bone/component counts, runtime time and clock-fallback count.

Useful public diagnostic APIs include:

- `stadium3DNative.cacheStatus()`
- `stadium3DNative.modelInfo(species)`
- `stadium3DHardening.cacheCompatibility()`
- `stadium3DAnimationCacheGuard.inspect()`
- `stadium3DCrystalBootstrap.status()`
- `stadium3DCrystalBootstrap.retry()`
- `stadium3DProviderRig.active()`
- `stadium3DFallback.interpolated`
- `stadium3DEffects.status()`
- `stadium3DLiveAnimation.stats(dex)`
- `stadium3DDiagnostics.snapshot(species)`
- `stadium3DDiagnostics.log(species)`

## Fallback hierarchy

The experimental branch is intentionally defensive:

1. Native Stadium 2 model using the voxel provider's StadiumRig when available.
2. Interpolated, anchored and hardened DSR DSM4 skinning fallback when the provider rig cannot be used.
3. Randy's compatible Stadium 1 provider for supported Gen I species when present.
4. DSR 2D mount rendering.

A broken native cache or failed safety patch must never be treated as a reason to lose the mount entirely.

## Second validation wave

After Charizard is visually correct, test representative shapes instead of immediately checking all species:

### Flight

- Pidgeot — bird wing animation and anchoring.
- Aerodactyl — wide wing span.
- Dragonair — long body.
- Moltres — additional generated fire geometry/flipbooks.
- Lugia or Ho-Oh with Crystal 251 — Gen II coverage.

### Ground Ride

- Rapidash — quadruped animation plus generated mane/body fire.
- Dodrio — tall narrow body.
- Snorlax — large/wide body and rider placement.
- Suicune — Gen II ground/water transition path.

### Visible Surf

- Lapras — conventional Surf mount.
- Gyarados — extreme body proportions.
- Mantine or Kingdra with Crystal 251 — Gen II Surf coverage.

## Experimental limitations

- This branch is not yet a stable release.
- Alpha.6's moving-clip recovery is intentionally heuristic until Crystal's Stadium 2 context table is fully decoded. It always uses genuine Stadium skeletal data; it does not synthesize movement, but the recovered clip may not yet be the ideal species-specific standby loop.
- Final rider seat tuning may still need species-specific visual adjustments after real in-game captures.
- Procedural fire/gas textures are generated replacements supplied by the Stadium extraction pipeline; DSR reads the generated DSM4 frames and does not bundle source game assets.
- Battle Art can consume the cache but cannot currently act as Crystal 251's cache-generation provider by itself.
- Runtime validation still requires Gen1Recomp/LÖVE plus a user-generated Stadium 2 cache; source-level tests cannot reproduce the final GPU/camera presentation by themselves.
