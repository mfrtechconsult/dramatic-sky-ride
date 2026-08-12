# Lot 07 — Beta stabilization matrix

Deferred pre-beta verification:

- Pokemon Red, Blue and Yellow;
- keyboard, Xbox-style and PlayStation-style controllers;
- 2D, intermediate voxel views, `1ST` and `3RD`;
- outdoors, caves, floors, warps, connections, Surf and battles;
- followers, save/reload and absent PokePC assets;
- no entity leaks, duplicate riders, permanently hidden followers or persisted mounted saves;
- stable performance and option persistence.

## Active Generation II blockers

- [ ] Restore the exact active mount after every successful battle when
  `REMOUNT AFTER BATTLE` is enabled: Flight, Ground Ride, amphibious Suicune
  and Visible Surf.
- [ ] Preserve the selected Visible Surf species across battle cleanup; a
  custom Gyarados must not fall back to Gold's native Surf sprite or another
  eligible party member.
- [ ] Verify win, flee/catch and loss behavior separately. A loss or an
  unavailable/fainted mount must return safely without forcing a remount.
- [ ] Check the same lifecycle for wild encounters, trainer battles and Wild
  Skies airborne encounters.

After this matrix passes, prepare a beta release with documentation cleanup and no new gameplay systems.
