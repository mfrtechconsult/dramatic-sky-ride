# Battle Art Voxel Fork 1.7.6 compatibility matrix

Target: `BATTLE_ART_VOXEL_FORK` 1.7.6 with Dramatic Sky Ride 0.1.1-compat.2.

The same DSR ZIP must also continue to work with upstream `DRAMATIC_SHAPE` 1.7+.
Never enable both voxel providers at once.

## Provider selection

- Battle Art Voxel Fork 1.7.6 only: DSR loads and reports full provider capabilities.
- Upstream Dramatic Shape 1.7+ only: DSR loads with the same full feature set.
- Neither provider: DSR fails with a clear provider-required error.
- Both providers: DSR fails with a clear ambiguous-provider error instead of mixing APIs.

## Overworld / camera parity

- Test OFF, FULL, 15, 35, 50, 75, 1ST and 3RD.
- Take off and land in 2D/orbit/1ST/3RD.
- In 1ST and 3RD, camera look changes altitude when CAMERA ALTITUDE is enabled.
- Right-stick look, mouse look, R2/L2 and Page Up/Page Down remain functional.
- Flight boost and camera follow remain smooth.
- Ground Ride and visible Surf remain functional.
- Pokédex mount scaling works in voxel mode, including shadows.

## Battle Art settings

Run at least one wild and one trainer battle for each relevant presentation path:

- 3D-BTL ON and OFF.
- BATTLE ART STATIC, ANIMATED and ROM.
- PLAYER FRONT SPRITES and BACK SPRITES.
- BACK PLACEMENT AUTO, WORLD and OG UI.
- HUD SCALE SCALED and OG.

DSR must not modify Battle Art's chosen Pokémon/trainer art, battle HUD placement, animations or battle camera.

## Mount lifecycle around battles

### Ground Ride

- Enter a wild battle while riding.
- Enter a trainer battle while riding.
- Confirm the mount/rider is removed before the staged-battle cast snapshot.
- After the battle, confirm Ground Ride resumes once and only once.
- Confirm no stale/duplicate rider entity remains.

### Flight

- Start a battle while airborne.
- Win, run, capture and lose where applicable.
- Confirm altitude, selected mount, boost and rider state restore correctly after win/run/capture.
- If the mount is fainted/removed, confirm the existing emergency landing path is used.
- Confirm Battle Art restores its overworld cast/camera before DSR reconciles airborne visual entities.

### Wild Skies 1.3.1

- Intercept a visible flyer while airborne.
- Confirm exact species and level enter the battle.
- Repeat with Battle Art STATIC, ANIMATED and ROM.
- Confirm AIR ENCOUNTERS OFF leaves Wild Skies visible without DSR interception.
- Confirm disabling Wild Skies leaves DSR functional.

## Other battle-mod coexistence

DSR deliberately does not own battle AI, move choice, damage calculation, battle HUDs or `pokemon.sprite`.
When available, smoke-test with current battle/QOL mods such as Auto Battle, Damage Numbers, Battle Move Info, Switch Advisor, Critical Capture and widescreen battle presentation. Their mechanics/UI should remain unchanged; DSR should only prepare/restore mount state around the battle.

## Regression

- PokePC Followers installed and removed: takeoff/landing and post-battle follower restoration remain clean.
- Custom maps remain allowed by default by DISCOVERY GATES.
- Wild Skies remains optional.
- Free Fly remains intentionally conflicting with DSR.
- Stable `main` remains v0.1.0 during this temporary test.
