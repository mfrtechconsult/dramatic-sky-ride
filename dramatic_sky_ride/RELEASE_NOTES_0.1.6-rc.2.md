# Dramatic Sky Ride 0.1.6-rc.2

Development candidate for the next compatibility preview. This version is **not published automatically** from the development branch.

## Native 2D flight

- Flight no longer requires an active voxel pipeline.
- Flat 2D uses the same flight state, altitude, collision and progression logic as voxel flight.
- The trainer is drawn first and the mount second, producing a readable seated pose without a second y-sorted rider entity.
- Existing Pokédex-proportional mount sizing and per-species size controls apply to the 2D mount automatically.

## Renderer priority

- Added `FLIGHT RENDERER`.
- `2D SPRITES` is the default and preferred mode.
- `STADIUM 3D` is an explicit opt-in only.
- Stadium becomes effective only when Pokémon Stadium Overworld Models is installed and a voxel pipeline is active; otherwise DSR falls back to 2D without refusing takeoff.
- Canonical inter-mod flight state remains renderer-independent through `isFlying()`, `altitude()` and `mount()`.
- Existing Stadium aliases remain for compatibility, but `mountSpecies()` is exposed to the Stadium bridge only while Stadium rendering is effectively enabled.
- `currentLift()` is still intentionally not approximated.

## Existing rc.1 compatibility work retained

- Wilds of Kanto follower/sprite integration and cooperative update-hook recovery.
- Wild Skies airborne encounter integration.
- Pokémon Stadium compatibility surface.
- Optional Flying Music from installed FRLG/HGSS/LGPE music packs without redistributing third-party audio.
- Dramaless and Battle Art compatibility coverage with Dramatic Deep Dive / Kanto Dive.

## Testing focus

Please test both of these paths independently:

1. Gen1Recomp + a compatible Pokémon sprite provider + DSR with **no voxel mod enabled**.
2. DSR with Battle Art or Dramaless enabled, switching `FLIGHT RENDERER` between **2D SPRITES** and **STADIUM 3D** where Stadium models are available.
