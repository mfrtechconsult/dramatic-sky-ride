# Lot 05 — Geometry-aware air collision safety

Deferred technical work:

- read actual Dramatic Shape terrain and voxel height around the mount;
- detect cliffs, trees, walls, facades, roofs and protruding voxel objects;
- prevent penetration without abrupt vertical camera motion;
- preserve manual altitude control;
- apply correction to the mount, not camera orientation;
- expose `AIR COLLISION SAFETY: OFF / BASIC / FULL`.

This lot requires isolated performance testing and must fail safely on unsupported maps.
