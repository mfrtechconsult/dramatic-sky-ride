# Dramatic Sky Ride alpha.15 validation checklist

Alpha.15 was validated interactively before publication. This file remains as a regression checklist for future bug fixes.

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

- Land on water with a Surf-capable party.
- Take off again from Surf.
- Select each visible Surf mount through `MOUNTS`.
- Confirm the alpha.14 flight camera behaviour in `1ST` and `3RD`.

## Installation regression

- Validate `manifest.json`.
- Compile `main.lua`, `mod.card` and concatenated source in `src/parts.txt` order.
- Build and test the install ZIP.
