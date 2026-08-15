# Dramatic Sky Ride 0.2.16 — Open Sky map hotfix

This hotfix repairs the regional artwork regression introduced when Open Sky assets were compacted for the 0.2.14/0.2.15 publication path.

## Open Sky maps

- Restores the Johto regional artwork instead of falling back to the green emergency/debug map.
- Restores both Johto and Kanto at the native **312×232** Open Sky viewport.
- Replaces the accidentally degraded/downscaled publication assets with verified native-resolution map data.
- Loads the restored maps from deterministic multipart bundled data and validates the decoded PNG dimensions before rendering.
- Keeps linear filtering for the Stadium 2-style regional artwork while avoiding the previous low-resolution source upscale.

## Regression protection

A dedicated CI check now reconstructs both bundled regional maps and verifies:

- valid PNG signatures,
- exact 312×232 dimensions,
- expected SHA-256 checksums,
- and that no `filesystem` permission is introduced.

## Unchanged

No Open Sky movement, city calibration, landing/progression, Wilds 2.1.5 compatibility, mount behavior, or sandbox permission behavior is intentionally changed by this release.
