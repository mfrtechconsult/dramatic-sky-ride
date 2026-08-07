# Changelog

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
