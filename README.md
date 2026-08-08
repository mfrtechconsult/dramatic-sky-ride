# Dramatic Sky Ride 0.1.2

Dramatic Sky Ride adds controllable flying, terrestrial and visible Surf mounts to **Gen1Recomp**.

## Download

Use the launcher-ready ZIP attached to the latest GitHub release:

https://github.com/mfrtechconsult/dramatic-sky-ride/releases

Do not use GitHub's automatic source-code ZIP as the mod package.

## Required setup

DSR 0.1.2 requires:

- **Battle Art Voxel Fork** by absol89 — `BATTLE_ART_VOXEL_FORK >=1.7.6 <2.0.0`;
- **PokéPC Followers (W/Voxel Support)** — `PokePCFollowers_VoxelMerge`, used as the overworld Pokémon/NPC sprite provider for mounts.

The retired `DRAMATIC_SHAPE` id is no longer a supported installation dependency. A best-effort runtime fallback remains only for older manual installations.

## Strongly recommended: Wild Skies

**Wild Skies 1.4.1+ is strongly recommended.** DSR works without it, but the intended flying experience is DSR + Wild Skies: visible Pokémon populate the sky and can be intercepted in mid-air.

DSR integrates through Wild Skies' public API only. The visible flyer remains owned by Wild Skies, and an interception starts a battle against that exact visible species and level. DSR then restores the mount and airborne state after battle.

In 0.1.2 the interception envelope is more forgiving: visually close flyers can be engaged within two cells instead of requiring a near-perfect pass.

## What's new in 0.1.2

- **Surf + 3RD camera fixed with Battle Art Voxel Fork.** Water no longer collapses the third-person camera boom, so the trainer and Surf mount remain visible at normal camera angles.
- **1ST remains true first-person.** DSR does not force the trainer or mount into the first-person camera.
- **Wild Skies 1.4.1+ integration improved.** Mid-air interceptions now use a two-cell envelope, matching the newer moving three-dimensional flocks much better.

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Flight | `H` | `X` |
| Ground Ride | `G` | `Y` |
| Move | configured movement keys | left stick / D-pad |
| Look in 1ST/3RD | mouse | right stick |
| Ascend | `Page Up` | `R2` |
| Descend | `Page Down` | `L2` |
| Boost / gallop | configured B action | in-game `B` |
| Land | configured A action | in-game `A` |

`F` is deliberately left free because Gen1PC Overworld Encounters uses `F`/`V` for follower attacks.

## Mounts

Flying: Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair and Dragonite.

Ground Ride: Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros and Snorlax.

Visible Surf: Blastoise, Tentacruel, Gyarados and Lapras.

## Progression and compatibility

DSR can require FLY, enforce THUNDERBADGE/SOULBADGE rules and apply story/discovery gates so airborne travel does not bypass normal Kanto progression. Unknown/custom maps remain permissive by default.

- Required: Gen1Recomp `>=0.1.69 <2.0.0`.
- Required: Battle Art Voxel Fork `>=1.7.6 <2.0.0`.
- Required: PokéPC Followers (W/Voxel Support).
- Strongly recommended: Wild Skies `>=1.4.1 <2.0.0`.
- `free_fly` is a conflicting alternative player-flight engine.

## Credits

- absol89/DramaticShapeVoxelMod — Battle Art Voxel Fork, primary voxel provider, cameras and 3D battle presentation.
- DramaticShape/DramaticShapeVoxelMod — original voxel architecture.
- gamecorner-033/PokePCFollowers — required Gen 1 overworld Pokémon sprite provider.
- ShaneHudson/gen1recomp-mods — Wild Skies public integration API and airborne ecosystem.

## License

No open-source license is currently granted. The code remains under the copyright of its owner until a `LICENSE` file is explicitly added.
