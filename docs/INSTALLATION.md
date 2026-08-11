# Installation

## Minimum installation

You only need:

1. Gen1Recomp `>=0.1.69 <2.0.0`;
2. Dramatic Sky Ride.

Native 2D Flight works without a voxel renderer, follower mod, Wild Skies, Crystal 251 or a music pack.

## Recommended native 2D setup

Install DSR with **one** primary Pokemon sprite/follower provider:

### Wilds of Kanto

Use `overworld_wild_spawns` if you want:

- visible wild Pokemon in the overworld;
- followers;
- DSR mount sprites;
- optional high-detail PokeMMO mounted sprites;
- a fuller ground-world complement to Wild Skies.

### PokéPC Followers

Use `PokePCFollowers_VoxelMerge` if you want a lighter follower and mount-sprite setup.

For a normal user configuration, do not install Wilds of Kanto and PokéPC Followers as competing primary follower providers at the same time.

## Add Wild Skies

Wild Skies is optional but strongly recommended for Flight. It adds visible airborne Pokemon and exposes the supported interception API used by DSR.

DSR remains the player's flight engine.

## Add Generation II content

DSR includes Generation II mount roles, but those Pokemon must exist in the active game dataset.

Install Crystal 251 or another compatible Gen II content provider if you want Johto mounts to be available.

## Voxel / first-person / third-person setup

Supported renderers include:

- **Battle Art Voxel Fork** `>=1.7.6 <2.0.0` — recommended renderer;
- **Dramaless Shape** `>=1.6.4 <2.0.0` — supported alternative.

DSR continues to own mount gameplay in both cases. The voxel mod owns world presentation and camera rendering.

## Optional integrations

You can also install:

- OTF Player Switcher — mounted rider art follows the selected character;
- compatible FRLG/HGSS/LGPE music packs — optional Flying Music choices;
- Crystal 251 + a compatible Stadium import host — animated Stadium 2 mounts;
- compatible Stadium overworld companion mods — wild/follower/companion rendering alongside DSR's active mount ownership.

## Recommended installation order for Stadium 2

For a first Stadium cache build:

1. install DSR;
2. install Crystal 251;
3. install Dramaless Shape or another compatible full Stadium import host;
4. start Gen1Recomp;
5. open the relevant Options/Mod Manager screen;
6. import your compatible Pokemon Stadium 2 ROM;
7. wait for the cache build to finish;
8. confirm `STADIUM 2 ROM = READY`;
9. enable `MOUNT RENDERER = STADIUM 3D` in DSR.

Once the cache exists, Battle Art can render the DSR Stadium mounts even if you no longer use Dramaless as the active renderer.

See [Pokemon Stadium 2](STADIUM2.md) for the full workflow.
