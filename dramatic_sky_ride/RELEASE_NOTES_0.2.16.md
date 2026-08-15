# Dramatic Sky Ride 0.2.16 — Open Sky + Gen2-3D-Sprites hotfix

This hotfix repairs the Open Sky regional artwork regression and restores clean compatibility with **Gen2-3D-Sprites / STADIUM2_OVERWORLD_MODELS 0.2.81**.

## Open Sky maps

- Restores the Johto regional artwork instead of falling back to the green emergency/debug map.
- Restores both Johto and Kanto at the native **312×232** Open Sky viewport.
- Replaces the accidentally degraded/downscaled publication assets with verified native-resolution map data.
- Loads the restored maps from deterministic multipart bundled data and validates the decoded PNG dimensions before rendering.
- Keeps linear filtering for the Stadium 2-style regional artwork while avoiding the previous low-resolution source upscale.

## Gen2-3D-Sprites 0.2.81 compatibility

Randy's current release separates the **3D voxel world** from the **3D Pokémon model** layer and can temporarily report individual Stadium models unavailable while the Stadium 2 pack is missing/rebuilt.

DSR now distinguishes those states correctly:

- `STADIUM2_OVERWORLD_MODELS` remains the owner of the Gen 2 voxel world whenever its voxel renderer is active.
- DSR reads Randy's public `modelsEnabled()` / `voxelPipelineState.status().pokemonModels` model-layer state.
- DSR probes the current mount through Randy's public `overworld.canRenderEntity()` capability.
- If **3D POKÉMON MODELS** is disabled, or the current model is not yet available, DSR automatically renders its proper **2D mount sprite/card** instead of selecting a missing 3D body.
- As soon as the requested model becomes available again, `MOUNT RENDERER = STADIUM 3D` can use it normally.
- No filesystem permission, private cache access or cross-mod ROM access is added to DSR.

A dedicated CI job now checks the public API contract against the exact **Gen2-3D-Sprites v0.2.81** release and LuaJIT-compiles DSR with the compatibility path enabled.

## Regression protection

Dedicated CI checks reconstruct both bundled regional maps and verify:

- valid PNG signatures,
- exact 312×232 dimensions,
- expected SHA-256 checksums,
- and that no `filesystem` permission is introduced.

## Unchanged

No Open Sky movement, city calibration, landing/progression, Wilds 2.1.5 compatibility, normal Flight/Ground/Surf behavior, or sandbox permission behavior is intentionally changed by this release.
