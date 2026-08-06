# Dramatic Sky Ride backlog

Alpha.15 is the frozen feature baseline. Development is paused while work moves to other mods; changes after alpha.15 should normally be limited to bug fixes, compatibility fixes and narrowly scoped regressions.

The documents in this directory preserve deferred ideas so work can resume later without reconstructing previous design decisions.

## Deferred lots

1. [Visible Surf mount polish](LOT-02-SURF-VISUALS.md)
2. [Dedicated rider postures and offsets](LOT-03-RIDER-POSTURES.md)
3. [Isolated flying-mount profiles](LOT-04-FLIGHT-PROFILES.md)
4. [Geometry-aware air collision safety](LOT-05-AIR-COLLISION.md)
5. [Final interface and comfort pass](LOT-06-UI-COMFORT.md)
6. [Beta stabilization matrix](LOT-07-BETA-STABILIZATION.md)

## Explicitly excluded ideas

The following ideas were intentionally rejected and should not be reintroduced without a new design decision:

- story-specific riding restrictions;
- automatic dismount/remount tied to building entrances and exits;
- a broad roster of specialized mounts beyond the humorous Snorlax addition.

## Resume rule

Any future feature lot must start from the latest bug-fixed alpha.15 descendant, preserve the validated flight camera, and return to the test-before-commit workflow.
