# Pokemon Stadium 2 mounts

Dramatic Sky Ride can render the active supported mount with an animated Pokemon Stadium 2 model while DSR continues to own movement, collision, altitude, progression and mounted state.

## Requirements

- Dramatic Sky Ride;
- Crystal 251 `>=0.9.13 <1.0.0`;
- a supported voxel renderer;
- a compatible legally obtained Pokemon Stadium 2 US ROM supplied by the player;
- a completed Crystal 251 Stadium 2 cache.

DSR never includes or redistributes the ROM or Nintendo Stadium model assets.

## Cache location

The generated persistent cache lives under:

`crystal_251/stadium2/`

A healthy cache contains the DSM data used for supported normal and shiny models.

## Recommended first-time import

Dramaless is currently the simplest complete import host.

1. Enable DSR.
2. Enable Crystal 251.
3. Enable Dramaless Shape.
4. Start the game.
5. Open the relevant Options/Mod Manager screen.
6. Find `STADIUM 2 ROM`.
7. Select your compatible Pokemon Stadium 2 ROM.
8. Wait for Crystal 251 to finish building the cache.
9. Confirm the row reports `READY`.
10. In DSR, set `MOUNT RENDERER = STADIUM 3D`.

## What `READY` means

`STADIUM 2 ROM = READY` means DSR/Crystal can see a healthy existing cache.

A successful cache should remain usable after restarting the game. Restoring the import/status UI must not delete or rebuild a healthy cache.

## Using Battle Art after import

Battle Art is supported for rendering a healthy existing Stadium 2 cache.

Recommended workflow:

1. generate the cache once with Crystal 251 + Dramaless + DSR;
2. confirm `READY`;
3. close the game;
4. switch to Battle Art if that is your preferred renderer;
5. keep Crystal 251 and DSR enabled;
6. keep the existing `crystal_251/stadium2/` cache;
7. use `MOUNT RENDERER = STADIUM 3D`.

## Renderer ownership

DSR's native Stadium path replaces only the active DSR mount presentation. The trainer remains a separate rider.

Compatible companion mods can continue to render their own wild Pokemon, followers and UI. DSR's provider interoperability layer prevents both sides from claiming the same active mount at once.

## Animation model

The Stadium cache contains genuine skeletal animation data. DSR keeps those animation tracks and adds mount-state presentation around them:

- Flight: speed-sensitive cadence, forward pitch, climb/dive response and banking;
- Ground Ride: movement cadence, body bob/lean and turn response;
- Visible Surf: buoyancy, pitch and water-turn roll;
- Suicune: dedicated amphibious water presentation while remaining a Ground Ride state.

DSR does not claim that Pokemon Stadium 2 exposes one universal overworld walk/run/fly/swim animation contract. Arbitrary battle attacks are not reused as fake locomotion.

## Reimporting

Reimport is only needed when you intentionally want to rebuild/replace the cache or when diagnostics show that the cache is invalid.

Do not delete a healthy cache merely because you changed renderer.

## Troubleshooting

### `STADIUM 2 ROM` row is missing

Check that:

- Crystal 251 is enabled and loaded cleanly;
- a compatible import host is enabled for the first build;
- DSR is enabled;
- the versions satisfy the manifest ranges.

### The row is present but not `READY`

The cache may not exist yet or may have failed validation. Re-run the import flow and inspect the log for Crystal/DSR Stadium diagnostics.

### Battle Art does not offer first-time import

That is expected in the current compatibility model. Build the cache first with a complete import host such as Dramaless, then return to Battle Art.

### The mount disappears in Stadium 3D

DSR is designed to fall back when a native Stadium model cannot be used. If you get no fallback, collect diagnostics and report the selected Pokemon, renderer, Crystal version and cache status.

See [Troubleshooting](TROUBLESHOOTING.md) and [Technical reference](TECHNICAL.md) for diagnostic APIs.
