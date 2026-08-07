# Dramatic Sky Ride alpha.15.3 validation checklist

Alpha.15 was validated interactively before publication. Alpha.15.3 keeps the option repair, blocks manual Surf during flight and targets current Gen1Recomp/Dramatic Shape releases.

## Alpha.15.3 regression

- Confirm that the mod options screen exposes 20 entries: 11 flight options and 9 mount options.
- Toggle `SHOW RIDER`, `FLIGHT BOOST`, `GROUND GALLOP` and `VISIBLE SURF MOUNTS`; confirm each feature follows its setting.
- Restart Gen1Recomp and confirm the selected values remain saved.
- Run one takeoff/landing, one Ground Ride gallop and one Surf transition to confirm no behavioural regression.
- Test with Gen1Recomp 0.1.75 and Dramatic Shape 1.7.0.
- Install Dramatic Shape through the in-game Mod Manager ZIP flow and confirm flight terrain-height compensation remains active.

## Ground Ride

- Mount and dismount every supported species.
- Compare Tauros and Snorlax movement profiles.
- Hold `B` in 2D, `1ST` and `3RD`; confirm acceleration, stamina, HUD and dust.
- Cross route/town connections at maximum gallop without a speed break.
- Traverse compatible cave floors and map connections.
- Jump official ledges in both directions and reject blocked, water, warp or occupied landings.

## Battles and party changes

- Win, run from and lose a wild battle while Ground Riding.
- Complete a trainer battle while Ground Riding.
- Faint, remove, reorder or evolve the selected Ground Ride Pokemon.
- Trigger a wild battle while airborne and confirm altitude, boost and rider rendering return correctly.
- Faint or remove the selected flying mount during battle and confirm safe landing.
- Confirm that no rider or trainer ghost entity remains after battle.

## Interactions

- Talk to an NPC and read a sign while mounted.
- Use an item pickup, PC, slot machine, Cut, Surf, fishing, Fly, Dig/Teleport and Strength boulder push; confirm safe dismount before the native action.

## Surf and flight

- While airborne, open a Surf-capable Pokemon's party submenu and confirm native `SURF` is not available.
- While airborne, confirm `SURF & RIDE` is not available and `MOUNTS` contains no `SURF` entries.
- Attempt any native Surf activation path while airborne and confirm it is refused with `LAND FIRST`.
- Land on water with a Surf-capable party and confirm Surf starts automatically.
- Confirm the visible Surf mount activates after that water landing.
- Take off again from Surf.
- Land on dry ground and confirm normal manual Surf is available again.
- Select each visible Surf mount through `MOUNTS` while not flying.
- Confirm the alpha.14 flight camera behaviour in `1ST` and `3RD`.

## Installation regression

- Validate `manifest.json`.
- Compile `main.lua`, `mod.card` and concatenated source in `src/parts.txt` order.
- Build and test the install ZIP.

## Mount sizing

- Confirm `POKEDEX SIZES` is enabled by default.
- Compare a small mount (Rhyhorn/Fearow) with a large mount (Lapras/Dragonair/Gyarados).
- Confirm Gyarados is dramatically larger than Blastoise at 100.
- Change at least one flying, Ground and Surf species size while mounted; confirm the visual scale updates.
- Confirm the rider remains human-sized and its seat height follows the mount.
- Repeat in 2D, voxel orbit, `1ST` and `3RD` where the player card is visible.
- Confirm collisions, ledges, encounters and Surf transitions remain cell-based and unchanged.
- Reset defaults and confirm every species returns to 100.
