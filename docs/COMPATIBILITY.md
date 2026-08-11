# Compatibility

Dramatic Sky Ride is designed as a gameplay owner with optional presentation and ecosystem integrations around it.

## Capability model

A compatible companion does not need to replace DSR's movement system. Integrations are separated by capability:

- mount gameplay;
- Pokemon sprite/follower source;
- airborne ecosystem;
- voxel renderer/camera;
- Stadium cache/import host;
- Stadium ROM-selection UI;
- player-character source;
- music provider.

This separation prevents a renderer, follower mod or Stadium companion from accidentally becoming a second mount engine.

## Compatibility matrix

| Project | Role with DSR | Notes |
|---|---|---|
| Wilds of Kanto (`overworld_wild_spawns`) | Sprite/follower and living-overworld provider | Recommended primary sprite provider. Supports DSR's high-detail PokeMMO mounted path when Wilds uses that style. |
| mfrtechconsult/PokePCFollowers (`PokePCFollowers_VoxelMerge`) | Alternative sprite/follower provider | Lighter alternative to Wilds. Normally choose one primary follower provider. |
| Wild Skies | Airborne Pokemon ecosystem | DSR uses its public API for visible flyers and aerial interceptions while retaining Flight ownership. |
| Battle Art Voxel Fork | Voxel renderer / 1ST / 3RD presentation | Recommended voxel renderer. Can render an existing Stadium cache. |
| Dramaless Shape | Voxel renderer and Stadium import host | Supported renderer and currently the easiest complete first-time Stadium cache host. |
| Crystal 251 | Gen II dataset + Stadium cache bridge | Required for DSR's current Stadium 2 cache workflow and useful for Johto mounts. |
| STADIUM_OVERWORLD_MODELS-compatible projects | Stadium companion presentation | DSR prevents double ownership of the active DSR mount while allowing companion rendering for other subjects. |
| OTF Player Switcher | Player/rider provider | Mounted rider art follows the active selected player where supported. |
| FRLG/HGSS/LGPE music packs | Optional flight music providers | DSR detects compatible tracks dynamically; battle/jingle priority remains with the normal audio flow. |

## Wilds of Kanto

DSR can use Wilds-provided follower/mount assets while leaving Wilds in control of its normal overworld population and follower behavior.

When Wilds uses its PokeMMO sprite style, DSR can use the higher-resolution mounted atlas only for the mount presentation. It does not force the rest of Wilds to change sprite style.

## PokéPC Followers

The maintained PokéPC path provides Gen I/II follower and mount-sprite support and is intended as a lighter alternative to Wilds.

## Wild Skies

DSR registers with Wild Skies through public exports rather than reaching into its internal flyer list. Wild Skies owns the airborne NPC ecosystem; DSR owns the player's Flight state and decides when an aerial interception should become a battle.

Some Wild Skies species may use generic fallback flying art when no species-specific airborne sheet exists. That is separate from DSR's settings UI and does not indicate a mount renderer failure.

## Battle Art and Dramaless

Both are supported as voxel presentation layers. DSR keeps movement, collision and mount state independent from the renderer.

A key distinction for Stadium 2 is that a renderer and a cache/import host are not always the same capability:

- Dramaless currently carries the full module family Crystal 251 needs for a first cache build;
- Battle Art can render a healthy existing cache but is not currently the recommended first-time import host.

## Crystal 251

Crystal 251 provides the current Generation II and Stadium cache bridge used by DSR. DSR expects a healthy generated cache rather than redistributing Stadium assets itself.

## Stadium companion mods

When DSR's native Stadium renderer owns the active Flight/Ground/Surf mount, compatible companion mods should not rebuild or draw that same mount a second time. They remain free to render their own wild Pokemon, followers, UI and unrelated models.

## Free Fly

DSR conflicts with `free_fly` because both are player Flight engines. Do not enable both at the same time.
