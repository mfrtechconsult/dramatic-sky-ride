# Dramatic Sky Ride 0.2.17 — Post-sandbox mount restore

This release restores the last committed post-sandbox mount implementation and discards the later experimental movement changes.

## Restored mount system

- Restores the pre-sandbox seated rider crop entirely in memory, without runtime file writes or a full standing-trainer fallback.
- Bundles the PokePC Generation I-II follower sheets as a dependency-free 2D fallback for Flight, Ground Ride and Visible Surf.
- Restores the Gen2-3D-Sprites 0.2.81 provider bridge, public-provider fallback and single-owner cleanup.
- Restores the bounded 2D mount cards and synchronized rider seats for the close third-person camera.
- Restores Gold's Surf-to-Flight cleanup, shoreline transitions and post-battle remount behavior.

## Scope

The release content is the clean `Fix sandboxed 2D mount rendering` state, reapplied on top of the published 0.2.16 `main`. Later continuous-movement experiments are intentionally excluded.
