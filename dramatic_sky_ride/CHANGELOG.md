# Changelog

## 0.1.1-compat.6 — temporary test branch

- Promotes `BATTLE_ART_VOXEL_FORK` 1.7.6+ to the primary voxel provider used by DSR.
- Keeps the retired `DRAMATIC_SHAPE` id as a best-effort legacy fallback for existing installations.
- Uses the fork's normal public `exports.lib` API instead of patching Battle Art internals.
- Moves the keyboard flight shortcut from `F` to `H`: Gen1PC Overworld Encounters reserves `F`/`V` for follower attacks and was displaying `No follower POKéMON found!` when DSR removed the follower for flight.
- Keeps `G` for Ground Ride and updates Ground Ride -> Flight switching to use `H` as well.
- Controller shortcuts remain `X` for Flight and `Y` for Ground Ride.
- Retains Battle Art 3D battle lifecycle protection: Ground Ride is removed before the battle-world snapshot and normal mount restoration runs after battle.
- Final release packaging is validated by rebuilding the exact concatenated `sky_ride.lua` from the packaged ZIP and compiling it with LuaJIT.

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

- Added `DISCOVERY GATES`: airborne traversal cannot enter canonical vanilla routes/cities until that map has been reached through normal non-DSR-flight gameplay.
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
