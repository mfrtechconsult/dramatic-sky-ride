# Stadium 2 Mount Motion — Alpha 9

This document applies only to the `experiment/stadium2-3d` branch.

## Design rule

Pokemon Stadium 2 does not provide a shared overworld `walk`, `run`, `fly` or `swim` animation contract. Its packed context slots are battle-oriented (`idle`, attacks, reactions, entrance, flinch and alternate idle states). Dramatic Sky Ride therefore does **not** invent generic bone mappings or reuse attack animations as fake locomotion.

The mount-motion layer keeps each Pokemon's genuine Stadium skeletal animation and adapts the whole model to the DSR mount state:

- skeletal playback cadence follows real mount movement;
- Flight adds forward pitch, climb/dive pitch and turn banking;
- Ground Ride adds morphology-specific body cadence, forward lean/bob and restrained turn response;
- Visible Surf adds low-frequency buoyancy, pitch and water-turn roll;
- DSR still owns movement, collisions, altitude, progression, cameras and rider state;
- the voxel provider still owns depth, terrain, reflections and the final draw path;
- the model and its shadow use the same motion transform.

Heavy bipeds are intentionally calmer than quadrupeds, Dragonair is not treated like a bird, and Snorlax/Tyranitar remain restrained. This layer never guesses individual Stadium bone indices.

## Alpha 9 audit and changes

Alpha 8 had complete roster tables but several Ground/Surf amplitudes were too small to read visually in the voxel world. Many body bobs were only about 0.2–0.5 world pixels, so the code could be active without the player noticing a meaningful difference.

Alpha 9 therefore audits three independent requirements: profile coverage, render-matrix attachment, and visible motion amplitude.

Changes:

- all 17 Ground Ride profiles were reviewed and retuned;
- all 8 Visible Surf profiles were reviewed and retuned;
- the deliberately subtle Flight profiles (Dragonair, Xatu, Skarmory, Lugia and Ho-Oh) were raised moderately;
- fast quadrupeds/equines/runner birds receive clearly stronger body response than heavy bipeds;
- Surf idle buoyancy is now large enough to be visually readable while remaining under roughly one world pixel for most species at rest;
- serpentine/ray swimmers receive stronger motion and turn response;
- Suicune now has a dedicated `water` presentation while its Ground Ride amphibious state is active;
- Suicune is still not a ninth Visible Surf mount: Ground Ride remains its lifecycle owner;
- runtime audit reports whether the skeleton clock, model matrix and shadow matrix were actually patched.

The public `stadium3DMountMotion.audit()` result is expected to report 16 Flight, 17 Ground, 8 Visible Surf, one amphibious-water helper, no malformed profiles, and an active model-motion matrix.

## Complete role coverage

There are **41 normal mount-role entries**: 16 Flight, 17 Ground Ride and 8 Visible Surf. Lugia is intentionally present in both Flight and Surf. Suicune additionally owns one internal amphibious-water motion profile without joining the Visible Surf roster.

### Flight — 16

- Charizard — winged dragon
- Pidgeot — bird
- Fearow — bird
- Golbat — bat
- Aerodactyl — pterosaur
- Articuno — large bird
- Zapdos — large bird
- Moltres — large bird
- Dragonair — serpentine flyer
- Dragonite — winged dragon
- Noctowl — bird
- Crobat — bat
- Xatu — levitating bird
- Skarmory — armored bird
- Lugia — large winged flyer
- Ho-Oh — large bird

### Ground Ride — 17

- Arcanine — fast quadruped
- Rapidash — equine
- Dodrio — runner bird
- Rhyhorn — heavy quadruped
- Rhydon — heavy biped
- Kangaskhan — large biped
- Tauros — bovine
- Snorlax — very heavy biped
- Meganium — heavy quadruped
- Girafarig — equine-like quadruped
- Ursaring — heavy biped
- Donphan — heavy quadruped
- Stantler — deer
- Raikou — fast quadruped
- Entei — large quadruped
- Suicune — fast quadruped / amphibious water presentation
- Tyranitar — very heavy biped

### Visible Surf — 8

- Blastoise — bulky swimmer
- Tentacruel — tentacled swimmer
- Gyarados — serpentine swimmer
- Lapras — large swimmer
- Feraligatr — bulky swimmer
- Mantine — ray
- Kingdra — serpentine swimmer
- Lugia — large swimmer

## Runtime behavior

Motion is measured from the player's actual world-space movement instead of assuming a specific input implementation. This keeps the presentation compatible with normal tile movement and supported free-camera movement paths.

Each active Stadium runtime tracks:

- smoothed horizontal speed;
- flight vertical speed;
- recent left/right turn impulse;
- DSR Flight boost;
- Ground Ride speed/gallop blend;
- a role-specific motion phase;
- the resulting animation-rate multiplier, bob, pitch and roll.

Public diagnostic APIs:

`stadium3DMountMotion.coverage()` — complete curated roster and family mapping.

`stadium3DMountMotion.profile(role, species, dex)` — resolved profile.

`stadium3DMountMotion.stats(dex)` — live measured speed/intensity/rate/bob/pitch/roll.

`stadium3DMountMotion.audit()` — coverage and runtime attachment audit.

## Alpha 9 visual priorities

Recommended representative tests:

- Flight: Charizard, Dragonair, Skarmory, Lugia;
- Ground: Rapidash, Dodrio, Tauros, Raikou, Suicune, Snorlax, Tyranitar;
- Surf: Tentacruel, Gyarados, Lapras, Mantine, Kingdra, Lugia;
- Suicune: compare Ground Ride on land, shoreline transition and amphibious water running.

Fast Ground mounts should now show a clearly perceptible body cadence/lean while moving and galloping. Heavy bipeds should remain noticeably calmer. Surf mounts should visibly float at rest and react more clearly to forward motion and turns.

## Intentional limitation

Ground Ride still does not have a genuine shared Stadium locomotion animation. Selecting a battle reaction or attack merely because it moves many bones would often look worse than a restrained authentic idle. Per-species gait clips should only be added after a specific Stadium source clip has been visually verified as credible locomotion for that species.
