# Troubleshooting

## Start with a minimal check

If you are not sure which integration is failing, temporarily reduce the stack to:

- Gen1Recomp;
- Dramatic Sky Ride;
- your save.

Confirm native 2D Flight first, then add the sprite provider, Wild Skies, voxel renderer, Crystal/Stadium and music integrations one at a time.

## The settings menu is too long

Set:

`SETTINGS VIEW = SIMPLE`

Simple mode hides advanced rows without changing their saved values.

If you need individual mount sizes, switch to Advanced and set:

`SIZE OVERRIDES = EDIT`

## Simple and Advanced do not change the visible rows

Make sure you are running a DSR build that includes the Settings UX layer. The current implementation rebuilds the active DSR option rows immediately when `SETTINGS VIEW` or `SIZE OVERRIDES` changes.

If the visible rows still do not change, restart Gen1Recomp once and verify that only one Dramatic Sky Ride installation is enabled.

## A mount looks too large or too small

1. Check `REALISTIC MOUNT SIZES`.
2. Switch to Advanced.
3. Set `SIZE OVERRIDES = EDIT`.
4. Adjust only the affected Pokemon.

Hiding the size rows later does not reset the custom value.

## Ground Ride key does not work with Dramaless

Dramaless reserves `G` for V-GRID. Use `J` for Ground Ride in that configuration.

## Wild Skies shows generic-looking Pokemon

Wild Skies can fall back to generic airborne art for species that do not have an appropriate species-specific flying/levitating sheet from an installed sprite source.

This is independent from DSR's mount settings and does not mean the DSR mount renderer is broken.

## Aerial encounters do not happen

Check:

- Wild Skies is installed and enabled;
- `AIR ENCOUNTERS` is enabled in DSR Advanced settings;
- DSR is actually in active Flight cruise state;
- Wild Skies currently has an eligible nearby flyer;
- battle-rest/cooldown behavior is not temporarily suppressing another encounter.

## Followers duplicate or remain visible while mounted

Check the active follower provider and `SHOW FOLLOWERS`/ground follower behavior. Wilds and PokéPC are normally alternatives rather than two simultaneous primary follower engines.

## Flying Music is missing from Simple mode

The row is intentionally contextual. It appears in Simple only when DSR detects at least one usable compatible track.

Use Advanced for full diagnostic visibility of integration settings.

## Stadium 2 model does not appear

Check, in order:

1. Crystal 251 is loaded;
2. a healthy cache exists under `crystal_251/stadium2/`;
3. `STADIUM 2 ROM = READY` where the import/status UI is available;
4. `MOUNT RENDERER = STADIUM 3D`;
5. the selected mount has a valid cached model;
6. a compatible voxel renderer is active.

## Stadium cache works in Dramaless but not Battle Art

Do not rebuild the cache just because you changed renderer. Battle Art is expected to reuse the existing Crystal cache. Check provider/cache visibility and collect diagnostics first.

## Useful diagnostic information for reports

Include:

- Gen1Recomp version;
- DSR version;
- Pokemon species;
- Flight/Ground/Surf state;
- renderer and camera mode;
- Wilds or PokéPC version;
- Wild Skies version;
- Crystal 251 version;
- whether the Stadium cache existed before launch;
- relevant log lines.

For Stadium issues, the public diagnostic surfaces include:

- `stadium3DNative.cacheStatus()`
- `stadium3DCrystalBootstrap.status()`
- `stadium3DProviderInterop.status()`
- `stadium3DProviderRig.active()`
- `stadium3DLiveAnimation.stats(dex)`
- `stadium3DRenderClock.stats(dex)`
- `stadium3DMountMotion.audit()`
- `stadium3DDiagnostics.snapshot(species)`
