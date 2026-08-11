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
- if the requested idle is static but another Stadium clip has changing bone data, DSR selects a real moving clip for the experimental overworld idle;
- if **no clip contains any changing skeletal track**, DSR logs that the generated DSM itself is still static and does not invent a procedural animation;
- alpha.7 drives pose/skin directly from the render path so visible models cannot remain frozen merely because the Overworld update seam did not advance their runtime.

## Alpha.9 mount-motion audit

Alpha.9 audits the complete 41-role roster and strengthens motion where alpha.8 was too subtle to read visually.

- Flight: 16 supported roles remain covered; subtle profiles such as Dragonair, Xatu, Skarmory, Lugia and Ho-Oh receive moderate readability tuning.
- Ground Ride: all 17 profiles were reviewed; fast quadrupeds/equines/runner birds receive clearly stronger bob/pitch/turn response, while heavy bipeds remain restrained.
- Visible Surf: all 8 profiles were reviewed; idle buoyancy and movement/turn response are now visibly stronger.
- Suicune: Ground Ride remains the lifecycle owner on water, but its amphibious state now has a dedicated Stadium `water` presentation instead of falling through to no motion profile.
- `stadium3DMountMotion.audit()` reports profile coverage and whether the model/shadow motion matrices are actually attached.

The normal roster remains 16 Flight + 17 Ground + 8 Visible Surf. Suicune's extra amphibious-water helper is not a ninth Surf mount.

## Recommended alpha.9 visual checks

### Flight

- Charizard — established animation baseline.
- Dragonair — serpentine motion should now be easier to read without bird-like banking.
- Skarmory — moderate armored-bird response.
- Lugia — large-flight response.

### Ground Ride

- Rapidash — one of the strongest Ground profiles; moving/galloping must look clearly different from standing still.
- Dodrio — strong runner-bird body cadence.
- Tauros — strong bovine response.
- Raikou — strong fast-quadruped response.
- Suicune — clear land movement plus dedicated water-running presentation.
- Snorlax — intentionally restrained.
- Tyranitar — intentionally restrained.

### Visible Surf

- Tentacruel — strong buoyancy.
- Gyarados — strong serpentine buoyancy/turn response.
- Lapras — readable but calmer large-swimmer motion.
- Mantine — strongest turn roll among Surf profiles.
- Kingdra — serpentine swimmer response.
- Lugia — large-swimmer response.

## What should be visually correct

- The model must remain assembled during animation; limbs must not twist or separate.
- The mount must face the same direction as DSR movement/facing.
- The model must remain centered on the player's world position.
- Flight altitude must move the entire 3D model without terrain-induced vertical bobbing from unrelated relief.
- The trainer must remain a separate human-sized sprite and sit consistently relative to the resized mount.
- The model must participate in the voxel depth buffer and cast the model-shaped shadow supplied by the voxel provider.
- Skeletal animation should be interpolated rather than visibly stepping at the Stadium source rate.
- Animated Stadium material streams such as eye/blink changes should remain synchronized with the skeleton.
- Generated DSM4 `fxFrames` should animate at the Stadium source rate (30 Hz).
- Generated additive fire must not be included in the shadow pass.
- A missing/invalid Stadium 2 model must fall back instead of making the mount invisible.
- Fast Ground mounts should now have a visibly readable moving/galloping presentation; heavy bipeds should remain substantially calmer.
- Surf mounts should visibly float at rest and react more strongly during travel and turns.

## Runtime diagnostics

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
- `stadium3DRenderClock.stats(dex)`
- `stadium3DMountMotion.coverage()`
- `stadium3DMountMotion.profile(role, species, dex)`
- `stadium3DMountMotion.stats(dex)`
- `stadium3DMountMotion.audit()`
- `stadium3DDiagnostics.snapshot(species)`
- `stadium3DDiagnostics.log(species)`

## Fallback hierarchy

The experimental branch is intentionally defensive:

1. Native Stadium 2 model using the voxel provider's StadiumRig when available.
2. Interpolated, anchored and hardened DSR DSM4 skinning fallback when the provider rig cannot be used.
3. Randy's compatible Stadium 1 provider for supported Gen I species when present.
4. DSR 2D mount rendering.

A broken native cache or failed safety patch must never be treated as a reason to lose the mount entirely.

## Experimental limitations

- This branch is not yet a stable release.
- Stadium 2 still does not provide a trustworthy shared overworld walk/run/swim/fly clip contract.
- Ground Ride therefore remains presentation-based rather than a fabricated generic skeletal gait.
- A future per-species locomotion clip should only be used when the actual Stadium source clip has been visually verified as credible for that species.
- Final rider seat tuning may still need species-specific visual adjustments after real in-game captures.
- Battle Art can consume the cache but cannot currently act as Crystal 251's cache-generation provider by itself.
