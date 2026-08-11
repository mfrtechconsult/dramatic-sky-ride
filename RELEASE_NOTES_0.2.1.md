# Dramatic Sky Ride 0.2.1

## Simpler settings

0.2.1 focuses on configuration and documentation without intentionally changing Flight, Ground Ride, Visible Surf, collision, progression or Stadium mount gameplay.

- Added `SETTINGS VIEW = SIMPLE / ADVANCED`.
- Simple mode keeps the main player-facing controls visible and hides specialist configuration.
- Advanced mode retains the complete settings surface for existing and power-user setups.
- Added `SIZE OVERRIDES = HIDDEN / EDIT` so per-species mount sizes no longer dominate the normal menu.
- Hidden settings and individual size values remain saved and active; the new switches only control presentation.
- Reordered the Advanced view into a clearer logical flow.
- Improved selected user-facing labels while preserving all persistent option keys.
- The Mod Manager now rebuilds DSR's visible option rows immediately when Settings View or Size Overrides changes.

## Documentation overhaul

- Replaced the oversized front-page README with a concise quick-start guide.
- Added dedicated Installation, Settings, Compatibility, Pokemon Stadium 2, Troubleshooting and Technical Reference pages under `docs/`.
- Consolidated Stadium 2 first-time import, cache persistence, `READY`, Dramaless/Battle Art roles and reimport guidance.
- Documented DSR's ownership model so movement/gameplay responsibilities are clearly separated from renderers, sprite providers and ecosystem mods.
- Refreshed the changelog with the stable 0.2.0 and 0.1.7 milestones.

## Compatibility

- No intended changes to Wild Skies behavior in this release.
- No intended changes to Wilds of Kanto, PokéPC Followers, Battle Art, Dramaless, Crystal 251, Stadium companion, OTF Player Switcher or Flying Music gameplay integrations.
- Existing 0.2.0 option keys and saved values remain compatible.

## Installation

The release ZIP is launcher-ready with `manifest.json` at the archive root.

DSR does not include Pokemon Stadium 2 ROM/model assets. Stadium 2 models are generated locally from the player's own compatible ROM through Crystal 251.
