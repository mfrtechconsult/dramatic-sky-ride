# Changelog

All notable changes to Dramatic Sky Ride are documented here.

## 0.2.8

### Generation II Ground Ride map restrictions

- Matched Ground Ride permissions to Gold's native Bicycle environments.
- Terrestrial mounts now dismount automatically when entering indoor buildings or dungeons.
- Towns, routes, caves, gatehouses and seamless map passages preserve the active Ground Ride mount.
- Amphibious Suicune remains mounted on water and is not affected by the building-only guard.
- Added regression coverage for native Gold warps and the rideable environment allowlist.

## 0.2.7

### Generation II Flight presentation

- Suppressed Gold's ground-level grass rustle animation while an airborne Flight mount crosses tall grass.
- Preserved native grass state, encounters, collisions and all movement outside Flight.
- Added regression coverage for the Generation II Flight terrain-effect guard.

## 0.2.6

### Generation II post-battle mount restoration

- Restored Flight, Ground Ride and Visible Surf only after Gold has fully returned to free roam following a battle.
- Preserved the exact selected Visible Surf mount across battle cleanup, including Gyarados and amphibious Suicune.
- Prevented Gold's generic native Surf sheet from being cropped and rendered on top of a restored custom water mount.
- Applied `REMOUNT AFTER BATTLE` consistently to every mount type.
- Declined automatic remount safely after a loss or when the saved mount is fainted, missing or no longer eligible.
- Added Generation II battle-remount regression coverage and a full Lua 5.1 runtime compilation check.

## 0.2.5

### Generation II transition fix

- Fixed Visible Surf's native Gold sprite being reused as the rider when taking off directly from Gyarados or another water mount.
- Added automated Gold coverage for the complete Visible Surf-to-Flight transition.
- Documented the temporary New Bark Town test NPC and the `BADGE CHECKS = OFF` rapid-test setting.

## 0.2.4

### Generation II support

- Declared Gen2 compatibility in the normal release manifest.
- Added Gold-native live-player bridges for Flight, Ground Ride and Visible Surf rendering and movement.
- Added Generation II mount selection, Pokedex sizing fallbacks and 2D provider-safe sprites.
- Added seamless airborne map connections, Gold reverse-ledge jumps and native water-landing Surf transitions.
- Preserved authored map topology, ordinary solid-wall collision and existing progression rules.
- Added automated Gold coverage for mount activation, Ground-to-Flight switching, map connections, reverse ledges, water landing, shoreline exit and ordinary Surf.

### Testing scope

- Added a temporary New Bark Town NPC that gives Ho-Oh, Suicune, Raikou and Gyarados for rapid Gen2 testing.
- Badge requirements can be disabled from DSR settings during testing.
- Generation II voxel/Stadium rendering remains dependent on compatible companion providers; 2D is the validated Gen2 path in this release.

## 0.2.3

### Gen 1 runtime stability

- Fixed Flight and Visible Surf being bypassed when Wild Skies re-armed its overworld update watchdog around DSR.
- Preserved the complete DSR update chain after the new Gen 1 Surf and Gold Suicune compatibility layers were added.
- Prevented false hook recovery when an outer cooperative wrapper still owns the complete DSR update root.
- Allowed native Surf state to bootstrap Visible Surf recovery before DSR's private water-mount state exists.
- Added regression coverage for the complete Gen 1/Gen 2 wrapper chain and cooperative watchdog composition.

### Generation II beta

- Included the generation-aware runtime, progression and Gold Suicune compatibility work for continued beta testing.
- Kept the standard release manifest conservative: Gen 2 is not declared in the normal package while real Gold testing continues.
- Kept all companion integrations optional; native 2D remains the dependency-free fallback.

## 0.2.2

### Wild Skies / Wilds of Kanto compatibility

- Updated compatibility work for Wilds of Kanto 1.14.x and Wild Skies 1.8.x.
- Wild Skies now remains authoritative for airborne sprite-source ordering when Wilds of Kanto is enabled.
- Removed DSR's direct filesystem scan for Wild Skies flyer sprites, preventing installed-but-disabled follower mods from influencing sky rendering.
- DSR explicitly removes its own legacy Wild Skies sprite source before allowing Wild Skies' built-in Wilds `levitates` adapter to resolve airborne species art.
- Retained a species-specific DSR fallback through Wild Skies' public `registerSpriteSource` API only when Wilds is absent and a compatible enabled follower provider is available.
- Added `wildSkies.spriteIntegrationMode()` diagnostics to identify the active integration path.
- Flight movement, Ground Ride, Visible Surf and Stadium 2 mount gameplay are unchanged.

## 0.2.1

### Settings UX

- Added `SETTINGS VIEW` with Simple and Advanced presentations.
- Simple mode keeps the main Flight/Ground/Surf controls visible while hiding specialist configuration.
- Contextual Simple rows appear only when their integration is useful, including Wild Skies air encounters, detected Flying Music and Stadium renderer selection.
- Added `SIZE OVERRIDES` so the per-species size controls no longer dominate the normal settings menu.
- Hidden advanced settings and per-species sizes retain their saved values.
- Reordered Advanced settings into a more predictable logical flow.
- Improved selected labels without renaming persistent option keys: `REALISTIC MOUNT SIZES`, `SHOW FOLLOWERS`, `GALLOP HUD`, `QUEST COLLISIONS`.
- Added immediate Mod Manager row rebuilding when Settings View or Size Overrides changes.

### Documentation

- Replaced the oversized project front page with a concise quick-start README.
- Added dedicated installation, settings, compatibility, Stadium 2, troubleshooting and technical documentation pages.
- Consolidated first-time Stadium import, cache persistence, `READY`, Dramaless/Battle Art roles and reimport guidance.
- Documented DSR's gameplay-ownership model and capability-based integrations.

### Gameplay

- No intended Flight, Ground Ride, Visible Surf, collision, progression or Stadium mount gameplay changes in this release.

## 0.2.0

### Stadium 2 mounts

- Promoted the native animated Pokemon Stadium 2 mount renderer to the stable branch.
- Added genuine Stadium 2 skeletal animation, interpolation and compatible effect-frame animation for the active DSR mount.
- Covered the complete current mount roster: 16 Flight, 17 Ground Ride and 8 Visible Surf roles, plus Suicune's amphibious-water presentation.
- Added morphology-aware Flight, Ground Ride and Surf presentation while keeping DSR authoritative for movement, collision, altitude, progression, rider state and sizing.
- Added Crystal 251 `>=0.9.13` Stadium cache support and fixed the `STADIUM 2 ROM = READY` bridge so a healthy cache remains available after restart.
- Separated voxel renderer, Stadium import host and ROM-selection capabilities for cleaner Battle Art, Dramaless and companion interoperability.
- Added explicit `STADIUM_OVERWORLD_MODELS` interoperability to prevent duplicate active-mount rendering.

### Existing features retained

- Native renderer-independent 2D Flight.
- Generation II Flight/Ground/Surf mounts.
- Wilds of Kanto and maintained PokéPC Followers compatibility.
- Wild Skies aerial encounters.
- Optional high-detail PokeMMO mounted sprites.
- OTF Player Switcher compatibility.
- Optional FRLG/HGSS/LGPE Flying Music integration.
- Suicune seamless land/water Ground Ride.

## 0.1.7

- Added optional OTF Player Switcher rider compatibility.
- Added the high-detail PokeMMO mounted sprite path for Wilds of Kanto and corrected transparent-padding size distortion.
- Added canonical Generation II height fallbacks for coherent Pokédex-proportional mount sizing.
- Improved flat 2D Flight presentation over tall buildings while preserving authoritative collision altitude.
- Added defensive source-loader boundary normalization for late compatibility chunks.

## 0.1.0-alpha.15

- Added species-aware Ground Ride profiles for speed, acceleration, gallop strength, stamina and rider positioning.
- Added Snorlax as a deliberately slow terrestrial mount.
- Added Ground Ride stamina HUD, cries, dust, landing effects, sound and vibration.
- Fixed gallop support in Dramatic Shape free-movement `1ST` and `3RD` modes.
- Preserved flight boost and Ground Ride momentum across connected-map transitions in 2D and voxel views.
- Added the `MOUNTS` START-menu entry for Ground Ride, flight and Surf selection.
- Added visible Blastoise, Tentacruel, Gyarados and Lapras Surf mounts while retaining native Surf rules.
- Remembered the preferred Ground Ride mount across party reordering and compatible map transitions.
- Hardened post-battle restoration for wild battles, trainer battles, evolution, fainting and party changes.
- Preserved airborne altitude, boost and rider rendering after battles and removed stale ghost rider entities.
- Added guarded two-way official ledge jumps with species-weighted presentation.
- Allowed ordinary NPC conversations and sign reading while mounted.
- Added safe automatic dismount before incompatible native interactions and field actions.
- Kept the validated alpha.14 flight camera behaviour unchanged.

## 0.1.0-alpha.14

- Added Ground Ride for Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan and Tauros.
- Added the separate `G` / `SELECT + L1` terrestrial shortcut and party `RIDE` action.
- Kept native collisions, encounters, scripts, warps and cave/outdoor traversal.
- Added safe traversal of official low ledges in both directions.
- Added follower hiding/restoration and battle/map-transition recovery.

## 0.1.0-alpha.13

- Allowed water landings when at least one party Pokemon knows `SURF`.
- Activated native Surf state, music and water collisions after landing.
- Added direct takeoff from water with `F` or `SELECT + R1`.
- Updated landing validation, followers and music for Surf transitions.

## 0.1.0-alpha.12

- Removed automatic flight and its destination menu/code.
- Retained camera follow only as a visual aid.
- Kept fully manual free flight in `1ST` and `3RD`.

## 0.1.0-alpha.11

- Removed the early Pokemon Stadium integration experiment.
- Corrected continuous free flight in `1ST` and `3RD`.
- Corrected boost application and automatic camera follow.
- Added Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

## 0.1.0-alpha.1 to alpha.10

- Progressively introduced takeoff, Charizard/Pidgeot mounts, manual altitude, landing, air collision checks, menus, palettes, shortcuts, effects and Dramatic Shape/follower compatibility.
