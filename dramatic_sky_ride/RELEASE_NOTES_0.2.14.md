# Dramatic Sky Ride 0.2.14 — Open Sky

This release integrates the latest **Open Sky Stadium 2 fidelity v20** gameplay on top of the 0.2.13 stable codebase.

## Open Sky

- Gen 2 regional soaring for Johto and Kanto.
- Bundled Pokemon Stadium 2-inspired regional map renders; no ROM access is required at runtime.
- `OPEN SKY` is available directly in the **SIMPLE** settings view.
- Free screen-space navigation with smooth acceleration/deceleration and constant terrain-independent speed.
- Normal speed is 56 viewport px/s; hold B for the 96 px/s boost.
- Terrain, water and map geometry never collide with or slow the mount.
- Kanto and Johto behave as adjacent airspaces: fly west from Kanto to reach Johto, and east from Johto to reach Kanto when Kanto is unlocked.
- Stable 2D regional presentation designed for city-position calibration in this release.

## Landing and progression

- Only settlements are exposed as landing targets.
- Individual city `ENGINE_FLYPOINT` / spawn-visited state is authoritative.
- Unvisited cities remain visible but locked and cannot be used to descend.
- The vanilla Kanto `SPAWN_INDIGO` picker gate is not reused as a blanket visited-city rule.

## City Calibration Editor

The release includes the in-session **Open Sky City Editor** so the final positions of the 10 Johto and 10 Kanto cities can be calibrated against the regional maps.

- F8: enter/leave editor.
- F5: switch Johto/Kanto.
- F6/F7: previous/next city and jump to its current position.
- Arrow keys: move point; Shift = fine, Ctrl = ultra-fine.
- F9: validate current city and advance.
- F10: reset current city to the bundled position.
- F4: clear every in-session validation.
- F11: copy/export the complete validated report.

A complete calibration report contains **20 coordinate lines** in `region|landmark_id|x|y` format. Clipboard export is used when available, with runtime-log output as fallback. Calibration remains session-only until the validated coordinates are integrated into the bundled landmarks.

## Compatibility retained

- Gen1Recomp 0.1.86+ sandbox rules.
- PokéPC Followers 0.8.2 legacy seam and 0.8.3+ provider API.
- Followers EX and Wilds of Kanto follower integrations.
- Wild Skies `>=1.4.1 <2.0.0`.
- Battle Art / Dramaless and current Gen 2 voxel interoperability for normal Dramatic Sky Ride mounts.
- No cross-mod raw filesystem discovery is restored.

The attached ZIP is launcher-ready and is rebuilt and LuaJIT-validated by the release workflow before publication.
