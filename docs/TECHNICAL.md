# Technical reference

## Ownership model

Dramatic Sky Ride is intentionally structured so optional integrations do not become competing gameplay engines.

### DSR owns

- Flight state;
- Ground Ride state;
- Visible Surf mount state;
- mount selection;
- movement;
- altitude;
- collision decisions;
- progression gates;
- rider placement;
- mount sizing;
- battle/remount lifecycle;
- active mount renderer selection.

### Companion mods may provide

- follower/mount sprites;
- airborne NPCs;
- voxel world rendering and camera modes;
- Pokemon Stadium cache generation;
- Stadium ROM-selection UI;
- Stadium companion models for non-DSR entities;
- player-character selection;
- optional music tracks.

## Settings architecture

Gen1Recomp replaces a mod's full option schema whenever `mod.options:define()` is called. DSR therefore builds one shared `OPTION_SCHEMA` across its source chunks.

The Settings UX layer runs after the feature modules have appended their settings. It republishes the complete schema, then changes only the rows presented by the UI.

Important properties:

- persistent option keys are not renamed;
- hidden rows remain part of the schema;
- hidden saved values are not modified;
- Reset Defaults still sees the complete schema;
- the modern Mod Manager's `optionRows` cache is rebuilt only when the two presentation switches change;
- a legacy `ui.options.rows` path remains as a backward-compatible fallback.

The two presentation keys are:

- `settings_view`;
- `size_overrides`.

## Wild Skies interoperability

DSR uses Wild Skies' documented exports rather than internal entity tables. DSR registers a sprite source where appropriate and consumes eligible flyers through the public take/registration seams.

DSR exports its own active Flight information so other compatible mods can observe the player without taking ownership of Flight.

## Wilds/PokéPC sprite providers

DSR resolves mounted sprites through provider-specific integration layers. The active sprite style used by another mod is not globally rewritten just to improve the mounted presentation.

The PokeMMO mount path is specifically designed to use higher-detail source sprites only when Wilds is already configured for that style.

## Stadium 2 capability separation

DSR treats the following as distinct capabilities:

1. voxel renderer;
2. Stadium cache/import host;
3. ROM-selection UI;
4. existing valid cache;
5. active-mount Stadium renderer;
6. companion Stadium renderer for non-DSR entities.

This is why Battle Art can be a valid renderer for an existing cache even when Dramaless is still the preferred first-time import host.

## Stadium cache and animation

Crystal 251 generates persistent Stadium DSM data under `crystal_251/stadium2/` from the player's own ROM.

DSR's native renderer consumes that cache for supported active mounts. Animation pose/skin advancement is driven from the render path to remain reliable across supported provider update seams.

Whole-model mount presentation is layered on top of genuine Stadium skeletal animation. DSR does not invent a universal per-bone overworld locomotion contract that Stadium 2 does not provide.

## Stadium mount motion

The motion layer applies state-aware whole-model transforms:

- Flight — cadence, forward pitch, climb/dive response, bank;
- Ground Ride — cadence, bob/lean, turn response;
- Visible Surf — buoyancy, pitch, roll;
- Suicune water — dedicated amphibious Ground Ride presentation.

The model and shadow share the same presentation transform so the mount remains visually grounded.

## Provider interoperability

When DSR's native Stadium renderer owns the active mount, compatible Stadium companion mods are gated from independently rebuilding or drawing that same mount. This avoids double models while preserving their unrelated wild/follower/UI functionality.

## Source layout

DSR's entry point reads `src/parts.txt`, concatenates the source chunks in order and compiles the resulting runtime. Late integration layers can therefore be appended after the core gameplay modules without refactoring stable movement code.

The Settings UX module is intentionally late-loaded so it sees the final option schema and can remain presentation-only.
