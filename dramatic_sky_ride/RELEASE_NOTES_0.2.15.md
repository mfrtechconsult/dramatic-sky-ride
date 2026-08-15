# Dramatic Sky Ride 0.2.15 — Wilds sandbox compatibility hotfix

This release restores the Dramatic Sky Ride integration with the current **Wilds of Kanto 2.1.5+** sandbox-compatible runtime.

## Wilds of Kanto compatibility

- Migrated the DSR/Wilds bridge to Wilds' public `mod.exports` API.
- Flight and Ground Ride mount sheets are resolved through `resolveFollowerSprite(...)`.
- Follower restoration is delegated to Wilds through its public `syncAll(...)` API.
- DSR now passes the live `mod.world.game` / `mod.game` object to Wilds instead of relying on a Gen 1 compatibility facade.
- Wilds remains the sole follower lifecycle owner when installed, including temporary not-ready states, so PokéPC or Followers EX cannot start a competing runtime underneath it.
- Static/Pokédex Wilds art is rejected for mounts and retried through Wilds' walking/follower sprite style.

## Sandbox cleanup

- Removed the old compatibility layer that inspected and rewrote overworld update-function upvalues.
- No `debug`-based update-chain surgery is required for Wilds 2.1.5: Wilds now uses supported hooks/events and owns its battle-return reconciliation.
- No raw filesystem access or filesystem permission was added.
- Legacy cooperative-guard exports remain as harmless no-op compatibility shims for companion mods that still query them.

## Validation

A dedicated compatibility workflow now tests the current Wilds `main` branch against the current Gen1Recomp `dev` sandbox. It validates:

- both manifests remain filesystem-free,
- removed sandbox surfaces are absent from the bridge,
- LuaJIT compilation,
- the public sprite/follower API bridge,
- and an actual Gen1Recomp Loader stack containing Wilds of Kanto + Dramatic Sky Ride.

No Open Sky, Flight, Ground Ride, Visible Surf, Stadium, or progression behavior is intentionally changed by this hotfix.
