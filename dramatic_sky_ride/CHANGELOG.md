# Changelog

## 0.1.0-alpha.15.2.3

- Added the GitHub repository identifier required for launcher and Mod Index update tracking.
- Switched release archives to the Gen1Recomp Mod Index layout with `manifest.json` at the ZIP root.
- No gameplay behaviour changed from the alpha.15 maintenance baseline.

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
