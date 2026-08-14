# Dramatic Sky Ride 0.2.13

Compatibility bridge release for Gen1Recomp 0.1.86+.

## Follower sprite providers

- Restores PokéPC mount sprites under the 0.1.86 sandbox by accepting the existing public `assetPath(...)` export when a provider has not yet implemented `resolveFollowerSprite(...)`.
- Continues to prefer the modern `resolveFollowerSprite(...)` contract whenever it is available.
- Preserves Wilds of Kanto's dedicated `followers` style fallback before trying legacy provider APIs.
- Keeps PokéPC/Followers EX aliases and follower lifecycle synchronization intact.
- Keeps the public `registerSpriteSource(...)` path unchanged for external/custom providers.
- Validates every provider result as a loadable six-frame walking sheet of at least 16x96 before using it.
- Does not restore direct cross-mod filesystem access; all compatibility continues through `mod.find(...).exports`.

## Compatibility retained

- PokéPC Followers 0.8.2 legacy provider seam and 0.8.3+ canonical provider API.
- Followers EX lifecycle integration.
- Wilds of Kanto sprite/follower integration.
- Wild Skies update-chain interoperability.
- Battle Art / Dramaless voxel provider integration.
