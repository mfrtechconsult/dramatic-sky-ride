# Changelog

All notable changes to Dramatic Sky Ride are documented here.

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
- Added a repository backlog for deferred feature work; feature development is paused after this release.

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

- Removed the Pokemon Stadium integration experiment.
- Corrected continuous free flight in `1ST` and `3RD`.
- Corrected boost application and automatic camera follow.
- Added Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

## 0.1.0-alpha.1 to alpha.10

- Progressively introduced takeoff, Charizard/Pidgeot mounts, manual altitude, landing, air collision checks, menus, palettes, shortcuts, effects and Dramatic Shape/follower compatibility.
