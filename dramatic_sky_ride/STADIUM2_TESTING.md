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
4. Crystal 251 with its Stadium 2 importer available.
5. A legally obtained supported Pokémon Stadium 2 US ROM supplied to Crystal 251 when requested.
6. A complete Crystal 251 Stadium 2 cache.

The expected cache contract is:

- root: `crystal_251/stadium2`
- marker: `crystal_251/stadium2/pack.info`
- format: `C2DSM10`
- species: 251
- variants: 2 (`normal` and `shiny`)

DSR now refuses incomplete or stale native caches. If the cache contract is not satisfied, the renderer falls back safely instead of consuming partial packs.

## First validation target: Charizard

Charizard is the primary end-to-end validation mount because it exercises:

- a Gen I Stadium 2 model;
- a flying mount;
- an animated skeleton;
- the independent 2D rider entity;
- DSR altitude and camera placement;
- Pokédex-proportional mount sizing;
- Stadium procedural-effect geometry present in generated packs;
- shadows and the normal voxel depth path.

### Test sequence

1. Start with DSR `MOUNT RENDERER = 2D SPRITES` and verify normal Flight still works.
2. Enter a supported voxel mode.
3. Set `MOUNT RENDERER = STADIUM 3D`.
4. Mount Charizard.
5. Test all four facings while stationary.
6. Fly forward, backward and sideways.
7. Ascend and descend through several manual altitude levels.
8. Toggle `SHOW RIDER` off and on.
9. Test at least one orbit/voxel camera and 3RD camera.
10. Land, take off again and change maps.
11. Enter and leave a battle, then verify the mount restores correctly.
12. If possible, test a shiny Charizard to verify the `shiny` DSM pack is selected.

## What should be visually correct

- The model must remain assembled during animation; limbs must not twist or separate.
- Charizard must face the same direction as DSR movement/facing.
- The model must remain centered on the player's world position.
- Flight altitude must move the entire 3D model without terrain-induced vertical bobbing.
- The trainer must remain a separate human-sized sprite and sit consistently relative to the resized mount.
- The model must participate in the voxel depth buffer and cast the model-shaped shadow supplied by the voxel provider.
- Animated Stadium material streams such as eye/blink changes should remain synchronized with the skeleton when the provider StadiumRig bridge is active.
- A missing/invalid Stadium 2 model must fall back instead of making the mount invisible.

## Runtime diagnostics

When `MOUNT RENDERER = STADIUM 3D`, DSR writes a compact status line only when the relevant state changes.

Look for:

`Stadium 2 status:`

The line reports:

- requested and effective renderer;
- active mount species;
- native cache format/count/variant status;
- whether the native cache is compatible and operational;
- hardening-patch status;
- provider StadiumRig availability and activation.

When a native model is loaded, DSR also logs:

`Stadium 2 model:`

with dex number, variant, bone/primitive/texture/animation counts, idle animation and measured model bounds.

Useful public diagnostic APIs are also exported for compatibility tools:

- `stadium3DNative.cacheStatus()`
- `stadium3DNative.modelInfo(species)`
- `stadium3DHardening.cacheCompatibility()`
- `stadium3DProviderRig.active()`
- `stadium3DDiagnostics.snapshot(species)`
- `stadium3DDiagnostics.log(species)`

## Fallback hierarchy

The experimental branch is intentionally defensive:

1. Native Stadium 2 model using the voxel provider's StadiumRig when available.
2. Hardened DSR native DSM4 skinning fallback if the provider rig cannot be used.
3. Randy's compatible Stadium 1 provider for supported Gen I species when present.
4. DSR 2D mount rendering.

A broken native cache or failed safety patch must never be treated as a reason to lose the mount entirely.

## Second validation wave

After Charizard is visually correct, test representative shapes instead of immediately checking all species:

### Flight

- Pidgeot — bird wing animation and anchoring.
- Aerodactyl — wide wing span.
- Dragonair — long body.
- Lugia or Ho-Oh with Crystal 251 — Gen II coverage.

### Ground Ride

- Rapidash — quadruped animation.
- Dodrio — tall narrow body.
- Snorlax — large/wide body and rider placement.
- Suicune — Gen II ground/water transition path.

### Visible Surf

- Lapras — conventional Surf mount.
- Gyarados — extreme body proportions.
- Mantine or Kingdra with Crystal 251 — Gen II Surf coverage.

## Experimental limitations

- This branch is not yet a stable release.
- Final rider seat tuning may still need species-specific visual adjustments after real in-game captures.
- Generated Stadium effects depend on what is present in the DSM4 pack supplied by Crystal 251 and the active voxel provider's rendering capabilities.
- Runtime validation still requires Gen1Recomp/LÖVE plus a user-generated Stadium 2 cache; source-level tests cannot reproduce the final GPU/camera presentation by themselves.
