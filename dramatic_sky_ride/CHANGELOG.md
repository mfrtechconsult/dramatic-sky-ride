# Changelog

## 0.1.5

- Fixed Dramaless Shape voxel detection: current Dramaless releases register the canonical `voxel` pipeline, not `st_voxel`.
- A stale or incorrect provider pipeline hint no longer makes DSR report `Turn VOXEL on before taking off.` while a supported voxel pipeline is visibly active.
- Added a compatibility fallback that checks `voxel` first and retains `st_voxel` only for older forks.
- Added a one-time provider/pipeline/level diagnostic log to simplify future compatibility reports.
- Battle Art Voxel Fork remains preferred when both providers are installed and continues to use its existing `voxel` pipeline unchanged.
- No Flight, Ground Ride, visible Surf, Wild Skies or music functionality was added or changed in this bugfix release.

## 0.1.4

- Raised the supported Dramaless Shape baseline to `DRAMALESS_SHAPE >=1.6.4 <2.0.0`.
- Dramaless Shape 1.6.4 keeps the public `exports.lib` API and `st_voxel` pipeline used by DSR while fixing the 1ST/3RD menu softlock and camera-control issues present in 1.6.3.
- Battle Art Voxel Fork remains supported at `BATTLE_ART_VOXEL_FORK >=1.7.6 <2.0.0`; its latest release and `feature/battle-art` branch are still identical at 1.7.6.
- No flight, Ground Ride, visible Surf or Wild Skies gameplay behavior changed in this compatibility release.

## 0.1.3

- Added Dramaless Shape (`DRAMALESS_SHAPE`) as a supported alternative voxel provider alongside Battle Art Voxel Fork.
- Provider integration now uses the selected provider's public `exports.lib` API and exported voxel pipeline id (`voxel` or `st_voxel`).
- Battle Art Voxel Fork remains preferred when both supported providers are installed.
- Added global `FLIGHT SPEED` and `GROUND SPEED` options from 50% to 200%, while preserving species-specific profiles, Flight boost and Ground gallop behavior.
- Applied the global speed multipliers to standard movement, voxel 1ST/3RD FreeMove and seamless connected-map movement paths.
- When Dramaless is selected, Ground Ride automatically uses `J` because Dramaless reserves `G` for V-GRID; controller `X`/`Y` controls remain unchanged.
- Removed the temporary Ground Ride `JUMP` notice while keeping jump animation, audio, rumble and landing feedback.
- Removed the `Visible Surf mount active.` activation dialog without changing visible Surf behavior.
- Retained the 0.1.2 Surf 3RD camera correction and Wild Skies 1.4.1+ two-cell interception envelope.

## 0.1.2

- Fixed visible Surf in Battle Art Voxel Fork `3RD`: water cells no longer collapse the third-person camera boom as if they were pedestrian obstacles, so the trainer and Surf mount remain visible at normal camera angles.
- Kept `1ST` as a true first-person view; DSR does not force the trainer or mount into the first-person camera.
- Updated the recommended Wild Skies baseline to `1.4.1+`.
- Increased DSR's Wild Skies interception envelope from one cell to two cells, making mid-air encounters substantially easier with Wild Skies' newer three-dimensional roaming flocks.
- Wild Skies remains optional and independent; DSR continues to use only its public `registerSpriteSource` / `takeFlyer` integration surface.

## 0.1.1

- Promoted the validated Battle Art compatibility work to stable.
- `BATTLE_ART_VOXEL_FORK >=1.7.6 <2.0.0` is now the primary required voxel provider.
- `PokePCFollowers_VoxelMerge` is now required as the overworld Pokémon/NPC sprite provider used by mount rendering.
- The retired `DRAMATIC_SHAPE` provider is no longer a supported manifest dependency; a best-effort runtime fallback remains for old manual installs.
- DSR now selects Battle Art Voxel Fork first through its public `exports.lib` API and does not patch Battle Art sprite/battle internals.
- Added Battle Art staged-battle lifecycle protection so Ground Ride entities are removed before the battle-world snapshot and restored cleanly afterward.
- Moved the keyboard Flight shortcut from `F` to `H` because Gen1PC Overworld Encounters reserves `F`/`V` for follower attacks.
- Ground Ride remains `G`; controller shortcuts are `X` for Flight and `Y` for Ground Ride.
- Wild Skies remains optional but is strongly recommended; DSR uses its public API for visible airborne Pokémon and exact species/level aerial encounters.
- Release packaging is validated by reconstructing the exact packaged `sky_ride.lua` and compiling it with LuaJIT before publication.

## 0.1.0

- Promoted the validated alpha.16 feature set to the first stable Dramatic Sky Ride release.
- Removed the experimental manifest flag and restored GitHub/Mod Index update metadata for stable SemVer releases.
- Added story-aware FLY progression: optional FLY requirement, THUNDERBADGE takeoff gate, SOULBADGE water-landing gate and data-driven story gates.
- Added `DISCOVERY GATES`: first-time airborne entry into canonical vanilla Kanto routes/cities is blocked until the map has been reached through normal gameplay.
- Unknown/custom map ids remain allowed by default; custom mods can optionally register discovery gates or mark legitimate visits through DSR's public flight-rules API.
- Added camera-directed altitude in Dramatic Shape 1ST/3RD modes.
- Added optional Wild Skies integration through its public API, including real per-species follower/overworld sprites when available and exact visible flyer species/level battles.
- Kept Wild Skies separate and optional; Free Fly remains a conflicting alternative flight engine.
- Includes the alpha.16 startup/scope fixes and the Ground Ride sizing crash fix validated during testing.

## 0.1.0-alpha.16.4

- Added `DISCOVERY GATES`: airborne traversal cannot enter canonical vanilla Kanto routes/cities until that map has been reached through normal non-DSR-flight gameplay.
- Progression discovery is stored per save through `mod.save`; walking, Ground Ride, Surf and ordinary/scripted non-flight entries count as legitimate visits, while DSR flight entries do not.
- Saffron City and unvisited vanilla routes are therefore protected from first-time airborne sequence breaks even when no explicit badge gate catches the seam.
- Unknown/custom map ids remain allowed by default for map-pack and total-conversion compatibility.
- Added optional `flightRules.registerDiscoveryGate`, `markMapReached`, `isMapReached` and override helpers so custom integrations can opt in without depending on DSR internals.

## 0.1.0-alpha.16.3

- Fixed a Ground Ride crash triggered immediately by `G`: the Pokédex sizing wrapper referenced `GROUND_PROFILES`, which is private to the alpha.15 polish scope and therefore resolved as nil.
- Ground rider seat scaling now uses its own stable lift table instead of another chunk's private locals.
- Removed invalid global wrappers around the private visible-Surf builder/rider symbols and made Pokédex height lookup fall back to the canonical Pokémon definition.
- Added a Ground Ride smoke-test requirement before Wild Skies validation.

## 0.1.0-alpha.16.1

- Fixed the alpha.16.0 startup failure caused by exceeding Lua's 200-local-variable limit in the concatenated DSR source.
- Isolated the alpha.16 flight-rules, camera-altitude and Wild Skies integration modules in nested scopes without changing their gameplay behaviour.
- Kept Wild Skies optional and Free Fly conflicting.

## 0.1.0-alpha.16.0 — experimental

- Adds story-aware FLY progression: optional FLY requirement, THUNDERBADGE flight gate, SOULBADGE water-landing gate, and data-driven story/badge connection gates.
- Adds camera-driven altitude in Dramatic Shape 1ST/3RD modes.
- Adds optional Wild Skies integration through its public API, including exact species/level aerial interceptions.
- Registers real per-species follower/overworld sprites with Wild Skies when available.
- Declares Free Fly as a conflicting alternative flight engine.

## 0.1.0-alpha.15.5

- Kept the Mod Index-compatible ZIP layout introduced in alpha.15.4.
- Disabled manifest-level GitHub auto-update tracking while the mod uses prerelease SemVer tags.
- No gameplay behavior changed from alpha.15.4.
