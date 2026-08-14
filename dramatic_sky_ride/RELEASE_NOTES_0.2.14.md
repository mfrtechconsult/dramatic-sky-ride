# Dramatic Sky Ride 0.2.14

Open Sky integration release for Generation II.

## Open Sky regional soaring

- Integrates the **Open Sky** build previously distributed as `dramatic-sky-ride-open-sky-glb-region-hd-stable-altitude-launcher-ready.zip` into the current stable codebase.
- Open Sky is opt-in and Generation II only.
- Enter the regional layer by climbing above altitude 88 while cruising outdoors.
- Uses Gold's real Johto/Kanto landmark data and visited Fly Points for progression-safe navigation and landing.
- Kanto airspace stays gated by normal progression.
- Regional descent returns to Dramatic Sky Ride still airborne instead of invoking vanilla Fly.

## Manual ORAS-style controls

- No automatic forward movement.
- **Left / Right** steer and bank.
- **Up** applies forward throttle at the 3.4 regional speed profile.
- **Down** brakes.
- **B + Up** boosts to 5.4.
- Existing DSR altitude controls continue to climb/descend.
- **A** descends when close enough to a visited Fly Point.
- Outer boundaries perform a controlled turnaround rather than sticking against the edge.

## GLB-derived regional 3D map

- Uses the baked result of `Meshy_AI_map_monde_de_la_regio_0812201706_texture.glb` rather than loading the ~82 MB / ~1.95M triangle GLB at runtime.
- Runtime terrain uses the baked albedo plus the smoothed 384x296 heightfield.
- The Open Sky 3D canvas renders at the presentation resolution up to **1920x1080**, rather than rendering at 160x144 and magnifying it.
- Flight altitude is absolute and stable: terrain relief moves below the rider and does not push the rider/camera up and down.
- The chase camera remains low/close enough to read the terrain while preserving stable altitude and restrained banking.
- If the 3D provider or GPU path cannot initialize, the illustrated 2D Open Sky view remains playable.

## Compatibility retained from 0.2.13

- Gen1Recomp 0.1.86+ sandbox rules; no filesystem permission is restored.
- PokéPC Followers 0.8.2 legacy provider seam and 0.8.3+ canonical provider API.
- Followers EX and Wilds of Kanto follower integration.
- Wild Skies compatibility with the Gen1-compatible `>=1.4.1 <2.0.0` range.
- Battle Art / Dramaless and current Gen2 voxel interoperability.
- Existing Gen1 Flight, Ground Ride and Visible Surf remain outside the Open Sky path.

This branch is packaged as a launcher-ready test ZIP before `main` is updated and before the GitHub release is published.
