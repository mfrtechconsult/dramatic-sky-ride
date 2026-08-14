# Dramatic Sky Ride 0.2.12

This is the Gen1Recomp 0.1.86 sandbox compatibility release.

## Sandbox migration

- Requires Gen1Recomp **0.1.86 or newer**.
- Removes the obsolete `filesystem` permission.
- Stops enumerating or reading other mods' folders.
- Cross-mod integration now goes through `mod.find(...).exports` and provider APIs.
- DSR-owned files use `mod:read` / `mod.assets`.
- Runtime rider-sheet filesystem writes are removed; the live player renderer is used as the safe fallback.
- Direct Crystal 251 DSM-cache reads are disabled until Crystal 251 exposes a sandbox-safe public bridge.
- The legacy Stadium 2 cache invalidator no longer deletes another mod's file; it can only request a provider-side cache clear.
- Direct FRLG/HGSS/LGPE music-folder discovery is disabled; DSR-local flight music remains supported.

## Preserved from 0.2.11

- Wild Skies 1.9+ Generation II interoperability.
- Gold continuous 1ST/3RD flight movement.
- Native 2D flight, Ground Ride and Visible Surf.
- Battle Art and Dramaless optional voxel integration through their public exports.

## Known limitations

- HGSS-style overworld sprites can still fail to display on the Generation II path.
- Wilds of Kanto remains outside the validated stable support matrix.
- Native Stadium 2 DSM mounts sourced from Crystal 251 are temporarily unavailable until a public sandbox-safe cache/model bridge exists.

The attached ZIP is launcher-ready and is reconstructed and compiled with LuaJIT by the release workflow before publication.
